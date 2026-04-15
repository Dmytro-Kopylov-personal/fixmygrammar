import SwiftUI

@main
struct FixMyGrammarApp: App {
    @NSApplicationDelegateAdaptor(FixMyGrammarAppDelegate.self) private var appDelegate
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appModel)
        }

        Settings {
            SettingsView()
                .environmentObject(appModel)
        }

        MenuBarExtra("FixMyGrammar", systemImage: "text.badge.checkmark") {
            MenuBarContent()
                .environmentObject(appModel)
        }
    }
}
