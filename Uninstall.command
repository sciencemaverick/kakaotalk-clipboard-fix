#!/bin/zsh
set -euo pipefail
LABEL="local.kakaotalk-clipboard-fix"
BASE="$HOME/Library/Application Support/KakaoTalkClipboardFix"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$BASE"

echo "제거 완료."
echo "시스템 설정의 손쉬운 사용/입력 모니터링 목록에 항목이 남으면 직접 '-'로 삭제하세요."
sleep 2
