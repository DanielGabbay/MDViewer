#!/bin/bash
# MDViewer Uninstaller
# Removes the app, preferences, accessibility permissions, and all traces.

BUNDLE_ID="com.danielgabbay.MDViewer"
APP_NAME="MDViewer.app"
APP_PATH="/Applications/$APP_NAME"

echo "MDViewer Uninstaller"
echo "===================="
echo ""
echo "This will remove:"
echo "  • $APP_PATH"
echo "  • Accessibility permission"
echo "  • All app preferences (UserDefaults)"
echo "  • Login item (if registered)"
echo ""
read -p "Continue? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# 1. Quit the app if running
if pgrep -x "MDViewer" > /dev/null 2>&1; then
    echo "→ Quitting MDViewer..."
    osascript -e 'quit app "MDViewer"' 2>/dev/null || killall MDViewer 2>/dev/null
    sleep 1
fi

# 2. Remove the app bundle
if [ -d "$APP_PATH" ]; then
    echo "→ Removing $APP_PATH..."
    rm -rf "$APP_PATH"
else
    echo "  (App not found in /Applications, skipping)"
fi

# 3. Reset Accessibility permission in TCC
echo "→ Resetting Accessibility permission..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null && echo "  Done." || echo "  (Nothing to reset or permission denied)"

# 4. Remove UserDefaults / preferences plist
PLIST="$HOME/Library/Preferences/$BUNDLE_ID.plist"
if [ -f "$PLIST" ]; then
    echo "→ Removing preferences plist..."
    rm -f "$PLIST"
else
    echo "  (No preferences plist found)"
fi

# Also flush any in-memory defaults the system may have cached
defaults delete "$BUNDLE_ID" 2>/dev/null

# 5. Remove app support data (if any)
APP_SUPPORT="$HOME/Library/Application Support/$BUNDLE_ID"
if [ -d "$APP_SUPPORT" ]; then
    echo "→ Removing Application Support data..."
    rm -rf "$APP_SUPPORT"
fi

# 6. Remove saved application state
SAVED_STATE="$HOME/Library/Saved Application State/$BUNDLE_ID.savedState"
if [ -d "$SAVED_STATE" ]; then
    echo "→ Removing saved application state..."
    rm -rf "$SAVED_STATE"
fi

# 7. Remove login item (macOS 13+ SMAppService / older LSSharedFileList)
# Try scripting bridge first (works on all versions)
osascript <<'EOF' 2>/dev/null
tell application "System Events"
    set loginItems to every login item whose name is "MDViewer"
    repeat with item in loginItems
        delete item
    end repeat
end tell
EOF
echo "→ Removed login item (if registered)."

echo ""
echo "✓ MDViewer has been fully uninstalled."
