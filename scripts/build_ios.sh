#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUILD_NAME="${BUILD_NAME:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
CODE_SIGNING="${CODE_SIGNING:---no-codesign}"

echo "Building CatDex iOS release ${BUILD_NAME}+${BUILD_NUMBER}"
flutter build ipa \
  --release \
  "$CODE_SIGNING" \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER"
