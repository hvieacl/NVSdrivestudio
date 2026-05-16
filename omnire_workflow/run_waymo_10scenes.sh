#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ENV_NAME="${ENV_NAME:-drivestudio}"
SCENE_IDS="${SCENE_IDS:-0 1 4 8 32 102 109 114 149 156}"
WORKERS="${WORKERS:-4}"
START_TIMESTEP="${START_TIMESTEP:-0}"
END_TIMESTEP="${END_TIMESTEP:--1}"
OUTPUT_ROOT="${OUTPUT_ROOT:-./OutPut}"
PROJECT="${PROJECT:-waymo_training_10scenes}"
CONFIG_FILE="${CONFIG_FILE:-configs/omnire.yaml}"
DATASET="${DATASET:-waymo/3cams}"
SKIP_PREPROCESS="${SKIP_PREPROCESS:-0}"

export PYTHONPATH="$REPO_ROOT${PYTHONPATH:+:$PYTHONPATH}"

if [[ "$SKIP_PREPROCESS" != "1" ]]; then
  conda run -n "$ENV_NAME" python datasets/preprocess.py \
    --data_root data/waymo/raw/ \
    --target_dir data/waymo/processed \
    --dataset waymo \
    --split training \
    --scene_ids $SCENE_IDS \
    --workers "$WORKERS" \
    --process_keys images lidar calib pose dynamic_masks objects
fi

for scene_idx in $SCENE_IDS; do
  conda run -n "$ENV_NAME" python tools/train.py \
    --config_file "$CONFIG_FILE" \
    --output_root "$OUTPUT_ROOT" \
    --project "$PROJECT" \
    --run_name "scene_${scene_idx}" \
    dataset="$DATASET" \
    data.scene_idx="$scene_idx" \
    data.start_timestep="$START_TIMESTEP" \
    data.end_timestep="$END_TIMESTEP"
done
