#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$ROOT_DIR/packages/app/assets/embedded-runner-js"
RELEASE_TAG="${RUNNER_JS_RELEASE_TAG:-}"
GITHUB_REPO="${RUNNER_JS_GITHUB_REPO:-garder500/runner-js}"

mkdir -p "$ASSET_DIR"

if [ -z "$RELEASE_TAG" ]; then
  echo "[fetch-embedded-runner-js] RUNNER_JS_RELEASE_TAG not set — skipping download"
  exit 0
fi

download_asset() {
  local name="$1"
  local url="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${name}"
  echo "[fetch-embedded-runner-js] downloading $url"
  curl -fsSL "$url" -o "$ASSET_DIR/$name"
  if [ "${name##*.}" != "exe" ]; then
    chmod +x "$ASSET_DIR/$name" || true
  fi
}

case "${TARGET_PLATFORM:-linux-x64}" in
  linux-x64)
    download_asset "bot-creator-runner-js-linux-x64"
    ;;
  linux-arm64)
    download_asset "bot-creator-runner-js-linux-arm64"
    ;;
  windows)
    download_asset "bot-creator-runner-js-win.exe"
    ;;
  macos-arm64)
    download_asset "bot-creator-runner-js-macos-arm64"
    ;;
  macos-x64)
    download_asset "bot-creator-runner-js-macos-x64"
    ;;
  *)
    echo "unsupported TARGET_PLATFORM=$TARGET_PLATFORM" >&2
    exit 1
    ;;
esac

echo "[fetch-embedded-runner-js] assets ready in $ASSET_DIR"
