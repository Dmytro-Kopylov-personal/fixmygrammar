import AppKit
import ApplicationServices

enum TextCaptureOrder: String, CaseIterable, Identifiable {
    case selectionThenClipboard
    case clipboardThenSelection
    case clipboardOnly
    case selectionOnly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .selectionThenClipboard:
            return "Selection, then clipboard"
        case .clipboardThenSelection:
            return "Clipboard, then selection"
        case .clipboardOnly:
            return "Clipboard only"
        case .selectionOnly:
            return "Selection only"
        }
    }

    fileprivate var usesClipboard: Bool {
        switch self {
        case .clipboardOnly, .selectionThenClipboard, .clipboardThenSelection:
            return true
        case .selectionOnly:
            return false
        }
    }

    fileprivate var usesSelection: Bool {
        switch self {
        case .selectionOnly, .selectionThenClipboard, .clipboardThenSelection:
            return true
        case .clipboardOnly:
            return false
        }
    }
}

enum TextCapture {
    static func capture(order: TextCaptureOrder) -> String? {
        captureWithDiagnostics(order: order).text
    }

    /// Plain text and, if missing, a specific reason (Accessibility, empty clipboard, unsupported host app, etc.).
    static func captureWithDiagnostics(order: TextCaptureOrder) -> (text: String?, diagnostics: String?) {
        let clip = clipboardPlainText()
        let sel = selectionPlainText()

        let text: String?
        switch order {
        case .selectionThenClipboard:
            text = firstNonEmpty(sel, clip)
        case .clipboardThenSelection:
            text = firstNonEmpty(clip, sel)
        case .clipboardOnly:
            text = clip
        case .selectionOnly:
            text = sel
        }

        if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (text, nil)
        }

        return (nil, buildDiagnostics(order: order, clip: clip, sel: sel))
    }

    private static func firstNonEmpty(_ parts: String?...) -> String? {
        for p in parts {
            if let p, !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return p
            }
        }
        return nil
    }

    private static func clipboardPlainText() -> String? {
        let pb = NSPasteboard.general
        let types: [NSPasteboard.PasteboardType] = [
            .string,
            NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text"),
            NSPasteboard.PasteboardType(rawValue: "public.plain-text"),
        ]
        for t in types {
            if let s = pb.string(forType: t) {
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return s }
            }
        }
        return nil
    }

    /// Selected text from the focused accessibility element and a short walk up ancestors (many hosts expose selection on a parent).
    private static func selectionPlainText() -> String? {
        promptAccessibilityIfNeeded()

        guard AXIsProcessTrusted() else {
            return nil
        }

        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focusedRef = focused
        else {
            return nil
        }

        let start = focusedRef as! AXUIElement
        return selectedTextWalkingAncestors(from: start, maxDepth: 20)
    }

    private static func selectedTextWalkingAncestors(from start: AXUIElement, maxDepth: Int) -> String? {
        var element: AXUIElement? = start
        var depth = 0
        while let el = element, depth < maxDepth {
            if let t = selectedText(on: el), !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return t
            }
            var parentRef: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(el, kAXParentAttribute as CFString, &parentRef)
            guard err == .success, let parent = parentRef else { break }
            element = (parent as! AXUIElement)
            depth += 1
        }
        return nil
    }

    private static func selectedText(on element: AXUIElement) -> String? {
        if let text = copyStringAttribute(element, kAXSelectedTextAttribute as CFString) {
            return text
        }

        guard let rangeValue = copyAXValue(element, kAXSelectedTextRangeAttribute as CFString),
              let fullText = copyStringAttribute(element, kAXValueAttribute as CFString)
        else {
            return nil
        }

        var cfRange = CFRange()
        guard AXValueGetValue(rangeValue, .cfRange, &cfRange) else {
            return nil
        }

        let nsRange = NSRange(location: cfRange.location, length: cfRange.length)
        guard nsRange.location != NSNotFound, nsRange.length > 0,
              let swiftRange = Range(nsRange, in: fullText)
        else {
            return nil
        }

        return String(fullText[swiftRange])
    }

    private static func copyStringAttribute(_ element: AXUIElement, _ attribute: CFString) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private static func copyAXValue(_ element: AXUIElement, _ attribute: CFString) -> AXValue? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return (value as! AXValue)
    }

    private static func buildDiagnostics(order: TextCaptureOrder, clip: String?, sel: String?) -> String {
        var parts: [String] = []

        if order.usesSelection {
            if !AXIsProcessTrusted() {
                parts.append(
                    """
                    Accessibility is not enabled for FixMyGrammar (or you have not approved it yet).

                    Open System Settings → Privacy & Security → Accessibility, enable FixMyGrammar, then try again. FixMyGrammar’s Settings has buttons that open this pane.
                    """
                )
            } else if sel == nil || sel!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append(
                    """
                    No readable text selection was found in the focused app.

                    Highlight text in your editor, then run the check again while that app stays focused. If “Bring FixMyGrammar to the front when results or errors appear” is on, an error can still move focus here—turn it off while debugging capture, or use Clipboard first / Clipboard only and copy your text (⌘C) before checking.

                    Some apps (parts of Chrome, Slack, Electron) expose little or no selection to Accessibility—in that case turn off “Check only selected text” and use “Clipboard only”, then copy your text before checking.
                    """
                )
            }
        }

        if order.usesClipboard {
            if clip == nil || clip!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append(
                    """
                    The clipboard has no plain text.

                    Copy your passage (⌘C), then run the check again—or change capture order in Settings to use selection first.
                    """
                )
            }
        }

        if parts.isEmpty {
            parts.append("No text was captured. Adjust capture settings or copy/select your text and retry.")
        }

        return parts.joined(separator: "\n\n")
    }

    static func promptAccessibilityIfNeeded() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: NSDictionary = [promptKey: true]
        AXIsProcessTrustedWithOptions(options)
    }
}
