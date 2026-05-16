#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
VIZ_ENV_NAME="${VIZ_ENV_NAME:-waymo-kitti-viz}"
conda create -n "$VIZ_ENV_NAME" python=3.8 -y || true
conda run -n "$VIZ_ENV_NAME" python -m pip install --upgrade pip
conda run -n "$VIZ_ENV_NAME" pip install tensorflow==2.11.* waymo-open-dataset-tf-2-11-0==1.6.0 opencv-python tqdm matplotlib
conda run -n "$VIZ_ENV_NAME" pip install numpy==1.21.3 vedo==2021.0.6 vtk==9.0.3 opencv-python==4.5.4.58 matplotlib==3.4.3
