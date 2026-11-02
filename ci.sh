#!/usr/bin/env bash
# Збірка, тестування та пакування hello (Linux / macOS).
set -euo pipefail
cd "$(dirname "$0")"

BUILD_DIR=build
DIST_DIR=dist

echo "==> Configure"
cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release

echo "==> Build (Release)"
cmake --build "$BUILD_DIR" --config Release

echo "==> Test"
ctest --test-dir "$BUILD_DIR" -C Release --output-on-failure

echo "==> Package"
mkdir -p "$DIST_DIR"
if [ -f "$BUILD_DIR/hello" ]; then
  BIN="$BUILD_DIR/hello"
else
  BIN="$BUILD_DIR/Release/hello"
fi
cp "$BIN" "$DIST_DIR/hello"

echo "==> Run"
"./$DIST_DIR/hello"
