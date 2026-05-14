#!/bin/bash
set -euo pipefail

BUNDLE_ID="com.kickapp.KickApp"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/${BUNDLE_ID}.plist"

if [ -f "${LAUNCH_AGENT_PLIST}" ]; then
    echo "==> Unloading LaunchAgent..."
    launchctl unload "${LAUNCH_AGENT_PLIST}" 2>/dev/null || true
    rm "${LAUNCH_AGENT_PLIST}"
    echo "==> Done! KickApp will no longer launch at login."
else
    echo "LaunchAgent not installed."
fi
