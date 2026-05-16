#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
VIZ_ENV_NAME="${VIZ_ENV_NAME:-waymo-kitti-viz}"
TFRECORD_FILE="${TFRECORD_FILE:-data/waymo/raw/train_segment-12505030131868863688_1740_000_1760_000_with_camera_labels.tfrecord}"
KITTI_OUT="${KITTI_OUT:-OutPut/waymo_training_10scenes/scene_114/dataset_visualization/kitti}"
NUM_PROC="${NUM_PROC:-1}"
tmp_dir="visualization_outputs/_staging/$(basename "$TFRECORD_FILE" .tfrecord)"
mkdir -p "$tmp_dir" "$KITTI_OUT"
ln -f "$TFRECORD_FILE" "$tmp_dir/$(basename "$TFRECORD_FILE")" 2>/dev/null || cp -f "$TFRECORD_FILE" "$tmp_dir/"
conda run -n "$VIZ_ENV_NAME" python external_tools/waymo_kitti_converter/converter.py "$tmp_dir" "$KITTI_OUT" --num_proc "$NUM_PROC"
