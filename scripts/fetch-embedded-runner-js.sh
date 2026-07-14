#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$ROOT_DIR/packages/app/assets/embedded-runner-js"
RELEASE_TAG="${RUNNER_JS_RELEASE_TAG:-}"
GITHUB_REPO="${RUNNER_JS_GITHUB_REPO:-ketsuna-org/runner-js}"
MIN_BYTES=1048576

mkdir -p "$ASSET_DIR"

resolve_release_tag() {
  if [ -z "$RELEASE_TAG" ]; then
    echo ""
    return
  fi
  if [ "$RELEASE_TAG" != "latest" ]; then
    echo "$RELEASE_TAG"
    return
  fi
  curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -1
}

verify_asset() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "[fetch-embedded-runner-js] missing asset: $path" >&2
    exit 1
  fi
  local size
  size="$(wc -c < "$path" | tr -d ' ')"
  if [ "$size" -lt "$MIN_BYTES" ]; then
    echo "[fetch-embedded-runner-js] asset too small ($size bytes): $path" >&2
    exit 1
  fi
  local sha
  sha="$(sha256sum "$path" | awk '{print $1}')"
  echo "[fetch-embedded-runner-js] verified $path (${size} bytes, sha256=${sha})"
}

if [ -z "$RELEASE_TAG" ]; then
  echo "[fetch-embedded-runner-js] RUNNER_JS_RELEASE_TAG not set — skipping download"
  exit 0
fi

RESOLVED_TAG="$(resolve_release_tag)"
if [ -z "$RESOLVED_TAG" ]; then
  echo "[fetch-embedded-runner-js] could not resolve release tag from RUNNER_JS_RELEASE_TAG=$RELEASE_TAG" >&2
  exit 1
fi

echo "[fetch-embedded-runner-js] using release tag: $RESOLVED_TAG"

download_asset() {
  local name="$1"
  local url="https://github.com/${GITHUB_REPO}/releases/download/${RESOLVED_TAG}/${name}"
  local dest="$ASSET_DIR/$name"
  echo "[fetch-embedded-runner-js] downloading $url"
  curl -fsSL "$url" -o "$dest"
  if [ "${name##*.}" != "exe" ]; then
    chmod +x "$dest" || true
  fi
  verify_asset "$dest"
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
  *)
    echo "unsupported TARGET_PLATFORM=$TARGET_PLATFORM" >&2
    exit 1
    ;;
esac

echo "[fetch-embedded-runner-js] assets ready in $ASSET_DIR"
