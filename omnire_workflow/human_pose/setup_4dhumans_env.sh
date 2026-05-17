#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

HUMANS4D_ENV_NAME="${HUMANS4D_ENV_NAME:-4D-humans}"

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

git submodule update --init --recursive

if ! conda env list | awk '{print $1}' | grep -qx "$HUMANS4D_ENV_NAME"; then
  conda create --name "$HUMANS4D_ENV_NAME" python=3.10 -y
fi

conda run -n "$HUMANS4D_ENV_NAME" python -m pip install --upgrade pip
conda run -n "$HUMANS4D_ENV_NAME" python -m pip install torch
conda run -n "$HUMANS4D_ENV_NAME" python -m pip install -e "third_party/Humans4D[all]"
conda run -n "$HUMANS4D_ENV_NAME" python -m pip install git+https://github.com/brjathu/PHALP.git
conda run -n "$HUMANS4D_ENV_NAME" python -m pip install git+https://github.com/facebookresearch/pytorch3d.git --no-build-isolation

echo "[OK] 4D-Humans env is ready: $HUMANS4D_ENV_NAME"
