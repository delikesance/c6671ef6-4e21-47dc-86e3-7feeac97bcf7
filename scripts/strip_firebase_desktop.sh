#!/bin/bash
# Post-pub-get hook: strip Firebase native plugins from desktop platform registrants.
# Firebase is only supported on Android/iOS in this project.
#
# Usage: from repo root — ./scripts/strip_firebase_desktop.sh
# Or add to CI: flutter pub get && ./scripts/strip_firebase_desktop.sh

set -euo pipefail
APP=packages/app

# --- Windows ---
if [ -f "$APP/windows/flutter/generated_plugins.cmake" ]; then
  sed -i '/firebase_core/d' "$APP/windows/flutter/generated_plugins.cmake"
  echo "[strip_firebase] Windows: removed firebase_core from generated_plugins.cmake"
fi

if [ -f "$APP/windows/flutter/generated_plugin_registrant.cc" ]; then
  sed -i '/firebase_core/d' "$APP/windows/flutter/generated_plugin_registrant.cc"
  echo "[strip_firebase] Windows: removed firebase_core from generated_plugin_registrant.cc"
fi

# --- macOS (BSD sed) ---
if [ -f "$APP/macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  sed -i.bak '/firebase_/d' "$APP/macos/Flutter/GeneratedPluginRegistrant.swift"
  rm -f "$APP/macos/Flutter/GeneratedPluginRegistrant.swift.bak"
  echo "[strip_firebase] macOS: removed firebase_* from GeneratedPluginRegistrant.swift"
fi

# --- Linux (already clean, no firebase plugins exist for Linux) ---
if [ -f "$APP/linux/flutter/generated_plugins.cmake" ]; then
  if grep -q firebase "$APP/linux/flutter/generated_plugins.cmake" 2>/dev/null; then
    sed -i '/firebase_core/d' "$APP/linux/flutter/generated_plugins.cmake"
    echo "[strip_firebase] Linux: removed firebase_core from generated_plugins.cmake"
  else
    echo "[strip_firebase] Linux: already clean"
  fi
fi

echo "[strip_firebase] Done."
