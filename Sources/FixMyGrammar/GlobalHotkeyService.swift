import AppKit
import HotKey

@MainActor
final class GlobalHotkeyService {
    private var hotKey: HotKey?

    func rebind(combo: KeyCombo, onKeyUp: @escaping @MainActor () -> Void) {
        hotKey = nil
        hotKey = HotKey(keyCombo: combo, keyDownHandler: nil, keyUpHandler: {
            Task { @MainActor in
                onKeyUp()
            }
        })
    }
}
