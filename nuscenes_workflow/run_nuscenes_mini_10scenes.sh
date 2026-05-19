#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f /root/miniconda3/etc/profile.d/conda.sh ]]; then
  source /root/miniconda3/etc/profile.d/conda.sh
fi

ENV_NAME="${ENV_NAME:-drivestudio}"
SCENE_IDS="${SCENE_IDS:-0 1 2 3 4 5 6 7 8 9}"
WORKERS="${WORKERS:-4}"
START_TIMESTEP="${START_TIMESTEP:-0}"
END_TIMESTEP="${END_TIMESTEP:--1}"
OUTPUT_ROOT="${OUTPUT_ROOT:-./OutPut}"
PROJECT="${PROJECT:-nuscenes_mini_10scenes}"
CONFIG_FILE="${CONFIG_FILE:-configs/omnire_nuscenes_no_smpl.yaml}"
DATASET="${DATASET:-nuscenes/6cams}"
RAW_ROOT="${RAW_ROOT:-data/nuscenes/raw}"
TARGET_DIR="${TARGET_DIR:-data/nuscenes/processed}"
PROCESSED_ROOT="${PROCESSED_ROOT:-data/nuscenes/processed_10Hz/mini}"
SPLIT="${SPLIT:-v1.0-mini}"
INTERPOLATE_N="${INTERPOLATE_N:-4}"
SKIP_PREPROCESS="${SKIP_PREPROCESS:-0}"
REQUIRE_SKY_MASKS="${REQUIRE_SKY_MASKS:-1}"
AUTO_EXTRACT_MASKS="${AUTO_EXTRACT_MASKS:-1}"
SEGFORMER_ENV_NAME="${SEGFORMER_ENV_NAME:-segformer}"
SEGFORMER_ROOT="${SEGFORMER_ROOT:-$REPO_ROOT/../SegFormer}"
SEGFORMER_CHECKPOINT="${SEGFORMER_CHECKPOINT:-$SEGFORMER_ROOT/pretrained/segformer.b5.1024x1024.city.160k.pth}"
MASK_DEVICE="${MASK_DEVICE:-cuda:0}"
PROCESS_FINE_DYNAMIC_MASKS="${PROCESS_FINE_DYNAMIC_MASKS:-1}"
EXTRA_ARGS="${EXTRA_ARGS:-render.vis_lidar=True render.render_full=True render.render_test=False data.pixel_source.load_smpl=False}"

export PYTHONPATH="$REPO_ROOT${PYTHONPATH:+:$PYTHONPATH}"

if [[ "$SKIP_PREPROCESS" != "1" ]]; then
  conda run -n "$ENV_NAME" python datasets/preprocess.py \
    --data_root "$RAW_ROOT" \
    --target_dir "$TARGET_DIR" \
    --dataset nuscenes \
    --split "$SPLIT" \
    --scene_ids $SCENE_IDS \
    --workers "$WORKERS" \
    --interpolate_N "$INTERPOLATE_N" \
    --process_keys images lidar calib dynamic_masks objects
fi

if [[ "$REQUIRE_SKY_MASKS" == "1" ]]; then
  echo "[workflow] Checking nuScenes sky masks for scenes: $SCENE_IDS"
  if ! conda run -n "$ENV_NAME" python nuscenes_workflow/semantic_masks/cli.py check \
    --data_root "$PROCESSED_ROOT" \
    --scene_ids "$SCENE_IDS" \
    --cameras 0 1 2 3 4 5; then
    if [[ "$AUTO_EXTRACT_MASKS" != "1" ]]; then
      echo "[ERROR] Missing sky masks. Run nuscenes_workflow/semantic_masks/extract_nuscenes_masks.sh first, or set AUTO_EXTRACT_MASKS=1." >&2
      exit 1
    fi
    echo "[workflow] Missing sky masks; running SegFormer extraction with env: $SEGFORMER_ENV_NAME"
    mask_args=()
    if [[ "$PROCESS_FINE_DYNAMIC_MASKS" == "1" ]]; then
      mask_args+=(--process_dynamic_mask)
    fi
    conda run -n "$SEGFORMER_ENV_NAME" python nuscenes_workflow/semantic_masks/cli.py extract \
      --data_root "$PROCESSED_ROOT" \
      --scene_ids "$SCENE_IDS" \
      --segformer_path "$SEGFORMER_ROOT" \
      --checkpoint "$SEGFORMER_CHECKPOINT" \
      --device "$MASK_DEVICE" \
      "${mask_args[@]}"
    conda run -n "$ENV_NAME" python nuscenes_workflow/semantic_masks/cli.py check \
      --data_root "$PROCESSED_ROOT" \
      --scene_ids "$SCENE_IDS" \
      --cameras 0 1 2 3 4 5
  fi
fi

read -r -a extra_args <<< "$EXTRA_ARGS"
for scene_idx in $SCENE_IDS; do
  echo "[workflow] Training nuScenes scene ${scene_idx}"
  conda run -n "$ENV_NAME" python tools/train.py \
    --config_file "$CONFIG_FILE" \
    --output_root "$OUTPUT_ROOT" \
    --project "$PROJECT" \
    --run_name "scene_${scene_idx}" \
    dataset="$DATASET" \
    data.scene_idx="$scene_idx" \
    data.start_timestep="$START_TIMESTEP" \
    data.end_timestep="$END_TIMESTEP" \
    "${extra_args[@]}"
done
