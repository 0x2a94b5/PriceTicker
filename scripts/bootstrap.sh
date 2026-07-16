#!/usr/bin/env bash
set -euo pipefail

XCODEGEN_VERSION="2.38.0"
XCODEGEN_SHA256="aed5bedc80979058287d46b292d3118f89a4cec8e7f1f2ff849e190948c9cd7e"
CACHE_ROOT="${TMPDIR:-/tmp}/priceticker-xcodegen/${XCODEGEN_VERSION}"
ARCHIVE_PATH="${CACHE_ROOT}/xcodegen.zip"
XCODEGEN_BIN="${CACHE_ROOT}/xcodegen/bin/xcodegen"
DOWNLOAD_URL="https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"

mkdir -p "$CACHE_ROOT"

if [[ ! -f "$ARCHIVE_PATH" ]]; then
  echo "→ Downloading XcodeGen ${XCODEGEN_VERSION}..."
  curl \
    --proto '=https' \
    --tlsv1.2 \
    --fail \
    --location \
    --retry 3 \
    "$DOWNLOAD_URL" \
    --output "$ARCHIVE_PATH"
fi

echo "${XCODEGEN_SHA256}  ${ARCHIVE_PATH}" | shasum -a 256 --check

if [[ ! -x "$XCODEGEN_BIN" ]]; then
  echo "→ Extracting XcodeGen..."
  unzip -q -o "$ARCHIVE_PATH" -d "$CACHE_ROOT"
  chmod +x "$XCODEGEN_BIN"
fi

echo "→ Generating Xcode project..."
"$XCODEGEN_BIN" generate

echo "→ Building and testing..."
xcodebuild \
  -project PriceTicker.xcodeproj \
  -scheme PriceTicker \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test

echo "✓ Done. App: build/Debug/PriceTicker.app"
