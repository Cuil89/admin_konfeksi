#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
if [ ! -d "flutter-sdk" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter-sdk
else
  echo "Flutter SDK already cached."
fi

export PATH="$PATH:`pwd`/flutter-sdk/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Getting dependencies ==="
flutter pub get

echo "=== Building Flutter Web ==="
flutter build web --release

echo "=== Build finished successfully! ==="
