#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ENV_NAME="${ENV_NAME:-drivestudio}"
TARGET_DIR="${TARGET_DIR:-data}"
GDOWN_ID="${GDOWN_ID:-1QrtMrPAQhfSABpfgQWJZA2o_DDamL_7_}"

conda run -n "$ENV_NAME" python -m pip install gdown
conda run -n "$ENV_NAME" python omnire_workflow/human_pose/cli.py download-preprocessed \
  --target_dir "$TARGET_DIR" \
  --gdown_id "$GDOWN_ID"
