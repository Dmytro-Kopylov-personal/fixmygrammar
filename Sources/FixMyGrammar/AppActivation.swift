import AppKit

enum AppActivation {
    /// Brings the app forward and orders visible windows (e.g. results overlay). Keeps `.accessory` so the Dock stays hidden.
    static func bringAppToForeground() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows where window.isVisible {
                window.orderFrontRegardless()
            }
            NSApp.keyWindow?.makeKeyAndOrderFront(nil)
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.keyWindow?.makeKeyAndOrderFront(nil)
            }
        }
    }

    /// When a check finishes while another app is focused, gently bounce the Dock icon (no modal).
    static func requestDockAttentionIfInactive() {
        guard !NSApp.isActive else { return }
        NSApp.requestUserAttention(.informationalRequest)
    }
}
