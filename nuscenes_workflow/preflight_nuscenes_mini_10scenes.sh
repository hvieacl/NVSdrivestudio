#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f /root/miniconda3/etc/profile.d/conda.sh ]]; then
  source /root/miniconda3/etc/profile.d/conda.sh
fi

ENV_NAME="${ENV_NAME:-drivestudio}"
SCENE_IDS="${SCENE_IDS:-0 1 2 3 4 5 6 7 8 9}"
RAW_ROOT="${RAW_ROOT:-data/nuscenes/raw}"
PROCESSED_ROOT="${PROCESSED_ROOT:-data/nuscenes/processed_10Hz/mini}"
REQUIRE_SKY_MASKS="${REQUIRE_SKY_MASKS:-1}"

args=()
if [[ "$REQUIRE_SKY_MASKS" == "1" ]]; then
  args+=(--require_sky_masks)
fi

conda run -n "$ENV_NAME" python nuscenes_workflow/preflight.py \
  --scene_ids "$SCENE_IDS" \
  --raw_dir "$RAW_ROOT" \
  --processed_root "$PROCESSED_ROOT" \
  --check_imports \
  "${args[@]}"
