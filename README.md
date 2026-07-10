# KakaoTalk Clipboard Fix for macOS

최근 macOS용 카카오톡에서 **Copy, Paste, Cut 메뉴가 비활성화되면서 `⌘C`, `⌘V`, `⌘X`까지 함께 작동하지 않는 문제**를 계속 마주쳐 만든 간단한 우회 도구입니다.

마우스로 PopClip을 누르면 복사와 붙여넣기가 잘 되는데 키보드 단축키만 묵묵부답인 상황이 반복됐습니다. 카카오톡이 고쳐질 때까지 기다리기에는 `⌘C`를 누른 횟수가 너무 많아서, macOS Accessibility API로 선택 텍스트를 직접 읽고 쓰는 작은 LaunchAgent를 만들었습니다.

카카오톡이 전면 앱일 때만 동작하며, 다른 앱의 단축키에는 관여하지 않습니다. 메뉴바 아이콘, Dock 아이콘 및 설정 창도 없습니다.

## What it does

- `⌘C`: 선택된 텍스트를 macOS 클립보드에 직접 복사
- `⌘X`: 선택된 텍스트를 복사한 뒤 선택 영역 삭제
- `⌘V`: 클립보드의 일반 텍스트를 현재 입력 위치에 삽입
- Accessibility 방식으로 처리할 수 없는 경우 카카오톡의 원래 단축키로 통과
- 로그인 시 LaunchAgent로 자동 실행

## Installation

1. 이 저장소를 다운로드하거나 clone합니다.
2. `Install.command`를 더블클릭합니다.
3. macOS가 실행을 막으면 Finder에서 파일을 우클릭하고 **열기**를 선택합니다.
4. Apple Command Line Tools 설치 요청이 나오면 설치를 마친 뒤 `Install.command`를 다시 실행합니다.
5. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 `KakaoTalk Clipboard Fix`를 허용합니다.
6. 필요하면 **입력 모니터링**에서도 같은 항목을 허용합니다.
7. 설치 창으로 돌아가 Enter를 눌러 에이전트를 재시작합니다.

설치 후에는 별도 앱을 열 필요가 없습니다.

## Uninstallation

`Uninstall.command`를 더블클릭합니다.

시스템 설정의 손쉬운 사용 또는 입력 모니터링 목록에 항목이 남아 있으면 `-` 버튼으로 직접 제거할 수 있습니다.

## How it works

`CGEventTap`으로 전역 키 입력을 감시하되, 현재 전면 앱이 카카오톡일 때만 `⌘C`, `⌘X`, `⌘V`를 처리합니다. 선택 텍스트와 현재 입력 영역은 macOS Accessibility API의 `AXSelectedText`를 통해 읽거나 수정하고, 클립보드는 `NSPasteboard`를 사용합니다.

실행 파일은 설치 시 로컬에서 Swift로 컴파일되며, 사용자 계정의 다음 위치에 설치됩니다.

```text
~/Library/Application Support/KakaoTalkClipboardFix/
~/Library/LaunchAgents/local.kakaotalk-clipboard-fix.plist
```

## Limitations

- 일반 텍스트용 우회 도구입니다. 이미지, 파일, 이모티콘 및 서식 있는 콘텐츠는 보장하지 않습니다.
- 카카오톡의 특정 화면이 `AXSelectedText`를 제공하지 않으면 원래 단축키 동작으로 통과합니다.
- 비밀번호와 Secure Input 영역에는 접근하지 않습니다.
- macOS 업데이트나 카카오톡 내부 UI 변경으로 동작이 달라질 수 있습니다.

## Files

```text
Install.command
Uninstall.command
KakaoTalkClipboardFix.swift
README.md
```

## Disclaimer

카카오 또는 KakaoTalk과 관련 없는 비공식 개인 유틸리티입니다. 코드는 짧으니 설치 전에 직접 읽어보는 것을 권장합니다. 클립보드를 고치려다 신뢰까지 복사해 오지는 않습니다.

## License

[MIT License](LICENSE)
