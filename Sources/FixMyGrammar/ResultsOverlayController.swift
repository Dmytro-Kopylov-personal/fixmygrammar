import AppKit
import SwiftUI

/// Full-screen, Spotlight-style host for results (borderless, floating above other app windows in this process).
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
            let w = makeWindow()
            window = w
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
        let frame = screen.frame
        let w = NSWindow(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.isMovable = false
        w.isMovableByWindowBackground = false
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.ignoresMouseEvents = false
        w.hidesOnDeactivate = false
        w.setFrame(frame, display: false)
        return w
    }

    private func installEscapeMonitor() {
        if escapeMonitor != nil { return }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let w = self.window, w.isVisible, event.keyCode == 53 else { return event }
            // Escape: mirror scrim / Done
            if let m = self.lastModel {
                m.activeResult = nil
            }
            return nil
        }
    }
}
