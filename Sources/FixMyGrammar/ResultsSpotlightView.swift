import AppKit
import SwiftUI

/// Chrome around the results sheet; the window itself is resizable — content fills it.
struct ResultsSpotlightContainer: View {
    let result: GrammarRunResult
    var onDismiss: () -> Void
    @EnvironmentObject private var appModel: AppModel
    @State private var cardReady = false

    var body: some View {
        ResultsSheet(result: result, onDismiss: dismiss)
            .environmentObject(appModel)
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.background)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.quaternary.opacity(0.9), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.22), radius: 16, y: 8)
            .padding(12)
            .scaleEffect(cardReady ? 1 : 0.96)
            .opacity(cardReady ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                    cardReady = true
                }
            }
    }

    private func dismiss() {
        onDismiss()
    }
}
