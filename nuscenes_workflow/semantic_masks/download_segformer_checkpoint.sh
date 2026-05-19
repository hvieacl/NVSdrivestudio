#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

SEGFORMER_ENV_NAME="${SEGFORMER_ENV_NAME:-segformer}"
SEGFORMER_ROOT="${SEGFORMER_ROOT:-$REPO_ROOT/../SegFormer}"
SEGFORMER_CHECKPOINT="${SEGFORMER_CHECKPOINT:-$SEGFORMER_ROOT/pretrained/segformer.b5.1024x1024.city.160k.pth}"
HF_URL="${HF_URL:-https://huggingface.co/chromics/segformer.b5.1024x1024.city.160k.pth/resolve/main/segformer.b5.1024x1024.city.160k.pth}"
GDOWN_ID="${GDOWN_ID:-1e7DECAH0TRtPZM6hTqRGoboq1XPqSmuj}"

mkdir -p "$(dirname "$SEGFORMER_CHECKPOINT")"

if [[ -s "$SEGFORMER_CHECKPOINT" ]]; then
  echo "[OK] Checkpoint already exists: $SEGFORMER_CHECKPOINT"
  ls -lh "$SEGFORMER_CHECKPOINT"
  exit 0
fi

echo "[workflow] Downloading SegFormer checkpoint to: $SEGFORMER_CHECKPOINT"

if command -v wget >/dev/null 2>&1; then
  if wget -O "$SEGFORMER_CHECKPOINT.tmp" "$HF_URL"; then
    mv "$SEGFORMER_CHECKPOINT.tmp" "$SEGFORMER_CHECKPOINT"
    ls -lh "$SEGFORMER_CHECKPOINT"
    exit 0
  fi
fi

if command -v curl >/dev/null 2>&1; then
  if curl -L "$HF_URL" -o "$SEGFORMER_CHECKPOINT.tmp"; then
    mv "$SEGFORMER_CHECKPOINT.tmp" "$SEGFORMER_CHECKPOINT"
    ls -lh "$SEGFORMER_CHECKPOINT"
    exit 0
  fi
fi

rm -f "$SEGFORMER_CHECKPOINT.tmp"
echo "[workflow] Hugging Face download failed; trying Google Drive via gdown."
conda run -n "$SEGFORMER_ENV_NAME" python -m pip install gdown
conda run -n "$SEGFORMER_ENV_NAME" gdown "$GDOWN_ID" -O "$SEGFORMER_CHECKPOINT"

if [[ ! -s "$SEGFORMER_CHECKPOINT" ]]; then
  echo "[ERROR] Checkpoint download failed. Put the file manually at: $SEGFORMER_CHECKPOINT" >&2
  exit 1
fi

ls -lh "$SEGFORMER_CHECKPOINT"
