import SwiftUI

/// Menu bar icon; while a check runs, shows an inline spinner in the same slot (no separate popup).
struct MenuBarExtraLabel: View {
    let isChecking: Bool
    /// Keeps menu bar width stable between idle and busy so neighbors don’t shift.
    private let slotWidth: CGFloat = 22

    var body: some View {
        Group {
            if isChecking {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.92)
                    .frame(width: slotWidth, height: slotWidth)
                    .accessibilityLabel("FixMyGrammar, checking grammar")
            } else {
                Image(systemName: "text.badge.checkmark")
                    .frame(width: slotWidth, height: slotWidth)
                    .accessibilityLabel("FixMyGrammar")
            }
        }
    }
}
