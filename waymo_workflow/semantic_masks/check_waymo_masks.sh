#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -f /root/miniconda3/etc/profile.d/conda.sh ]]; then
  source /root/miniconda3/etc/profile.d/conda.sh
fi

ENV_NAME="${ENV_NAME:-drivestudio}"
SCENE_IDS="${SCENE_IDS:-0 1 4 8 32 102 109 114 149 156}"
DATA_ROOT="${DATA_ROOT:-data/waymo/processed/training}"

conda run -n "$ENV_NAME" python waymo_workflow/semantic_masks/cli.py check \
  --data_root "$DATA_ROOT" \
  --scene_ids "$SCENE_IDS"
