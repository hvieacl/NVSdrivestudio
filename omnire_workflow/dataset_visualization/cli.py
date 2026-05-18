"""CLI for Waymo-to-KITTI dataset visualization workflows."""

from __future__ import annotations

import argparse
import csv
import os
import shutil
import subprocess
import sys
from pathlib import Path

from .check_kitti_io import validate_kitti_root

REPO_ROOT = Path(__file__).resolve().parents[2]


def repo_path(path: str | Path) -> Path:
    path = Path(path)
    return path if path.is_absolute() else REPO_ROOT / path


def scene_rows(map_file: str | Path):
    with repo_path(map_file).open("r", encoding="utf-8") as f:
        for row in csv.reader(f):
            if row and not row[0].startswith("#"):
                yield row[0].strip(), row[1].strip()


def stage_tfrecord(tfrecord: Path) -> Path:
    staging = REPO_ROOT / "visualization_outputs" / "_staging" / tfrecord.stem
    staging.mkdir(parents=True, exist_ok=True)
    staged = staging / tfrecord.name
    if not staged.exists():
        try:
            os.link(tfrecord, staged)
        except OSError:
            try:
                os.symlink(tfrecord, staged)
            except OSError:
                shutil.copy2(tfrecord, staged)
    return staging


def convert_ten(args):
    raw_dir = repo_path(args.raw_dir)
    out_root = repo_path(args.project_output)
    converter = repo_path(args.converter_dir) / "converter.py"
    for scene_idx, tfrecord_name in scene_rows(args.map_file):
        tfrecord = raw_dir / tfrecord_name
        out = out_root / f"scene_{scene_idx}" / "dataset_visualization" / "kitti"
        if (out / "velodyne").exists() and not args.overwrite:
            print(f"[SKIP] scene_{scene_idx}: {out}")
        else:
            subprocess.run(
                [sys.executable, str(converter), str(stage_tfrecord(tfrecord)), str(out), "--prefix", "", "--num_proc", str(args.num_proc)],
                cwd=str(REPO_ROOT),
                check=True,
            )
        if args.check:
            validate_kitti_root(out, args.camera_id)


def check_ten(args):
    out_root = repo_path(args.project_output)
    for scene_idx, _ in scene_rows(args.map_file):
        validate_kitti_root(out_root / f"scene_{scene_idx}" / "dataset_visualization" / "kitti", args.camera_id)


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("convert-ten")
    p.add_argument("--raw_dir", default="data/waymo/raw")
    p.add_argument("--project_output", default="OutPut/waymo_training_10scenes")
    p.add_argument("--map_file", default="omnire_workflow/dataset_visualization/waymo_10scene_map.txt")
    p.add_argument("--converter_dir", default="external_tools/waymo_kitti_converter")
    p.add_argument("--num_proc", type=int, default=1)
    p.add_argument("--camera_id", default="0")
    p.add_argument("--overwrite", action="store_true")
    p.add_argument("--check", dest="check", action="store_true", default=True)
    p.add_argument("--no-check", dest="check", action="store_false")
    p.set_defaults(func=convert_ten)
    p = sub.add_parser("check-ten")
    p.add_argument("--project_output", default="OutPut/waymo_training_10scenes")
    p.add_argument("--map_file", default="omnire_workflow/dataset_visualization/waymo_10scene_map.txt")
    p.add_argument("--camera_id", default="0")
    p.set_defaults(func=check_ten)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
