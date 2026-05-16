#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
VIZ_ENV_NAME="${VIZ_ENV_NAME:-waymo-kitti-viz}"
SCENE_IDX="${SCENE_IDX:-114}"
PROJECT_OUTPUT="${PROJECT_OUTPUT:-OutPut/waymo_training_10scenes}"
CAMERA_ID="${CAMERA_ID:-0}"
CLASSES="${CLASSES:-Car}"
START_FRAME="${START_FRAME:-0}"
END_FRAME="${END_FRAME:--1}"
conda run -n "$VIZ_ENV_NAME" python omnire_workflow/dataset_visualization/view_kitti_scene.py \
  --kitti_root "$PROJECT_OUTPUT/scene_$SCENE_IDX/dataset_visualization/kitti" \
  --camera_id "$CAMERA_ID" \
  --classes "$CLASSES" \
  --start_frame "$START_FRAME" \
  --end_frame "$END_FRAME"
