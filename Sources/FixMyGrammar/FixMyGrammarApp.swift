import SwiftUI

@main
struct FixMyGrammarApp: App {
    @NSApplicationDelegateAdaptor(FixMyGrammarAppDelegate.self) private var appDelegate
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(appModel)
        } label: {
            MenuBarExtraLabel(isChecking: appModel.isChecking)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(appModel)
        }
    }
}
