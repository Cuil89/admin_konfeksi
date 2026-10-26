#!/bin/bash
set -e

# Disable git safe directory check in CI container
git config --global --add safe.directory '*' || true

echo "=== Installing Flutter SDK ==="
if [ ! -d "flutter-sdk" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter-sdk
else
  echo "Flutter SDK already cached."
fi

export PATH="$PATH:`pwd`/flutter-sdk/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Building Flutter Web ==="
flutter build web --release

echo "=== Build finished successfully! ==="
