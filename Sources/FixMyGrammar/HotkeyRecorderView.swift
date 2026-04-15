import AppKit
import HotKey
import SwiftUI

/// Captures the next keyDown while this app is focused (use in Settings).
struct HotkeyRecorderView: View {
    @Binding var combo: KeyCombo
    @State private var recording = false
    @State private var localMonitor: Any?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(combo.description.isEmpty ? "—" : combo.description)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))

            Button(recording ? "Cancel" : "Record…") {
                if recording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        recording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                Task { @MainActor in
                    stopRecording()
                }
                return nil
            }

            let mods = event.modifierFlags.carbonFlags
            if mods == 0 {
                NSSound.beep()
                return nil
            }

            let newCombo = KeyCombo(carbonKeyCode: UInt32(event.keyCode), carbonModifiers: mods)
            Task { @MainActor in
                combo = newCombo
                stopRecording()
            }
            return nil
        }
    }

    private func stopRecording() {
        recording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        localMonitor = nil
    }
}
