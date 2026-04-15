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

        Divider()

        SettingsLink {
            Text("Settings…")
        }

        Button("Quit FixMyGrammar") {
            NSApplication.shared.terminate(nil)
        }
    }
}
