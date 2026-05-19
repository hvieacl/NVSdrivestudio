#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f /root/miniconda3/etc/profile.d/conda.sh ]]; then
  source /root/miniconda3/etc/profile.d/conda.sh
fi

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
REQUIRE_SKY_MASKS="${REQUIRE_SKY_MASKS:-1}"
AUTO_EXTRACT_MASKS="${AUTO_EXTRACT_MASKS:-1}"
SEGFORMER_ENV_NAME="${SEGFORMER_ENV_NAME:-segformer}"
SEGFORMER_ROOT="${SEGFORMER_ROOT:-$REPO_ROOT/../SegFormer}"
SEGFORMER_CHECKPOINT="${SEGFORMER_CHECKPOINT:-$SEGFORMER_ROOT/pretrained/segformer.b5.1024x1024.city.160k.pth}"
MASK_DEVICE="${MASK_DEVICE:-cuda:0}"
PROCESS_FINE_DYNAMIC_MASKS="${PROCESS_FINE_DYNAMIC_MASKS:-1}"
REQUIRE_HUMANPOSE="${REQUIRE_HUMANPOSE:-1}"
AUTO_DOWNLOAD_HUMANPOSE="${AUTO_DOWNLOAD_HUMANPOSE:-1}"
HUMANPOSE_ARCHIVE_NAME="${HUMANPOSE_ARCHIVE_NAME:-waymo_processed_humanpose.zip}"
REQUIRE_SMPL_MODEL="${REQUIRE_SMPL_MODEL:-1}"
AUTO_PREPARE_SMPL_MODEL="${AUTO_PREPARE_SMPL_MODEL:-1}"
SMPL_MODEL="${SMPL_MODEL:-smpl_models/SMPL_NEUTRAL.pkl}"
EXTRA_ARGS="${EXTRA_ARGS:-}"

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

if [[ "$REQUIRE_SKY_MASKS" == "1" ]]; then
  echo "[workflow] Checking Waymo sky masks for scenes: $SCENE_IDS"
  if ! conda run -n "$ENV_NAME" python waymo_workflow/semantic_masks/cli.py check \
    --data_root data/waymo/processed/training \
    --scene_ids "$SCENE_IDS"; then
    if [[ "$AUTO_EXTRACT_MASKS" != "1" ]]; then
      echo "[ERROR] Missing sky masks. Run waymo_workflow/semantic_masks/extract_waymo_masks.sh first, or set AUTO_EXTRACT_MASKS=1." >&2
      exit 1
    fi
    echo "[workflow] Missing sky masks; running SegFormer extraction with env: $SEGFORMER_ENV_NAME"
    mask_args=()
    if [[ "$PROCESS_FINE_DYNAMIC_MASKS" == "1" ]]; then
      mask_args+=(--process_dynamic_mask)
    fi
    conda run -n "$SEGFORMER_ENV_NAME" python waymo_workflow/semantic_masks/cli.py extract \
      --data_root data/waymo/processed/training \
      --scene_ids "$SCENE_IDS" \
      --segformer_path "$SEGFORMER_ROOT" \
      --checkpoint "$SEGFORMER_CHECKPOINT" \
      --device "$MASK_DEVICE" \
      "${mask_args[@]}"
    conda run -n "$ENV_NAME" python waymo_workflow/semantic_masks/cli.py check \
      --data_root data/waymo/processed/training \
      --scene_ids "$SCENE_IDS"
  fi
fi

if [[ "$REQUIRE_HUMANPOSE" == "1" ]]; then
  echo "[workflow] Checking Waymo humanpose/SMPL prerequisites for scenes: $SCENE_IDS"
  humanpose_args=()
  if [[ "$REQUIRE_SMPL_MODEL" == "1" ]]; then
    humanpose_args+=(--require_smpl_model)
  fi
  if [[ "$AUTO_PREPARE_SMPL_MODEL" == "1" ]]; then
    humanpose_args+=(--auto_prepare_smpl_model)
  fi
  if ! conda run -n "$ENV_NAME" python waymo_workflow/human_pose/cli.py check \
    --data_root data/waymo/processed/training \
    --scene_ids "$SCENE_IDS" \
    --smpl_model "$SMPL_MODEL" \
    "${humanpose_args[@]}"; then
    if [[ "$AUTO_DOWNLOAD_HUMANPOSE" == "1" ]]; then
      echo "[workflow] Trying to download DriveStudio preprocessed Waymo humanpose package."
      conda run -n "$ENV_NAME" python -m pip install gdown
      conda run -n "$ENV_NAME" python waymo_workflow/human_pose/cli.py download-preprocessed \
        --target_dir data \
        --archive_name "$HUMANPOSE_ARCHIVE_NAME"
    fi
    conda run -n "$ENV_NAME" python waymo_workflow/human_pose/cli.py check \
      --data_root data/waymo/processed/training \
      --scene_ids "$SCENE_IDS" \
      --smpl_model "$SMPL_MODEL" \
      "${humanpose_args[@]}"
  fi
fi

read -r -a extra_args <<< "$EXTRA_ARGS"
for scene_idx in $SCENE_IDS; do
  echo "[workflow] Training scene ${scene_idx}"
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
