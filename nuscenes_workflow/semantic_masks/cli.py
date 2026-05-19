"""Check and extract nuScenes semantic masks for OmniRe training."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import List, Optional


DEFAULT_SCENES = "0 1 2 3 4 5 6 7 8 9"
DEFAULT_CAMERAS = "0 1 2 3 4 5"


def parse_ids(value: Optional[str]) -> List[int]:
    if not value:
        return [int(v) for v in DEFAULT_SCENES.split()]
    return [int(v) for v in value.replace(",", " ").split()]


def parse_cameras(value: Optional[object]) -> List[int]:
    if not value:
        return [int(v) for v in DEFAULT_CAMERAS.split()]
    if isinstance(value, list):
        return [int(v) for item in value for v in str(item).replace(",", " ").split()]
    return [int(v) for v in value.replace(",", " ").split()]


def scene_dir(data_root: Path, scene_id: int) -> Path:
    return data_root / f"{scene_id:03d}"


def image_stems(data_root: Path, scene_id: int, cameras: List[int]) -> List[str]:
    image_dir = scene_dir(data_root, scene_id) / "images"
    stems: List[str] = []
    for cam_id in cameras:
        stems.extend(p.stem for p in sorted(image_dir.glob(f"*_{cam_id}.jpg")))
    return stems


def missing_sky_masks(data_root: Path, scene_id: int, cameras: List[int]) -> List[Path]:
    root = scene_dir(data_root, scene_id)
    missing: List[Path] = []
    for stem in image_stems(data_root, scene_id, cameras):
        mask_path = root / "sky_masks" / f"{stem}.png"
        if not mask_path.exists():
            missing.append(mask_path)
    return missing


def check(args: argparse.Namespace) -> int:
    data_root = Path(args.data_root)
    scenes = parse_ids(args.scene_ids)
    cameras = parse_cameras(args.cameras)
    failed = False

    for scene_id in scenes:
        root = scene_dir(data_root, scene_id)
        if not root.exists():
            print(f"[mask-check] scene {scene_id}: missing processed dir: {root}")
            failed = True
            continue
        stems = image_stems(data_root, scene_id, cameras)
        missing = missing_sky_masks(data_root, scene_id, cameras)
        if not stems:
            print(f"[mask-check] scene {scene_id}: no images found for cameras {cameras}")
            failed = True
        elif missing:
            print(
                f"[mask-check] scene {scene_id}: missing {len(missing)}/{len(stems)} sky masks; "
                f"first missing: {missing[0]}"
            )
            failed = True
        else:
            print(f"[mask-check] scene {scene_id}: sky masks OK ({len(stems)} files)")

    return 1 if failed else 0


def extract(args: argparse.Namespace) -> int:
    command = [
        sys.executable,
        "datasets/tools/extract_masks.py",
        "--data_root",
        args.data_root,
        "--scene_ids",
        *[str(v) for v in parse_ids(args.scene_ids)],
        "--segformer_path",
        args.segformer_path,
        "--checkpoint",
        args.checkpoint,
        "--device",
        args.device,
    ]
    if args.process_dynamic_mask:
        command.append("--process_dynamic_mask")
    if args.ignore_existing:
        command.append("--ignore_existing")

    print("[mask-extract] " + " ".join(command), flush=True)
    return subprocess.call(command)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    check_parser = subparsers.add_parser("check", help="Check processed scenes for sky masks.")
    check_parser.add_argument("--data_root", default="data/nuscenes/processed_10Hz/mini")
    check_parser.add_argument("--scene_ids", default=DEFAULT_SCENES)
    check_parser.add_argument("--cameras", nargs="+", default=DEFAULT_CAMERAS.split())
    check_parser.set_defaults(func=check)

    extract_parser = subparsers.add_parser("extract", help="Run SegFormer mask extraction.")
    extract_parser.add_argument("--data_root", default="data/nuscenes/processed_10Hz/mini")
    extract_parser.add_argument("--scene_ids", default=DEFAULT_SCENES)
    extract_parser.add_argument("--segformer_path", default="../SegFormer")
    extract_parser.add_argument(
        "--checkpoint",
        default="../SegFormer/pretrained/segformer.b5.1024x1024.city.160k.pth",
    )
    extract_parser.add_argument("--device", default="cuda:0")
    extract_parser.add_argument("--process_dynamic_mask", action="store_true")
    extract_parser.add_argument("--ignore_existing", action="store_true")
    extract_parser.set_defaults(func=extract)

    return parser


def main() -> int:
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
