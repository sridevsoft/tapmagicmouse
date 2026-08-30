#!/bin/bash
set -euo pipefail

NAME="TapMouse"
APP="build/$NAME.app"
SRC=(Settings.swift ClickSynthesizer.swift TapEngine.swift TouchSource.swift AppDelegate.swift main.swift)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

for arch in arm64 x86_64; do
    echo "Compiling $arch..."
    swiftc -O -o "build/${NAME}_$arch" \
        -target "$arch-apple-macos11.0" \
        -import-objc-header MultitouchBridge.h \
        -framework Cocoa -framework ApplicationServices \
        -F /System/Library/PrivateFrameworks -framework MultitouchSupport \
        -Xlinker -rpath -Xlinker /System/Library/PrivateFrameworks \
        "${SRC[@]}"
done

lipo -create "build/${NAME}_arm64" "build/${NAME}_x86_64" -output "$APP/Contents/MacOS/$NAME"
rm -f "build/${NAME}_arm64" "build/${NAME}_x86_64"
cp Info.plist "$APP/Contents/"

codesign --force --sign - "$APP"
echo "Built $APP"
