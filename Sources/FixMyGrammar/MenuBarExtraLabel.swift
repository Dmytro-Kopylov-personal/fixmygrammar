import SwiftUI

/// Menu bar icon + subtle motion while a grammar check is in flight.
struct MenuBarExtraLabel: View {
    let isChecking: Bool
    @State private var pulse = false

    var body: some View {
        Group {
            if isChecking {
                HStack(spacing: 5) {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.85)
                    Image(systemName: "text.badge.checkmark")
                        .symbolRenderingMode(.hierarchical)
                        .opacity(pulse ? 0.45 : 1)
                }
                .accessibilityLabel("FixMyGrammar, checking grammar")
                .onAppear {
                    pulse = false
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
            } else {
                Image(systemName: "text.badge.checkmark")
                    .accessibilityLabel("FixMyGrammar")
            }
        }
        .onChange(of: isChecking) { _, new in
            if !new { pulse = false }
        }
    }
}
