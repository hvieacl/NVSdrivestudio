#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -f /root/miniconda3/etc/profile.d/conda.sh ]]; then
  source /root/miniconda3/etc/profile.d/conda.sh
fi

ENV_NAME="${ENV_NAME:-drivestudio}"
SCENE_IDS="${SCENE_IDS:-0 1 2 3 4 5 6 7 8 9}"
DATA_ROOT="${DATA_ROOT:-data/nuscenes/processed_10Hz/mini}"

conda run -n "$ENV_NAME" python nuscenes_workflow/semantic_masks/cli.py check \
  --data_root "$DATA_ROOT" \
  --scene_ids "$SCENE_IDS" \
  --cameras 0 1 2 3 4 5
