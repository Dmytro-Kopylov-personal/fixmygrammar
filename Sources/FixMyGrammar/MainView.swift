import AppKit
import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FixMyGrammar")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Select or copy the passage you want checked (not the model id). Then press your shortcut or use Check now.")
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Current shortcut:")
                    Text(appModel.hotkeyCombo.description)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    appModel.runCheckFromUI()
                } label: {
                    if appModel.isChecking {
                        ProgressView()
                            .controlSize(.small)
                            .frame(minWidth: 120)
                    } else {
                        Text("Check now")
                            .frame(minWidth: 120)
                    }
                }
                .disabled(appModel.isChecking)

                Button("Open Accessibility…") {
                    TextCapture.promptAccessibilityIfNeeded()
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            if let error = appModel.lastError {
                Text(error)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 260)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .sheet(item: Binding(
            get: { appModel.activeResult },
            set: { appModel.activeResult = $0 }
        )) { result in
            ResultsSheet(result: result)
                .environmentObject(appModel)
        }
    }
}
