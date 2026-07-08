#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${THEOS:-}" ]]; then
  echo "THEOS is not set. Example: export THEOS=$HOME/theos"
  exit 1
fi

make clean package
mkdir -p output
cp packages/*.deb output/ 2>/dev/null || true
sha256sum output/*.deb > output/SHA256SUMS.txt 2>/dev/null || true

echo "Done. Check output/"
