#!/bin/zsh
set -euo pipefail

LABEL="local.kakaotalk-clipboard-fix"
BASE="$HOME/Library/Application Support/KakaoTalkClipboardFix"
APP="$BASE/KakaoTalkClipboardFix.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SCRIPT_DIR="${0:A:h}"

mkdir -p "$MACOS" "$HOME/Library/LaunchAgents"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "Apple Command Line Tools가 필요합니다."
  xcode-select --install || true
  echo "설치가 끝난 뒤 이 파일을 다시 실행하세요."
  read "?Enter를 누르면 종료합니다."
  exit 1
fi

echo "Swift 실행 파일을 컴파일합니다..."
xcrun swiftc \
  -O \
  -framework Cocoa \
  -framework ApplicationServices \
  -framework CoreGraphics \
  "$SCRIPT_DIR/KakaoTalkClipboardFix.swift" \
  -o "$MACOS/KakaoTalkClipboardFix"

cat > "$CONTENTS/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>local.kakaotalk-clipboard-fix</string>
  <key>CFBundleName</key>
  <string>KakaoTalk Clipboard Fix</string>
  <key>CFBundleDisplayName</key>
  <string>KakaoTalk Clipboard Fix</string>
  <key>CFBundleExecutable</key>
  <string>KakaoTalkClipboardFix</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Local utility</string>
</dict>
</plist>
EOF

# Stable local identity for macOS privacy permissions.
codesign --force --deep --sign - "$APP"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$MACOS/KakaoTalkClipboardFix</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ProcessType</key>
  <string>Interactive</string>
  <key>StandardOutPath</key>
  <string>$BASE/stdout.log</string>
  <key>StandardErrorPath</key>
  <string>$BASE/stderr.log</string>
</dict>
</plist>
EOF

chmod 644 "$PLIST"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo
echo "설치 및 ON 완료."
echo "잠시 뒤 권한 요청이 나타나면 허용하세요."
echo
echo "필수 설정:"
echo "시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용"
echo "KakaoTalk Clipboard Fix를 켭니다."
echo
echo "키 입력 감지가 안 되면:"
echo "시스템 설정 > 개인정보 보호 및 보안 > 입력 모니터링"
echo "KakaoTalk Clipboard Fix를 추가하거나 켭니다."
echo
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
read "?권한을 켠 뒤 Enter를 누르면 에이전트를 재시작합니다."
launchctl kickstart -k "gui/$(id -u)/$LABEL" || true
echo "완료. 이 창을 닫아도 됩니다."
