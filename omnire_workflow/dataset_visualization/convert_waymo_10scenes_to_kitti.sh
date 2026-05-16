#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
VIZ_ENV_NAME="${VIZ_ENV_NAME:-waymo-kitti-viz}"
conda run -n "$VIZ_ENV_NAME" python -m omnire_workflow.dataset_visualization.cli convert-ten "$@"
