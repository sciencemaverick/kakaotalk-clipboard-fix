import Cocoa
import ApplicationServices
import CoreGraphics

private let marker: Int64 = 0x55434147454E54 // "UCAGENT"

final class UniversalClipboardAgent {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            fputs("Accessibility permission is required.\n", stderr)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                )
            }
            return
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let agent = Unmanaged<UniversalClipboardAgent>.fromOpaque(refcon).takeUnretainedValue()
                return agent.handle(type: type, event: event)
            },
            userInfo: refcon
        )

        guard let eventTap else {
            fputs("Could not create keyboard event tap. Check Accessibility/Input Monitoring permission.\n", stderr)
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
            )
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        fputs("UniversalClipboardAgent started.\n", stderr)
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else { return Unmanaged.passUnretained(event) }
        if event.getIntegerValueField(.eventSourceUserData) == marker {
            return Unmanaged.passUnretained(event)
        }

        // Apply the override only while KakaoTalk is the frontmost app.
        // All other applications receive the original key event unchanged.
        guard isKakaoTalkFrontmost() else {
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        guard flags.contains(.maskCommand) else { return Unmanaged.passUnretained(event) }

        // Do not override modified variants such as Cmd-Option-C or Cmd-Control-V.
        let disallowed: CGEventFlags = [.maskControl, .maskAlternate]
        guard flags.intersection(disallowed).isEmpty else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        switch keyCode {
        case 8: // C
            return copySelectedText() ? nil : Unmanaged.passUnretained(event)
        case 7: // X
            return cutSelectedText() ? nil : Unmanaged.passUnretained(event)
        case 9: // V
            return pastePlainText() ? nil : Unmanaged.passUnretained(event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func isKakaoTalkFrontmost() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }

        let name = (app.localizedName ?? "").lowercased()
        let bundleID = (app.bundleIdentifier ?? "").lowercased()
        let bundleName = (app.bundleURL?.deletingPathExtension().lastPathComponent ?? "").lowercased()

        // Name matching avoids depending on a single KakaoTalk distribution-specific bundle ID.
        return name == "kakaotalk"
            || name == "카카오톡"
            || bundleName == "kakaotalk"
            || bundleName == "카카오톡"
            || bundleID.contains("kakao") && bundleID.contains("talk")
    }

    private func focusedElement() -> AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            system,
            kAXFocusedUIElementAttribute as CFString,
            &value
        )
        guard result == .success, let value else { return nil }
        return (value as! AXUIElement)
    }

    private func selectedText(from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &value
        )
        guard result == .success, let text = value as? String, !text.isEmpty else {
            return nil
        }
        return text
    }

    private func isSettable(_ attribute: CFString, on element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, attribute, &settable) == .success
            && settable.boolValue
    }

    private func copySelectedText() -> Bool {
        guard let element = focusedElement(),
              let text = selectedText(from: element) else {
            return false
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    private func cutSelectedText() -> Bool {
        guard let element = focusedElement(),
              let text = selectedText(from: element),
              isSettable(kAXSelectedTextAttribute as CFString, on: element) else {
            return false
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else { return false }

        let result = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            "" as CFTypeRef
        )
        return result == .success
    }

    private func pastePlainText() -> Bool {
        guard let text = NSPasteboard.general.string(forType: .string),
              let element = focusedElement(),
              isSettable(kAXSelectedTextAttribute as CFString, on: element) else {
            return false
        }

        let result = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )
        return result == .success
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let agent = UniversalClipboardAgent()
agent.start()

signal(SIGTERM) { _ in
    CFRunLoopStop(CFRunLoopGetMain())
}
signal(SIGINT) { _ in
    CFRunLoopStop(CFRunLoopGetMain())
}

RunLoop.main.run()
