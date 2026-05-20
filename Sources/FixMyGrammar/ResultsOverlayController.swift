import AppKit
import SwiftUI

/// Resizable floating panel for results (frame saved via `setFrameAutosaveName`).
@MainActor
final class ResultsOverlayController {
    static let shared = ResultsOverlayController()

    private var window: NSWindow?
    private var escapeMonitor: Any?
    private var hosting: NSHostingView<AnyView>?
    private weak var lastModel: AppModel?

    private init() {}

    func show(result: GrammarRunResult, appModel: AppModel) {
        lastModel = appModel
        if window == nil {
            window = makeWindow()
        }
        guard let w = window else { return }

        let root = AnyView(
            ResultsSpotlightContainer(result: result, onDismiss: { [weak appModel] in
                appModel?.activeResult = nil
            })
            .environmentObject(appModel)
        )

        if let h = hosting {
            h.rootView = root
        } else {
            let h = NSHostingView(rootView: root)
            hosting = h
            w.contentView = h
        }

        installEscapeMonitor()
        w.makeKeyAndOrderFront(nil)
        w.orderFrontRegardless()
    }

    func hide() {
        if let m = escapeMonitor {
            NSEvent.removeMonitor(m)
            escapeMonitor = nil
        }
        window?.orderOut(nil)
    }

    private func makeWindow() -> NSWindow {
        guard let screen = NSApp.keyWindow?.screen ?? NSScreen.main else {
            return NSWindow()
        }
        let vf = screen.visibleFrame
        let defaultW: CGFloat = 480
        let defaultH: CGFloat = 580
        let x = vf.minX + (vf.width - defaultW) / 2
        let y = vf.minY + (vf.height - defaultH) / 2
        let rect = NSRect(x: x, y: y, width: defaultW, height: defaultH)

        let w = NSWindow(
            contentRect: rect,
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = true
        w.isMovable = true
        w.isMovableByWindowBackground = true
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.ignoresMouseEvents = false
        w.hidesOnDeactivate = false
        w.minSize = NSSize(width: 320, height: 380)
        w.maxSize = NSSize(width: vf.width * 0.95, height: vf.height * 0.95)
        // Persists position & size across launches.
        w.setFrameAutosaveName("FixMyGrammarResultsPanel")
        w.setFrame(rect, display: false)
        return w
    }

    private func installEscapeMonitor() {
        if escapeMonitor != nil { return }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let w = self.window, w.isVisible, event.keyCode == 53 else { return event }
            if let m = self.lastModel {
                m.activeResult = nil
            }
            return nil
        }
    }
}
