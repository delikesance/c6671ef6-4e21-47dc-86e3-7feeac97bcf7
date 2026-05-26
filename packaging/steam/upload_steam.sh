#!/usr/bin/env bash
# Upload builds to Steam via steamcmd.
# Usage: upload_steam.sh <platform>
#   platform: win | linux | mac
#
# Required environment variables:
#   STEAM_USERNAME  - Steam account with Steamworks access
#   STEAM_PASSWORD  - Steam account password
#   STEAM_CMD_PATH  - Path to steamcmd binary (default: steamcmd)
#
# Expects build artifacts to be in:
#   packaging/steam/content_win/    (Windows)
#   packaging/steam/content_linux/  (Linux)
#   packaging/steam/content_mac/    (macOS)

set -euo pipefail

PLATFORM="${1:-}"
case "$PLATFORM" in
  win)   VDF="build_win.vdf"   ;;
  linux) VDF="build_linux.vdf" ;;
  mac)   VDF="build_mac.vdf"   ;;
  *)     echo "Usage: $0 <win|linux|mac>" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VDF_PATH="${SCRIPT_DIR}/${VDF}"

if [ ! -f "$VDF_PATH" ]; then
  echo "Error: VDF not found at $VDF_PATH" >&2
  exit 1
fi

STEAM="${STEAM_CMD_PATH:-steamcmd}"

echo "=== Uploading ${PLATFORM} build to Steam ==="
echo "VDF: ${VDF_PATH}"

# steamcmd exits with 0 only if the upload succeeds.
# +force_install_dir is needed for steamcmd to know where to put its own files.
"$STEAM" \
  +login "${STEAM_USERNAME}" "${STEAM_PASSWORD}" \
  -app_build "${VDF_PATH}" \
  +quit

echo "=== Steam upload for ${PLATFORM} complete ==="