#!/bin/bash

set -e

APP_NAME="MDViewer"
APP_PATH="/Applications/${APP_NAME}.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  MDViewer Installer"
echo "  ────────────────────────────────"
echo ""

# Copy app to /Applications if it exists next to the script
if [ -d "${SCRIPT_DIR}/${APP_NAME}.app" ]; then
    echo "  Copying ${APP_NAME}.app to /Applications..."
    cp -R "${SCRIPT_DIR}/${APP_NAME}.app" "/Applications/"
    echo "  Done."
fi

# Check the app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "  Error: ${APP_PATH} not found."
    echo "  Please drag MDViewer.app to /Applications first, then run this script."
    exit 1
fi

# Remove quarantine flag (Gatekeeper bypass for unsigned apps)
echo "  Removing macOS quarantine flag..."
xattr -cr "${APP_PATH}"
echo "  Done."

echo ""
echo "  MDViewer is ready to launch."
echo "  Open /Applications and double-click MDViewer."
echo ""
