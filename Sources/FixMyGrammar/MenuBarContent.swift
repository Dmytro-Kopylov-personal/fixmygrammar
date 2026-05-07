import AppKit
import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        if appModel.isChecking {
            HStack(alignment: .center, spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Checking with LM Studio…")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .disabled(true)
        }

        Button("Check grammar") {
            appModel.runCheckFromUI()
        }
        .disabled(appModel.isChecking)

        Text("Shortcut: \(appModel.hotkeyCombo.description)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)

        if let err = appModel.lastError {
            Button("Show last error…") {
                ErrorPresenter.showBlocking(message: err)
            }
        }

        Divider()

        SettingsLink {
            Text("Settings…")
        }

        Button("Open Accessibility Privacy…") {
            TextCapture.promptAccessibilityIfNeeded()
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }

        Button("Quit FixMyGrammar") {
            NSApplication.shared.terminate(nil)
        }
    }
}
