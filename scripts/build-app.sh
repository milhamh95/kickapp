#!/bin/bash
set -euo pipefail

APP_NAME="KickApp"
BUNDLE_ID="com.kickapp.KickApp"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="build/${APP_NAME}.app"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="${LAUNCH_AGENT_DIR}/${BUNDLE_ID}.plist"

echo "==> Building ${APP_NAME} (release)..."
swift build -c release

echo "==> Assembling ${APP_NAME}.app bundle..."
rm -rf "build"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Generate Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# Generate AppIcon.icns from source PNG
SOURCE_ICON="KickApp/Resources/AppIcon.png"
if [ -f "${SOURCE_ICON}" ]; then
    echo "==> Generating AppIcon.icns..."
    ICONSET_DIR="build/AppIcon.iconset"
    mkdir -p "${ICONSET_DIR}"

    sips -z 16 16     "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_16x16.png"      > /dev/null
    sips -z 32 32     "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_16x16@2x.png"   > /dev/null
    sips -z 32 32     "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_32x32.png"      > /dev/null
    sips -z 64 64     "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_32x32@2x.png"   > /dev/null
    sips -z 128 128   "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_128x128.png"    > /dev/null
    sips -z 256 256   "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_256x256.png"    > /dev/null
    sips -z 512 512   "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_512x512.png"    > /dev/null
    sips -z 1024 1024 "${SOURCE_ICON}" --out "${ICONSET_DIR}/icon_512x512@2x.png" > /dev/null

    iconutil -c icns "${ICONSET_DIR}" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    rm -rf "${ICONSET_DIR}"
    echo "    AppIcon.icns generated."
else
    echo "    WARNING: ${SOURCE_ICON} not found, skipping icon generation."
fi

# Copy menu bar icon
if [ -f "KickApp/Resources/MenuBarIcon.png" ]; then
    cp KickApp/Resources/MenuBarIcon.png "${APP_BUNDLE}/Contents/Resources/MenuBarIcon.png"
    cp KickApp/Resources/MenuBarIcon@2x.png "${APP_BUNDLE}/Contents/Resources/MenuBarIcon@2x.png"
    echo "    Menu bar icon copied."
fi

# Generate PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo "==> Done! App bundle created at: $(pwd)/${APP_BUNDLE}"
echo ""
echo "To install:"
echo "  cp -r ${APP_BUNDLE} /Applications/"
echo ""
echo "To enable launch at login:"
echo "  bash scripts/install-launchagent.sh"
echo ""
echo "To run directly:"
echo "  open ${APP_BUNDLE}"
