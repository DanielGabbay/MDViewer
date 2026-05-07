#!/bin/bash

set -e

APP_NAME="MDViewer"
APP_PATH="/Applications/${APP_NAME}.app"
BUNDLE_ID="com.danielgabbay.MDViewer"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  MDViewer Installer"
echo "  ────────────────────────────────"
echo ""

# Remove existing installation if present
if [ -d "${APP_PATH}" ]; then
    echo "  Found existing installation — cleaning up..."
    # Quit the app if running
    if pgrep -x "MDViewer" > /dev/null 2>&1; then
        echo "  Stopping MDViewer..."
        osascript -e 'tell application "MDViewer" to quit' 2>/dev/null || killall MDViewer 2>/dev/null || true
        sleep 1
    fi
    rm -rf "${APP_PATH}"
    echo "  Old version removed."
    echo ""
fi

# Copy app to /Applications if it exists next to the script
if [ -d "${SCRIPT_DIR}/${APP_NAME}.app" ]; then
    echo "  Installing ${APP_NAME}.app to /Applications..."
    cp -R "${SCRIPT_DIR}/${APP_NAME}.app" "/Applications/"
    echo "  Done."
else
    echo "  Error: ${APP_NAME}.app not found next to this script."
    echo "  Please place MDViewer.app in the same folder as install.sh."
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
