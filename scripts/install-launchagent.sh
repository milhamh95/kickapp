#!/bin/bash
set -euo pipefail

BUNDLE_ID="com.kickapp.KickApp"
APP_PATH="/Applications/KickApp.app"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="${LAUNCH_AGENT_DIR}/${BUNDLE_ID}.plist"

if [ ! -d "${APP_PATH}" ]; then
    echo "Error: ${APP_PATH} not found."
    echo "Please install first: cp -r build/KickApp.app /Applications/"
    exit 1
fi

# Unload existing agent if present
if launchctl list | grep -q "${BUNDLE_ID}" 2>/dev/null; then
    echo "==> Unloading existing LaunchAgent..."
    launchctl unload "${LAUNCH_AGENT_PLIST}" 2>/dev/null || true
fi

echo "==> Installing LaunchAgent..."
mkdir -p "${LAUNCH_AGENT_DIR}"

cat > "${LAUNCH_AGENT_PLIST}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${BUNDLE_ID}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_PATH}/Contents/MacOS/KickApp</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
PLIST

echo "==> Loading LaunchAgent..."
launchctl load "${LAUNCH_AGENT_PLIST}"

echo "==> Done! KickApp will now launch at login."
echo ""
echo "To disable:"
echo "  launchctl unload ${LAUNCH_AGENT_PLIST}"
echo "  rm ${LAUNCH_AGENT_PLIST}"
