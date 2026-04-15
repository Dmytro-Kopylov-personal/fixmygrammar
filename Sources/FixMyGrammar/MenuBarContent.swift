import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
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
