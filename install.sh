#!/bin/bash

set -e

APP_NAME="MDViewer"
APP_PATH="/Applications/${APP_NAME}.app"
BUNDLE_ID="com.danielgabbay.MDViewer"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP_PATH="${SCRIPT_DIR}/${APP_NAME}.app"

uninstall_mdviewer() {
    local force_mode="$1"
    local confirm
    local plist
    local app_support
    local saved_state

    echo "  MDViewer Uninstaller"
    echo "  ===================="
    echo ""
    echo "  This will remove:"
    echo "    - ${APP_PATH}"
    echo "    - Accessibility permission"
    echo "    - All app preferences (UserDefaults)"
    echo "    - Login item (if registered)"
    echo ""

    if [ "${force_mode}" != "--force" ]; then
        read -r -p "Continue? (y/N) " confirm
        if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
            echo "  Cancelled."
            return 0
        fi
    fi

    echo ""

    # 1) Quit the app if running.
    if pgrep -x "${APP_NAME}" > /dev/null 2>&1; then
        echo "  -> Quitting ${APP_NAME}..."
        osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || killall "${APP_NAME}" 2>/dev/null || true
        sleep 1
    fi

    # 2) Remove the app bundle.
    if [ -d "${APP_PATH}" ]; then
        echo "  -> Removing ${APP_PATH}..."
        rm -rf "${APP_PATH}"
    else
        echo "    (App not found in /Applications, skipping)"
    fi

    # 3) Reset Accessibility permission in TCC.
    echo "  -> Resetting Accessibility permission..."
    tccutil reset Accessibility "${BUNDLE_ID}" 2>/dev/null && echo "    Done." || echo "    (Nothing to reset or permission denied)"

    # 4) Remove UserDefaults / preferences plist.
    plist="${HOME}/Library/Preferences/${BUNDLE_ID}.plist"
    if [ -f "${plist}" ]; then
        echo "  -> Removing preferences plist..."
        rm -f "${plist}"
    else
        echo "    (No preferences plist found)"
    fi
    defaults delete "${BUNDLE_ID}" 2>/dev/null || true

    # 5) Remove app support data (if any).
    app_support="${HOME}/Library/Application Support/${BUNDLE_ID}"
    if [ -d "${app_support}" ]; then
        echo "  -> Removing Application Support data..."
        rm -rf "${app_support}"
    fi

    # 6) Remove saved application state.
    saved_state="${HOME}/Library/Saved Application State/${BUNDLE_ID}.savedState"
    if [ -d "${saved_state}" ]; then
        echo "  -> Removing saved application state..."
        rm -rf "${saved_state}"
    fi

    # 7) Remove login item.
    osascript <<'EOF' 2>/dev/null || true
tell application "System Events"
    set loginItems to every login item whose name is "MDViewer"
    repeat with item in loginItems
        delete item
    end repeat
end tell
EOF
    # System Events may fail without Automation permission; this is intentionally non-fatal.
    echo "  -> Removed login item (if registered)."

    echo ""
    echo "  ✓ MDViewer has been fully uninstalled."
}

echo ""
echo "  MDViewer Installer"
echo "  ────────────────────────────────"
echo ""

# Validate installer payload first so we do not uninstall an existing app and then fail to reinstall.
if [ ! -d "${SOURCE_APP_PATH}" ]; then
    echo "  Error: ${APP_NAME}.app not found next to this script."
    echo "  Expected at: ${SOURCE_APP_PATH}"
    echo "  Please place MDViewer.app in the same folder as install.sh."
    exit 1
fi

# if the app is already installed, run built-in uninstall logic first
if [ -d "${APP_PATH}" ]; then
    echo "  Found existing installation. Running built-in uninstall first..."
    uninstall_mdviewer --force
    echo ""
fi
# wait a moment to ensure the old app is fully removed before copying the new one
sleep 1

# Copy app to /Applications if it exists next to the script
echo "  Installing ${APP_NAME}.app to /Applications..."
cp -R "${SOURCE_APP_PATH}" "/Applications/"
echo "  Done."

# Remove quarantine flag (Gatekeeper bypass for unsigned apps)
echo "  Removing macOS quarantine flag..."
xattr -cr "${APP_PATH}"
echo "  Done."

echo ""
echo "  MDViewer is ready to launch."
echo "  Open /Applications and double-click MDViewer."
echo ""
