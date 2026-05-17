#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ENV_NAME="${ENV_NAME:-drivestudio}"
SCENE_IDS="${SCENE_IDS:-0 1 4 8 32 102 109 114 149 156}"
DATA_ROOT="${DATA_ROOT:-data/waymo/processed/training}"
SMPL_MODEL="${SMPL_MODEL:-smpl_models/SMPL_NEUTRAL.pkl}"
REQUIRE_SMPL_MODEL="${REQUIRE_SMPL_MODEL:-1}"

args=()
if [[ "$REQUIRE_SMPL_MODEL" == "1" ]]; then
  args+=(--require_smpl_model)
fi

conda run -n "$ENV_NAME" python omnire_workflow/human_pose/cli.py check \
  --data_root "$DATA_ROOT" \
  --scene_ids "$SCENE_IDS" \
  --smpl_model "$SMPL_MODEL" \
  "${args[@]}"
