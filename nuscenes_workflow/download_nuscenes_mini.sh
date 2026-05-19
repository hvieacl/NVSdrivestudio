#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RAW_ROOT="${RAW_ROOT:-data/nuscenes/raw}"
URL="${URL:-https://www.nuscenes.org/data/v1.0-mini.tgz}"

mkdir -p "$RAW_ROOT"
cd "$RAW_ROOT"

echo "[nuscenes-download] downloading: $URL"
wget -c --timeout=30 --tries=20 "$URL"

echo "[nuscenes-download] extracting v1.0-mini.tgz"
tar -xzf v1.0-mini.tgz

echo "[nuscenes-download] expected layout:"
find . -maxdepth 2 -type d | sort | head -50
