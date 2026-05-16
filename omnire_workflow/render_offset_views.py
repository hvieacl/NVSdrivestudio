"""Render a reconstructed OmniRe scene from an offset novel-view trajectory."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

import numpy as np
import torch
from omegaconf import OmegaConf


REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from datasets.driving_dataset import DrivingDataset  # noqa: E402
from models.video_utils import render_novel_views  # noqa: E402
from utils.misc import import_str  # noqa: E402


def apply_offset(poses: torch.Tensor, right: float, up: float, forward: float) -> torch.Tensor:
    poses = poses.clone()
    rot = poses[:, :3, :3]
    offset = right * rot[:, :, 0] - up * rot[:, :, 1] + forward * rot[:, :, 2]
    poses[:, :3, 3] += offset
    return poses


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--resume_from", required=True, type=Path)
    parser.add_argument("--base_traj", default="front_center_interp")
    parser.add_argument("--frames", type=int, default=None)
    parser.add_argument("--fps", type=int, default=24)
    parser.add_argument("--right_m", type=float, default=0.0)
    parser.add_argument("--up_m", type=float, default=0.0)
    parser.add_argument("--forward_m", type=float, default=0.0)
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("opts", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    resume_from = args.resume_from.resolve()
    log_dir = resume_from.parent
    cfg = OmegaConf.load(log_dir / "config.yaml")
    cfg = OmegaConf.merge(cfg, OmegaConf.from_cli(args.opts))
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    dataset = DrivingDataset(data_cfg=cfg.data)
    trainer = import_str(cfg.trainer.type)(
        **cfg.trainer,
        num_timesteps=dataset.num_img_timesteps,
        model_config=cfg.model,
        num_train_images=len(dataset.train_image_set),
        num_full_images=len(dataset.full_image_set),
        test_set_indices=dataset.test_timesteps,
        scene_aabb=dataset.get_aabb().reshape(2, 3),
        device=device,
    )
    trainer.resume_from_checkpoint(ckpt_path=str(resume_from), load_only_model=True)
    trainer.set_eval()

    frames = args.frames or dataset.frame_num
    traj = dataset.get_novel_render_traj([args.base_traj], frames)[args.base_traj]
    traj = apply_offset(traj, args.right_m, args.up_m, args.forward_m)

    if args.output is None:
        out_dir = log_dir / "videos_offset"
        out_dir.mkdir(parents=True, exist_ok=True)
        output = out_dir / f"{args.base_traj}_r{args.right_m:g}_u{args.up_m:g}_f{args.forward_m:g}.mp4"
    else:
        output = args.output.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)

    np.save(output.with_suffix(".npy"), traj.detach().cpu().numpy())
    render_novel_views(trainer, dataset.prepare_novel_view_render_data(traj), str(output), fps=args.fps)
    print(f"Saved offset-view video to {output}")


if __name__ == "__main__":
    main()
