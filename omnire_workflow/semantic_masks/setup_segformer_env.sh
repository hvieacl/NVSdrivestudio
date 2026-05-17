#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

SEGFORMER_ENV_NAME="${SEGFORMER_ENV_NAME:-segformer}"
SEGFORMER_ROOT="${SEGFORMER_ROOT:-$REPO_ROOT/../SegFormer}"

if ! command -v conda >/dev/null 2>&1; then
  for conda_sh in "$HOME/miniconda3/etc/profile.d/conda.sh" "$HOME/anaconda3/etc/profile.d/conda.sh" "/opt/conda/etc/profile.d/conda.sh"; do
    if [[ -f "$conda_sh" ]]; then
      source "$conda_sh"
      break
    fi
  done
fi

if ! command -v conda >/dev/null 2>&1; then
  echo "[ERROR] conda was not found in PATH." >&2
  exit 1
fi

if ! conda env list | awk '{print $1}' | grep -qx "$SEGFORMER_ENV_NAME"; then
  conda create -n "$SEGFORMER_ENV_NAME" python=3.8 -y
fi

conda run -n "$SEGFORMER_ENV_NAME" python -m pip install --upgrade "pip<24"
conda run -n "$SEGFORMER_ENV_NAME" python -m pip install \
  torch==1.8.1+cu111 torchvision==0.9.1+cu111 torchaudio==0.8.1 \
  -f https://download.pytorch.org/whl/torch_stable.html
conda run -n "$SEGFORMER_ENV_NAME" python -m pip install \
  timm==0.3.2 pylint debugpy opencv-python-headless attrs ipython tqdm imageio scikit-image omegaconf
conda run -n "$SEGFORMER_ENV_NAME" python -m pip install mmcv-full==1.2.7 --no-cache-dir

if [[ ! -d "$SEGFORMER_ROOT/.git" ]]; then
  git clone --depth 1 https://github.com/NVlabs/SegFormer "$SEGFORMER_ROOT"
fi

conda run -n "$SEGFORMER_ENV_NAME" python -m pip install -e "$SEGFORMER_ROOT"

mkdir -p "$SEGFORMER_ROOT/pretrained"
echo "[OK] SegFormer env is ready: $SEGFORMER_ENV_NAME"
echo "[NEXT] Put segformer.b5.1024x1024.city.160k.pth under:"
echo "       $SEGFORMER_ROOT/pretrained/"
