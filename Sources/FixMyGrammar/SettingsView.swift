import AppKit
import HotKey
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    private var hotkeyBinding: Binding<KeyCombo> {
        Binding(
            get: { appModel.hotkeyCombo },
            set: { appModel.setHotkeyCombo($0) }
        )
    }

    private var selectedTextOnlyBinding: Binding<Bool> {
        Binding(
            get: { appModel.useSelectedTextOnly },
            set: { appModel.useSelectedTextOnly = $0 }
        )
    }

    var body: some View {
        Form {
            Section("LM Studio") {
                TextField("Base URL (e.g. http://127.0.0.1:1234)", text: $appModel.lmBaseURL)
                    .textFieldStyle(.roundedBorder)
                TextField("Model id (loaded in LM Studio)", text: $appModel.model)
                    .textFieldStyle(.roundedBorder)
                Text("Use this field only for the LM Studio model name. The text you want proofread must come from selection or the clipboard—not from here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("API key (optional)", text: $appModel.apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Model context") {
                Toggle("Query LM Studio for context size (GET /v1/models)", isOn: $appModel.queryServerContextLimit)
                Text("When enabled, the smaller of your setting below and the server value is used (per model id).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Max context (tokens, approx.)") {
                    TextField("", value: $appModel.maxModelContextTokens, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
                LabeledContent("Reserve for reply (tokens, approx.)") {
                    TextField("", value: $appModel.replyReserveTokens, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
                Text("Long captures are shortened by keeping the beginning only, so the system prompt, your text, and the model reply fit. Raise max context for large models (e.g. 32768, 131072).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Capture") {
                Toggle("Check only selected text (ignore clipboard)", isOn: selectedTextOnlyBinding)
                Text("Uses Accessibility in the focused app. Grant access in Privacy → Accessibility. Clipboard is never read while this is on.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !appModel.useSelectedTextOnly {
                    Picker("Otherwise, prefer", selection: $appModel.captureOrder) {
                        ForEach(TextCaptureOrder.allCases.filter { $0 != .selectionOnly }) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                    Text("Selection uses the focused app’s selection; clipboard reads the pasteboard without simulating copy.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Results") {
                Toggle("Bring FixMyGrammar to the front when results or errors appear", isOn: $appModel.bringResultsToFront)
                Text("Useful after a global shortcut while you are still in another app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Show full report (issues list, raw output, copy full report)", isOn: $appModel.showFullReportInResults)
                Text("When off, the results sheet focuses on your original text and the corrected version only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Shortcut") {
                HotkeyRecorderView(combo: hotkeyBinding)
                Text("Record a shortcut while this window is focused. It works globally once saved. Include at least one modifier key.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                Button("Request Accessibility access…") {
                    TextCapture.promptAccessibilityIfNeeded()
                }
                Button("Open Accessibility privacy settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Text(
                    """
                    If you run from Terminal (swift run), macOS may not show a normal app entry. Build a real app bundle from the repo: run scripts/bundle_mac_app.sh, then open dist/FixMyGrammar.app once and add that app under Accessibility (use + if needed).
                    """
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 720)
    }
}
