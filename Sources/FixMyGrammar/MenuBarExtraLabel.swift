import AppKit
import SwiftUI

/// Menu bar item: SF Symbol when idle, AppKit spinner when checking (SwiftUI `ProgressView` often draws blank here).
struct MenuBarExtraLabel: View {
    let isChecking: Bool

    var body: some View {
        Group {
            if isChecking {
                MenuBarSpinningIndicator()
                    .frame(width: 18, height: 18)
                    .accessibilityLabel("FixMyGrammar, checking grammar")
            } else {
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 13, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
                    .accessibilityLabel("FixMyGrammar")
            }
        }
    }
}

private struct MenuBarSpinningIndicator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.isIndeterminate = true
        indicator.isDisplayedWhenStopped = false
        indicator.appearance = NSAppearance.currentDrawing()
        return indicator
    }

    func updateNSView(_ indicator: NSProgressIndicator, context: Context) {
        indicator.appearance = NSAppearance.currentDrawing()
        indicator.startAnimation(nil)
    }

    static func dismantleNSView(_ indicator: NSProgressIndicator, coordinator: ()) {
        indicator.stopAnimation(nil)
    }
}
