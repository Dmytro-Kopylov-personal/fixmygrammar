import AppKit
import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FixMyGrammar")
                .font(.title2.weight(.semibold))

            if appModel.isChecking {
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Working on your request")
                            .font(.subheadline.weight(.semibold))
                        Text("Waiting for LM Studio…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.blue.opacity(0.22), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Copy the passage with ⌘C (not the model id), then press your shortcut or Check now. Accessibility selection works in some native editors only—in browsers and Slack, use the clipboard.")
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
    }
}
