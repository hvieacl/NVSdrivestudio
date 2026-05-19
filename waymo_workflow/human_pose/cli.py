"""Check and prepare Waymo human pose data for OmniRe."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Optional


DEFAULT_SCENES = "0 1 4 8 32 102 109 114 149 156"
WAYMO_HUMANPOSE_GDOWN_ID = "1QrtMrPAQhfSABpfgQWJZA2o_DDamL_7_"
OFFICIAL_SMPL_FILENAME = "basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl"


def parse_ids(value: Optional[str]) -> List[int]:
    if not value:
        return [int(v) for v in DEFAULT_SCENES.split()]
    return [int(v) for v in value.replace(",", " ").split()]


def scene_dir(data_root: Path, scene_id: int) -> Path:
    return data_root / f"{scene_id:03d}"


def find_official_smpl_model(search_root: Path) -> Optional[Path]:
    direct = search_root / OFFICIAL_SMPL_FILENAME
    if direct.exists() and direct.stat().st_size > 0:
        return direct
    matches = list(search_root.rglob(OFFICIAL_SMPL_FILENAME))
    for match in matches:
        if match.exists() and match.stat().st_size > 0:
            return match
    return None


def prepare_smpl_model(args: argparse.Namespace) -> int:
    target = Path(args.smpl_model)
    source = Path(args.source) if args.source else find_official_smpl_model(Path(args.search_root))
    if target.exists() and target.stat().st_size > 0:
        print(f"[humanpose-smpl] target already exists: {target}")
        return 0
    if source is None or not source.exists():
        print(f"[humanpose-smpl] official SMPL file not found: {OFFICIAL_SMPL_FILENAME}", file=sys.stderr)
        print("[humanpose-smpl] Put it under smpl_models/ or pass --source /path/to/file.", file=sys.stderr)
        return 1
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    print(f"[humanpose-smpl] copied {source} -> {target}")
    return 0


def check(args: argparse.Namespace) -> int:
    data_root = Path(args.data_root)
    smpl_model = Path(args.smpl_model)
    scenes = parse_ids(args.scene_ids)
    failed = False

    if args.require_smpl_model:
        if smpl_model.exists() and smpl_model.stat().st_size > 0:
            print(f"[humanpose-check] SMPL model OK: {smpl_model}")
        else:
            official = find_official_smpl_model(Path(args.smpl_search_root))
            if official and args.auto_prepare_smpl_model:
                prep_args = argparse.Namespace(
                    smpl_model=str(smpl_model),
                    source=str(official),
                    search_root=args.smpl_search_root,
                )
                failed = (prepare_smpl_model(prep_args) != 0) or failed
            elif official:
                print(f"[humanpose-check] official SMPL file found: {official}")
                print(f"[humanpose-check] training expects: {smpl_model}")
                print("[humanpose-check] Run: python waymo_workflow/human_pose/cli.py prepare-smpl-model")
                failed = True
            else:
                print(f"[humanpose-check] missing SMPL model: {smpl_model}")
                print("[humanpose-check] Download SMPL v1.1 from https://smpl.is.tue.mpg.de/download.php")
                print(f"[humanpose-check] Put {OFFICIAL_SMPL_FILENAME} under smpl_models/ or copy it to {smpl_model}")
                failed = True

    for scene_id in scenes:
        root = scene_dir(data_root, scene_id)
        smpl_pkl = root / "humanpose" / "smpl.pkl"
        if smpl_pkl.exists() and smpl_pkl.stat().st_size > 0:
            print(f"[humanpose-check] scene {scene_id}: humanpose OK ({smpl_pkl})")
        else:
            print(f"[humanpose-check] scene {scene_id}: missing {smpl_pkl}")
            failed = True

    return 1 if failed else 0


def download_preprocessed(args: argparse.Namespace) -> int:
    target_dir = Path(args.target_dir)
    target_dir.mkdir(parents=True, exist_ok=True)
    archive = target_dir / args.archive_name
    legacy_archive = target_dir / "waymo_preprocess_humanpose.zip"
    if not archive.exists() and legacy_archive.exists():
        print(f"[humanpose-download] using legacy archive name: {legacy_archive}")
        archive = legacy_archive
    if not archive.exists():
        command = [
            sys.executable,
            "-m",
            "gdown",
            args.gdown_id,
            "-O",
            str(archive),
        ]
        print("[humanpose-download] " + " ".join(command), flush=True)
        rc = subprocess.call(command)
        if rc != 0:
            print("[humanpose-download] gdown failed. Download manually from DriveStudio docs/Waymo.md.", file=sys.stderr)
            return rc
    else:
        print(f"[humanpose-download] archive already exists: {archive}")

    command = ["unzip", "-o", str(archive), "-d", str(target_dir)]
    print("[humanpose-download] " + " ".join(command), flush=True)
    return subprocess.call(command)


def extract(args: argparse.Namespace) -> int:
    command = [
        sys.executable,
        "datasets/tools/humanpose_process.py",
        "--dataset",
        "waymo",
        "--data_root",
        args.data_root,
        "--scene_ids",
        *[str(v) for v in parse_ids(args.scene_ids)],
        "--fps",
        str(args.fps),
    ]
    if args.save_temp:
        command.append("--save_temp")
    if args.verbose:
        command.append("--verbose")
    print("[humanpose-extract] " + " ".join(command), flush=True)
    return subprocess.call(command)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    check_parser = subparsers.add_parser("check", help="Check SMPL model and per-scene humanpose files.")
    check_parser.add_argument("--data_root", default="data/waymo/processed/training")
    check_parser.add_argument("--scene_ids", default=DEFAULT_SCENES)
    check_parser.add_argument("--smpl_model", default="smpl_models/SMPL_NEUTRAL.pkl")
    check_parser.add_argument("--smpl_search_root", default="smpl_models")
    check_parser.add_argument("--require_smpl_model", action="store_true")
    check_parser.add_argument("--auto_prepare_smpl_model", action="store_true")
    check_parser.set_defaults(func=check)

    smpl_parser = subparsers.add_parser(
        "prepare-smpl-model",
        help="Copy the official SMPL filename to the DriveStudio training filename.",
    )
    smpl_parser.add_argument("--source", default=None)
    smpl_parser.add_argument("--search_root", default="smpl_models")
    smpl_parser.add_argument("--smpl_model", default="smpl_models/SMPL_NEUTRAL.pkl")
    smpl_parser.set_defaults(func=prepare_smpl_model)

    download_parser = subparsers.add_parser("download-preprocessed", help="Download official preprocessed Waymo humanpose zip.")
    download_parser.add_argument("--target_dir", default="data")
    download_parser.add_argument("--gdown_id", default=WAYMO_HUMANPOSE_GDOWN_ID)
    download_parser.add_argument("--archive_name", default="waymo_processed_humanpose.zip")
    download_parser.set_defaults(func=download_preprocessed)

    extract_parser = subparsers.add_parser("extract", help="Run the 4D-Humans based extraction pipeline.")
    extract_parser.add_argument("--data_root", default="data/waymo/processed/training")
    extract_parser.add_argument("--scene_ids", default=DEFAULT_SCENES)
    extract_parser.add_argument("--save_temp", action="store_true")
    extract_parser.add_argument("--verbose", action="store_true")
    extract_parser.add_argument("--fps", type=int, default=12)
    extract_parser.set_defaults(func=extract)

    return parser


def main() -> int:
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
