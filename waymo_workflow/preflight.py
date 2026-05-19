"""Preflight checks for the OmniRe Waymo training workflow."""

from __future__ import annotations

import argparse
import importlib
from pathlib import Path
from typing import List, Optional


DEFAULT_SCENES = "0 1 4 8 32 102 109 114 149 156"
OFFICIAL_SMPL_FILENAME = "basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl"


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


def find_official_smpl_model(search_root: Path) -> Optional[Path]:
    direct = search_root / OFFICIAL_SMPL_FILENAME
    if direct.exists() and direct.stat().st_size > 0:
        return direct
    for match in search_root.rglob(OFFICIAL_SMPL_FILENAME):
        if match.exists() and match.stat().st_size > 0:
            return match
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene_ids", default=DEFAULT_SCENES)
    parser.add_argument("--raw_dir", default="data/waymo/raw")
    parser.add_argument("--processed_root", default="data/waymo/processed/training")
    parser.add_argument("--smpl_model", default="smpl_models/SMPL_NEUTRAL.pkl")
    parser.add_argument("--smpl_search_root", default="smpl_models")
    parser.add_argument("--check_imports", action="store_true")
    args = parser.parse_args()

    failed = False
    scenes = parse_ids(args.scene_ids)
    raw_dir = Path(args.raw_dir)
    processed_root = Path(args.processed_root)

    if args.check_imports:
        for module_name in [
            "torch",
            "pytorch3d",
            "gsplat",
            "nvdiffrast.torch",
            "waymo_open_dataset",
            "omegaconf",
            "cv2",
            "open3d",
        ]:
            failed = (not check_import(module_name)) or failed

    raw_count = count_files(raw_dir, "*.tfrecord")
    if raw_count:
        print(f"[preflight] raw tfrecords OK: {raw_count} files under {raw_dir}")
    else:
        print(f"[preflight] raw tfrecords MISSING under {raw_dir}")
        failed = True

    smpl_model = Path(args.smpl_model)
    if smpl_model.exists() and smpl_model.stat().st_size > 0:
        print(f"[preflight] SMPL model OK: {smpl_model}")
    else:
        official = find_official_smpl_model(Path(args.smpl_search_root))
        if official:
            print(f"[preflight] official SMPL file found: {official}")
            print(f"[preflight] training target MISSING: {smpl_model}")
            print("[preflight] run: conda run -n drivestudio python waymo_workflow/human_pose/cli.py prepare-smpl-model")
        else:
            print(f"[preflight] SMPL model MISSING: {smpl_model}")
            print(f"[preflight] also searched for: {OFFICIAL_SMPL_FILENAME}")
        failed = True

    for scene_id in scenes:
        scene_root = processed_root / f"{scene_id:03d}"
        if not scene_root.exists():
            print(f"[preflight] scene {scene_id}: processed dir MISSING: {scene_root}")
            failed = True
            continue

        images = count_files(scene_root / "images", "*.jpg")
        sky_masks = count_files(scene_root / "sky_masks", "*.png")
        humanpose = scene_root / "humanpose" / "smpl.pkl"
        objects = scene_root / "instances" / "instances_info.json"

        print(f"[preflight] scene {scene_id}: images={images}, sky_masks={sky_masks}")
        if images == 0:
            failed = True
        if sky_masks == 0:
            print(f"[preflight] scene {scene_id}: sky_masks MISSING")
            failed = True
        if humanpose.exists() and humanpose.stat().st_size > 0:
            print(f"[preflight] scene {scene_id}: humanpose OK")
        else:
            print(f"[preflight] scene {scene_id}: humanpose MISSING: {humanpose}")
            failed = True
        if not objects.exists():
            print(f"[preflight] scene {scene_id}: instances_info MISSING: {objects}")
            failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
