#!/usr/bin/env bash
# Prints true/false. Run from the repository root after fetching all tags.
set -euo pipefail
base=$(git describe --tags --match 'runner-image/v*' --abbrev=0 HEAD 2>/dev/null || true)
if [ -z "$base" ]; then
  # Bootstrap once: older releases have no reliable image-publication marker.
  echo true
  exit 0
fi
if git diff --quiet "$base" HEAD -- \
  packages/runner packages/shared Dockerfile .dockerignore \
  .github/workflows/ci.yml .github/workflows/runner-image.yml \
  scripts/runner-image-changed.sh; then
  echo false
else
  status=$?
  if [ "$status" -ne 1 ]; then exit "$status"; fi
  echo true
fi
