import argparse
import math
import sys
from pathlib import Path

import imageio.v3 as iio
import numpy as np
from PIL import Image, ImageDraw, ImageFont


def parse_scenes(value):
    if not value:
        return list(range(10))
    scenes = []
    for part in value.replace(",", " ").split():
        if "-" in part:
            start, end = part.split("-", 1)
            scenes.extend(range(int(start), int(end) + 1))
        else:
            scenes.append(int(part))
    return scenes


def frame_indices(total_frames, explicit, num_samples):
    if explicit:
        return [idx for idx in explicit if 0 <= idx < total_frames]
    if num_samples <= 1:
        return [total_frames // 2]
    return sorted(set(int(round(v)) for v in np.linspace(0, total_frames - 1, num_samples)))


def read_video_frames(video_path):
    try:
        return [Image.fromarray(frame).convert("RGB") for frame in iio.imiter(video_path)]
    except Exception as imageio_error:
        try:
            import cv2
        except ImportError as exc:
            raise RuntimeError(
                "Could not read mp4 with imageio, and cv2 is not installed. "
                "Install imageio[ffmpeg] or opencv-python."
            ) from imageio_error

        cap = cv2.VideoCapture(str(video_path))
        if not cap.isOpened():
            raise RuntimeError(f"Could not open video: {video_path}") from imageio_error

        frames = []
        while True:
            ok, frame_bgr = cap.read()
            if not ok:
                break
            frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
            frames.append(Image.fromarray(frame_rgb).convert("RGB"))
        cap.release()
        return frames


def save_labelled_compare(left, right, label, out_path):
    left = left.convert("RGB")
    right = right.convert("RGB")
    h = max(left.height, right.height)
    if left.height != h:
        left = left.resize((round(left.width * h / left.height), h), Image.LANCZOS)
    if right.height != h:
        right = right.resize((round(right.width * h / right.height), h), Image.LANCZOS)

    pad = 12
    header = 34
    canvas = Image.new("RGB", (left.width + right.width + pad, h + header), (18, 18, 18))
    canvas.paste(left, (0, header))
    canvas.paste(right, (left.width + pad, header))

    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()
    draw.text((8, 10), f"{label} | degraded", fill=(240, 240, 240), font=font)
    draw.text((left.width + pad + 8, 10), "difix restored", fill=(240, 240, 240), font=font)
    canvas.save(out_path)


def save_grid(compare_paths, out_path, columns):
    if not compare_paths:
        return
    images = [Image.open(path).convert("RGB") for path in compare_paths]
    cell_w = max(img.width for img in images)
    cell_h = max(img.height for img in images)
    rows = math.ceil(len(images) / columns)
    grid = Image.new("RGB", (columns * cell_w, rows * cell_h), (12, 12, 12))
    for idx, img in enumerate(images):
        x = (idx % columns) * cell_w
        y = (idx // columns) * cell_h
        grid.paste(img, (x, y))
    grid.save(out_path)


class DifixRunner:
    def __init__(self, args, use_ref):
        self.args = args
        self.use_ref = use_ref

        difix_src = Path(args.difix_root) / "src"
        if not difix_src.exists():
            raise FileNotFoundError(f"Difix src directory not found: {difix_src}")
        sys.path.insert(0, str(difix_src))

        backend = args.backend
        if backend == "auto":
            backend = "model" if args.model_path else "pipeline"
        self.backend = backend

        if backend == "model":
            from model import Difix

            if not args.model_path:
                raise ValueError("--model_path is required for --backend model")
            self.model = Difix(
                pretrained_path=args.model_path,
                timestep=args.timestep,
                mv_unet=use_ref,
            )
            self.model.set_eval()
        elif backend == "pipeline":
            from pipeline_difix import DifixPipeline

            model_name = args.model_name or ("nvidia/difix_ref" if use_ref else "nvidia/difix")
            self.model = DifixPipeline.from_pretrained(model_name, trust_remote_code=True)
            self.model.set_progress_bar_config(disable=True)
            self.model.to(args.device)
        else:
            raise ValueError(f"Unknown backend: {backend}")

    def __call__(self, image, ref_image=None):
        if self.backend == "model":
            return self.model.sample(
                image,
                width=self.args.width,
                height=self.args.height,
                ref_image=ref_image,
                prompt=self.args.prompt,
            )
        result = self.model(
            self.args.prompt,
            image=image,
            ref_image=ref_image,
            num_inference_steps=1,
            timesteps=[self.args.timestep],
            guidance_scale=0.0,
        ).images[0]
        return result.resize(image.size, Image.LANCZOS)


def build_argparser():
    parser = argparse.ArgumentParser(
        description="Sample nuScenes offset-view videos, restore frames with Difix, and build before/after montages."
    )
    parser.add_argument("--project_root", default=".", help="drivestudio project root")
    parser.add_argument("--video_root", default=None, help="Root containing scene_x folders")
    parser.add_argument("--difix_root", default=r"D:\GithubDocument\Difix3D")
    parser.add_argument("--output_dir", default="visualization_outputs/difix_offset_comparison")
    parser.add_argument("--scenes", default="0-9", help='Examples: "0-9", "0 3 7", "7,8,9"')
    parser.add_argument("--video_name", default="front_center_interp_r2_u0_f0.mp4")
    parser.add_argument("--ref_video_name", default=None, help="Optional video under scene_x/videos_eval for reference frames")
    parser.add_argument(
        "--ref_image_root",
        default=None,
        help="Optional processed data root with scene folders, e.g. data/nuscenes/processed_10Hz/mini. Uses {scene}/images/{frame}_{camera}.jpg.",
    )
    parser.add_argument("--ref_camera_id", type=int, default=0, help="Reference camera id. nuScenes 0 is CAM_FRONT.")
    parser.add_argument("--frames", nargs="*", type=int, default=None, help="Explicit frame indices")
    parser.add_argument("--num_samples", type=int, default=6)
    parser.add_argument("--backend", choices=["auto", "model", "pipeline"], default="auto")
    parser.add_argument("--model_path", default=None, help="Local Difix model_*.pkl checkpoint")
    parser.add_argument("--model_name", default=None, help="HF pipeline name, e.g. nvidia/difix or nvidia/difix_ref")
    parser.add_argument("--prompt", default="remove degradation")
    parser.add_argument("--timestep", type=int, default=199)
    parser.add_argument("--height", type=int, default=576)
    parser.add_argument("--width", type=int, default=1024)
    parser.add_argument("--device", default="cuda")
    parser.add_argument("--skip_difix", action="store_true", help="Only sample degraded frames")
    parser.add_argument("--grid_columns", type=int, default=2)
    return parser


def main():
    args = build_argparser().parse_args()
    project_root = Path(args.project_root).resolve()
    video_root = Path(args.video_root).resolve() if args.video_root else project_root / "OutPut" / "nuscenes_mini_10scenes"
    output_root = Path(args.output_dir).resolve()

    degraded_dir = output_root / "degraded"
    restored_dir = output_root / "restored"
    compare_dir = output_root / "compare"
    for directory in [degraded_dir, restored_dir, compare_dir]:
        directory.mkdir(parents=True, exist_ok=True)

    scenes = parse_scenes(args.scenes)
    runner = None
    if not args.skip_difix:
        runner = DifixRunner(args, use_ref=(args.ref_video_name is not None or args.ref_image_root is not None))

    compare_paths = []
    for scene in scenes:
        scene_dir = video_root / f"scene_{scene}"
        video_path = scene_dir / "videos_offset" / args.video_name
        if not video_path.exists():
            print(f"[WARN] missing offset video: {video_path}")
            continue

        print(f"[scene {scene}] reading {video_path}")
        frames = read_video_frames(video_path)
        if not frames:
            print(f"[WARN] empty video: {video_path}")
            continue

        ref_frames = None
        ref_scene_image_dir = None
        if args.ref_video_name:
            ref_path = scene_dir / "videos_eval" / args.ref_video_name
            if not ref_path.exists():
                raise FileNotFoundError(f"Reference video not found for scene {scene}: {ref_path}")
            ref_frames = read_video_frames(ref_path)
        if args.ref_image_root:
            ref_scene_image_dir = Path(args.ref_image_root).resolve() / f"{scene:03d}" / "images"
            if not ref_scene_image_dir.exists():
                raise FileNotFoundError(f"Reference image directory not found for scene {scene}: {ref_scene_image_dir}")

        indices = frame_indices(len(frames), args.frames, args.num_samples)
        for idx in indices:
            image = frames[idx]
            stem = f"scene_{scene:03d}_frame_{idx:04d}"
            degraded_path = degraded_dir / f"{stem}.png"
            restored_path = restored_dir / f"{stem}.png"
            compare_path = compare_dir / f"{stem}_compare.png"

            image.save(degraded_path)
            if args.skip_difix:
                print(f"[OK] sampled {degraded_path}")
                continue

            ref_image = None
            if ref_frames is not None:
                ref_idx = int(round(idx * (len(ref_frames) - 1) / max(len(frames) - 1, 1)))
                ref_image = ref_frames[ref_idx]
            elif ref_scene_image_dir is not None:
                ref_path = ref_scene_image_dir / f"{idx:03d}_{args.ref_camera_id}.jpg"
                if not ref_path.exists():
                    print(f"[WARN] missing GT reference image: {ref_path}")
                else:
                    ref_image = Image.open(ref_path).convert("RGB")

            restored = runner(image, ref_image=ref_image)
            restored.save(restored_path)
            save_labelled_compare(image, restored, f"scene {scene} frame {idx}", compare_path)
            compare_paths.append(compare_path)
            print(f"[OK] {compare_path}")

    if compare_paths:
        grid_path = output_root / "all_compare_grid.png"
        save_grid(compare_paths, grid_path, columns=args.grid_columns)
        print(f"[OK] grid: {grid_path}")


if __name__ == "__main__":
    main()
