import AppKit

enum ErrorPresenter {
    /// Blocking alert — re‑activates the app so the dialog is visible in menu‑bar‑only mode.
    @MainActor
    static func showBlocking(message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "FixMyGrammar"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
