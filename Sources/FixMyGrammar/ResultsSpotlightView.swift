import AppKit
import SwiftUI

struct ResultsSpotlightContainer: View {
    let result: GrammarRunResult
    var onDismiss: () -> Void
    @EnvironmentObject private var appModel: AppModel
    @State private var cardReady = false

    var body: some View {
        ZStack {
            // Scrim: Raycast/Spotlight-style dim. Tap to dismiss.
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: dismiss)

            // Centered card, sized to content (capped inside ResultsSheet for long text).
            VStack {
                Spacer(minLength: 20)
                ResultsSheet(result: result, onDismiss: dismiss)
                    .environmentObject(appModel)
                    .frame(
                        minWidth: 280,
                        idealWidth: 360,
                        maxWidth: min(440, (NSScreen.main?.visibleFrame.width ?? 1000) - 48)
                    )
                    .frame(
                        maxHeight: min(640, (NSScreen.main?.visibleFrame.height ?? 800) * 0.78)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.background)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.quaternary.opacity(0.9), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 22, y: 12)
                    .scaleEffect(cardReady ? 1 : 0.92)
                    .opacity(cardReady ? 1 : 0)
                    .offset(y: cardReady ? 0 : 10)
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                cardReady = true
            }
        }
    }

    private func dismiss() {
        onDismiss()
    }
}
