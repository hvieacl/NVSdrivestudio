#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

HUMANS4D_ENV_NAME="${HUMANS4D_ENV_NAME:-4D-humans}"
SCENE_IDS="${SCENE_IDS:-0 1 4 8 32 102 109 114 149 156}"
DATA_ROOT="${DATA_ROOT:-data/waymo/processed/training}"
SAVE_TEMP="${SAVE_TEMP:-0}"
VERBOSE="${VERBOSE:-0}"
FPS="${FPS:-12}"

args=()
if [[ "$SAVE_TEMP" == "1" ]]; then
  args+=(--save_temp)
fi
if [[ "$VERBOSE" == "1" ]]; then
  args+=(--verbose)
fi

conda run -n "$HUMANS4D_ENV_NAME" python omnire_workflow/human_pose/cli.py extract \
  --data_root "$DATA_ROOT" \
  --scene_ids "$SCENE_IDS" \
  --fps "$FPS" \
  "${args[@]}"
