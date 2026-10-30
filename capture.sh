#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

: "${CAPTURE_URL:?CAPTURE_URL is required}"
: "${CAPTURE_DIR:?CAPTURE_DIR is required}"

mkdir -p "$CAPTURE_DIR"

# Open the exact URL in a browser, wait for rendered content, capture desktop
# and mobile views as final-desktop.png and final-mobile.png in CAPTURE_DIR,
# then close the browser and leave the app running.
/usr/bin/time -p node "${RUNTIME_DIR:?}/scripts/default-capture.mjs"
