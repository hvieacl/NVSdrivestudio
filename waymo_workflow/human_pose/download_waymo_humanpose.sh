#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -f /root/miniconda3/etc/profile.d/conda.sh ]]; then
  source /root/miniconda3/etc/profile.d/conda.sh
fi

ENV_NAME="${ENV_NAME:-drivestudio}"
TARGET_DIR="${TARGET_DIR:-data}"
GDOWN_ID="${GDOWN_ID:-1QrtMrPAQhfSABpfgQWJZA2o_DDamL_7_}"
ARCHIVE_NAME="${ARCHIVE_NAME:-waymo_processed_humanpose.zip}"

conda run -n "$ENV_NAME" python -m pip install gdown
conda run -n "$ENV_NAME" python waymo_workflow/human_pose/cli.py download-preprocessed \
  --target_dir "$TARGET_DIR" \
  --gdown_id "$GDOWN_ID" \
  --archive_name "$ARCHIVE_NAME"
