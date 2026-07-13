#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
OUTPUT_ROOT="${OUTPUT_ROOT:-$ROOT/dist}"
APP="$OUTPUT_ROOT/Rest Reminder.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

mkdir -p "$ROOT/.module-cache"

clang \
  -fobjc-arc \
  -fmodules-cache-path="$ROOT/.module-cache" \
  -mmacosx-version-min=13.0 \
  -arch arm64 \
  -arch x86_64 \
  -framework Cocoa \
  -framework UserNotifications \
  "$ROOT/main.m" \
  -o "$APP/Contents/MacOS/RestReminder"

cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - --timestamp=none "$APP"

echo "$APP"
