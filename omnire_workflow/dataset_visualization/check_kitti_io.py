"""Check converted Waymo-KITTI visualization inputs are aligned."""

from __future__ import annotations

import argparse
from pathlib import Path


def ids_in(folder: Path, suffix: str) -> set[str]:
    if not folder.exists():
        return set()
    return {path.stem for path in folder.glob(f"*{suffix}") if path.is_file()}


def validate_kitti_root(kitti_root: str | Path, camera_id: str = "0") -> None:
    root = Path(kitti_root).resolve()
    folders = {
        "velodyne": root / "velodyne",
        "calib": root / "calib",
        "pose": root / "pose",
        f"image_{camera_id}": root / f"image_{camera_id}",
        f"label_{camera_id}": root / f"label_{camera_id}",
        "label_all": root / "label_all",
    }
    missing_dirs = [name for name, folder in folders.items() if not folder.exists()]
    if missing_dirs:
        raise SystemExit(f"[ERROR] Missing directories under {root}: {', '.join(missing_dirs)}")
    id_sets = {
        name: ids_in(folder, ".bin" if name == "velodyne" else ".png" if name.startswith("image_") else ".txt")
        for name, folder in folders.items()
    }
    base = id_sets["velodyne"]
    if not base:
        raise SystemExit("[ERROR] No velodyne .bin files found")
    failed = False
    for name, values in id_sets.items():
        print(f"[INFO] {name}: {len(values)} files")
        missing = base - values
        if missing:
            failed = True
            print(f"[ERROR] {name} missing IDs: {', '.join(sorted(missing)[:10])}")
    if failed:
        raise SystemExit("[ERROR] Converted data is not aligned")
    print(f"[OK] {root} is aligned")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--kitti_root", required=True)
    parser.add_argument("--camera_id", default="0")
    args = parser.parse_args()
    validate_kitti_root(args.kitti_root, args.camera_id)


if __name__ == "__main__":
    main()
