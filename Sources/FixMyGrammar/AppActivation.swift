import AppKit

enum AppActivation {
    /// Raises this app and its visible windows so sheets and errors are visible after a background hotkey check.
    static func bringAppToForeground() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows where window.isVisible {
                window.orderFrontRegardless()
            }
            NSApp.keyWindow?.makeKeyAndOrderFront(nil)
            // Second pass so a just-presented sheet can become key.
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.keyWindow?.makeKeyAndOrderFront(nil)
            }
        }
    }
}
