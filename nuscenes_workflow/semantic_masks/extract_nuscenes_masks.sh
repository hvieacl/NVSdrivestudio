#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -f /root/miniconda3/etc/profile.d/conda.sh ]]; then
  source /root/miniconda3/etc/profile.d/conda.sh
fi

SEGFORMER_ENV_NAME="${SEGFORMER_ENV_NAME:-segformer}"
SCENE_IDS="${SCENE_IDS:-0 1 2 3 4 5 6 7 8 9}"
DATA_ROOT="${DATA_ROOT:-data/nuscenes/processed_10Hz/mini}"
SEGFORMER_ROOT="${SEGFORMER_ROOT:-$REPO_ROOT/../SegFormer}"
SEGFORMER_CHECKPOINT="${SEGFORMER_CHECKPOINT:-$SEGFORMER_ROOT/pretrained/segformer.b5.1024x1024.city.160k.pth}"
MASK_DEVICE="${MASK_DEVICE:-cuda:0}"
PROCESS_FINE_DYNAMIC_MASKS="${PROCESS_FINE_DYNAMIC_MASKS:-1}"

extra_args=()
if [[ "$PROCESS_FINE_DYNAMIC_MASKS" == "1" ]]; then
  extra_args+=(--process_dynamic_mask)
fi

conda run -n "$SEGFORMER_ENV_NAME" python nuscenes_workflow/semantic_masks/cli.py extract \
  --data_root "$DATA_ROOT" \
  --scene_ids "$SCENE_IDS" \
  --segformer_path "$SEGFORMER_ROOT" \
  --checkpoint "$SEGFORMER_CHECKPOINT" \
  --device "$MASK_DEVICE" \
  "${extra_args[@]}"

conda run -n "$SEGFORMER_ENV_NAME" python nuscenes_workflow/semantic_masks/cli.py check \
  --data_root "$DATA_ROOT" \
  --scene_ids "$SCENE_IDS" \
  --cameras 0 1 2 3 4 5
