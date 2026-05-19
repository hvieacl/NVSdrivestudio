"""Preflight checks for the nuScenes mini training workflow."""

from __future__ import annotations

import argparse
import importlib
from pathlib import Path
from typing import List, Optional


DEFAULT_SCENES = "0 1 2 3 4 5 6 7 8 9"


def parse_ids(value: Optional[str]) -> List[int]:
    if not value:
        return [int(v) for v in DEFAULT_SCENES.split()]
    return [int(v) for v in value.replace(",", " ").split()]


def check_import(module_name: str) -> bool:
    try:
        importlib.import_module(module_name)
        print(f"[preflight] import OK: {module_name}")
        return True
    except Exception as exc:
        print(f"[preflight] import MISSING: {module_name} ({exc})")
        return False


def count_files(root: Path, pattern: str) -> int:
    return sum(1 for _ in root.glob(pattern))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene_ids", default=DEFAULT_SCENES)
    parser.add_argument("--raw_dir", default="data/nuscenes/raw")
    parser.add_argument("--processed_root", default="data/nuscenes/processed_10Hz/mini")
    parser.add_argument("--check_imports", action="store_true")
    parser.add_argument("--require_sky_masks", action="store_true")
    args = parser.parse_args()

    failed = False
    scenes = parse_ids(args.scene_ids)
    raw_dir = Path(args.raw_dir)
    processed_root = Path(args.processed_root)

    if args.check_imports:
        for module_name in [
            "torch",
            "nuscenes",
            "omegaconf",
            "cv2",
            "open3d",
        ]:
            failed = (not check_import(module_name)) or failed

    for required in ["v1.0-mini", "samples", "sweeps", "maps"]:
        path = raw_dir / required
        if path.exists():
            print(f"[preflight] raw {required} OK: {path}")
        else:
            print(f"[preflight] raw {required} MISSING: {path}")
            failed = True

    for scene_id in scenes:
        scene_root = processed_root / f"{scene_id:03d}"
        if not scene_root.exists():
            print(f"[preflight] scene {scene_id}: processed dir MISSING: {scene_root}")
            failed = True
            continue

        images = count_files(scene_root / "images", "*.jpg")
        lidar = count_files(scene_root / "lidar", "*.bin")
        sky_masks = count_files(scene_root / "sky_masks", "*.png")
        objects = scene_root / "instances" / "instances_info.json"

        print(
            f"[preflight] scene {scene_id}: "
            f"images={images}, lidar={lidar}, sky_masks={sky_masks}"
        )
        if images == 0:
            failed = True
        if lidar == 0:
            failed = True
        if args.require_sky_masks and sky_masks == 0:
            print(f"[preflight] scene {scene_id}: sky_masks MISSING")
            failed = True
        if not objects.exists():
            print(f"[preflight] scene {scene_id}: instances_info MISSING: {objects}")
            failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
