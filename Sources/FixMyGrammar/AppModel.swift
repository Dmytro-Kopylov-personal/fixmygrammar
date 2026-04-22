import AppKit
import Foundation
import HotKey
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var lmBaseURL: String {
        didSet { UserDefaults.standard.set(lmBaseURL, forKey: Keys.lmBaseURL) }
    }

    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Keys.model) }
    }

    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: Keys.apiKey) }
    }

    @Published var captureOrder: TextCaptureOrder {
        didSet { UserDefaults.standard.set(captureOrder.rawValue, forKey: Keys.captureOrder) }
    }

    /// When true, only Accessibility selection is used (same as `captureOrder == .selectionOnly`).
    var useSelectedTextOnly: Bool {
        get { captureOrder == .selectionOnly }
        set {
            if newValue {
                captureOrder = .selectionOnly
            } else if captureOrder == .selectionOnly {
                captureOrder = .clipboardThenSelection
            }
        }
    }

    @Published var bringResultsToFront: Bool {
        didSet { UserDefaults.standard.set(bringResultsToFront, forKey: Keys.bringResultsToFront) }
    }

    @Published var showFullReportInResults: Bool {
        didSet { UserDefaults.standard.set(showFullReportInResults, forKey: Keys.showFullReportInResults) }
    }

    /// Total model context window (tokens, approximate). User text is truncated to fit with headroom for the reply.
    @Published var maxModelContextTokens: Int {
        didSet {
            let v = Self.clamp(maxModelContextTokens, min: 2048, max: 512_000)
            if v != maxModelContextTokens { maxModelContextTokens = v; return }
            UserDefaults.standard.set(maxModelContextTokens, forKey: Keys.maxModelContextTokens)
            let cap = max(256, maxModelContextTokens - 512)
            if replyReserveTokens > cap {
                replyReserveTokens = cap
            }
        }
    }

    /// Tokens reserved for assistant output (rough); larger = less user text allowed.
    @Published var replyReserveTokens: Int {
        didSet {
            let cap = max(256, maxModelContextTokens - 512)
            let v = Self.clamp(replyReserveTokens, min: 256, max: cap)
            if v != replyReserveTokens { replyReserveTokens = v; return }
            UserDefaults.standard.set(replyReserveTokens, forKey: Keys.replyReserveTokens)
        }
    }

    @Published var queryServerContextLimit: Bool {
        didSet { UserDefaults.standard.set(queryServerContextLimit, forKey: Keys.queryServerContextLimit) }
    }

    @Published private(set) var hotkeyCombo: KeyCombo

    @Published var isChecking = false
    @Published var lastError: String?

    /// When set, the results overlay is shown. Updated from the model so it works even if the main `WindowGroup` is closed (menu bar + hotkey only).
    @Published var activeResult: GrammarRunResult? {
        didSet {
            if let r = activeResult {
                ResultsOverlayController.shared.show(result: r, appModel: self)
            } else {
                ResultsOverlayController.shared.hide()
            }
        }
    }

    private let hotkeyService = GlobalHotkeyService()

    init() {
        let defaults = UserDefaults.standard
        lmBaseURL = defaults.string(forKey: Keys.lmBaseURL) ?? "http://127.0.0.1:1234"
        model = defaults.string(forKey: Keys.model) ?? ""
        apiKey = defaults.string(forKey: Keys.apiKey) ?? ""
        if let raw = defaults.string(forKey: Keys.captureOrder), let order = TextCaptureOrder(rawValue: raw) {
            captureOrder = order
        } else {
            // Selection via AX is unreliable in many apps; clipboard-only matches the usual ⌘C workflow.
            captureOrder = .clipboardOnly
        }

        if defaults.object(forKey: Keys.bringResultsToFront) == nil {
            bringResultsToFront = true
        } else {
            bringResultsToFront = defaults.bool(forKey: Keys.bringResultsToFront)
        }

        if defaults.object(forKey: Keys.showFullReportInResults) == nil {
            showFullReportInResults = true
        } else {
            showFullReportInResults = defaults.bool(forKey: Keys.showFullReportInResults)
        }

        let loadedMaxContext = defaults.object(forKey: Keys.maxModelContextTokens) == nil
            ? 8192
            : Self.clamp(defaults.integer(forKey: Keys.maxModelContextTokens), min: 2048, max: 512_000)
        let replyCap = max(256, loadedMaxContext - 512)
        let loadedReplyReserve = defaults.object(forKey: Keys.replyReserveTokens) == nil
            ? min(4096, replyCap)
            : Self.clamp(defaults.integer(forKey: Keys.replyReserveTokens), min: 256, max: replyCap)
        maxModelContextTokens = loadedMaxContext
        replyReserveTokens = loadedReplyReserve
        if defaults.object(forKey: Keys.queryServerContextLimit) == nil {
            queryServerContextLimit = true
        } else {
            queryServerContextLimit = defaults.bool(forKey: Keys.queryServerContextLimit)
        }

        let defaultCombo = KeyCombo(key: .g, modifiers: [.command, .option, .shift])
        if defaults.object(forKey: Keys.hotkeyKeyCode) != nil,
           defaults.object(forKey: Keys.hotkeyMods) != nil
        {
            let kc = UInt32(defaults.integer(forKey: Keys.hotkeyKeyCode))
            let mods = UInt32(defaults.integer(forKey: Keys.hotkeyMods))
            hotkeyCombo = KeyCombo(carbonKeyCode: kc, carbonModifiers: mods)
        } else {
            hotkeyCombo = defaultCombo
        }

        hotkeyService.rebind(combo: hotkeyCombo) { [weak self] in
            self?.runCheckFromHotkey()
        }
    }

    func setHotkeyCombo(_ combo: KeyCombo) {
        hotkeyCombo = combo
        let defaults = UserDefaults.standard
        defaults.set(Int(combo.carbonKeyCode), forKey: Keys.hotkeyKeyCode)
        defaults.set(Int(combo.carbonModifiers), forKey: Keys.hotkeyMods)
        hotkeyService.rebind(combo: combo) { [weak self] in
            self?.runCheckFromHotkey()
        }
    }

    func runCheckFromHotkey() {
        Task { await performCheck() }
    }

    func runCheckFromUI() {
        Task { await performCheck() }
    }

    private func performCheck() async {
        guard !isChecking else { return }
        lastError = nil

        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModel.isEmpty else {
            failCheck("Set the LM Studio model id in Settings (the loaded model name).", bringToFront: true)
            return
        }

        let capture = TextCapture.captureWithDiagnostics(order: captureOrder)
        guard let text = capture.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty
        else {
            // Do not activate our app here: stealing focus breaks the next selection/AX read in your editor.
            failCheck(capture.diagnostics ?? "No text was captured. Check Settings → Capture and try again.", bringToFront: false)
            return
        }

        if text.caseInsensitiveCompare(trimmedModel) == .orderedSame {
            failCheck(
                """
                Captured text is identical to your model id (“\(trimmedModel)”). That value belongs only in Settings → Model id, not in the clipboard or selection.

                Copy or select the real sentence or paragraph you want checked, then run the check again. If you use the clipboard, copy your draft after you finish pasting the model name.
                """,
                bringToFront: false
            )
            return
        }

        isChecking = true
        defer { isChecking = false }

        let client = LMStudioClient(baseURL: lmBaseURL, model: trimmedModel, apiKey: apiKey.nilIfEmpty)

        var effectiveContext = maxModelContextTokens
        if queryServerContextLimit, let reported = await client.fetchServerContextTokenLimit() {
            effectiveContext = min(effectiveContext, max(2048, reported))
        }

        let replyBudget = min(replyReserveTokens, max(256, effectiveContext / 2))
        let truncated = InputContextLimiter.truncateUserText(
            text,
            maxModelContextTokens: effectiveContext,
            replyReserveTokens: replyBudget,
            systemPrompt: GrammarPrompt.systemMessage
        )

        do {
            let raw = try await client.review(text: truncated.text)
            let parsed = try? GrammarJSONParser.parse(from: raw)
            let note: String? = truncated.wasTruncated
                ? "Input was shortened to fit about \(effectiveContext) tokens of context (approximate UTF-8 budget). Sent \(truncated.text.utf8.count) of \(truncated.originalUTF8Count) UTF-8 bytes from the start of your capture."
                : nil
            activeResult = GrammarRunResult(
                sourceText: truncated.text,
                rawResponse: raw,
                parsed: parsed,
                inputWasTruncated: truncated.wasTruncated,
                truncationNote: note
            )
            surfaceCheckUIIfNeeded()
            AppActivation.requestDockAttentionIfInactive()
        } catch {
            failCheck(error.localizedDescription, bringToFront: true)
            AppActivation.requestDockAttentionIfInactive()
        }
    }

    private static func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }

    private func failCheck(_ message: String, bringToFront: Bool = true) {
        lastError = message
        if bringToFront {
            surfaceCheckUIIfNeeded()
        }
    }

    private func surfaceCheckUIIfNeeded() {
        guard bringResultsToFront else { return }
        AppActivation.bringAppToForeground()
    }

    private enum Keys {
        static let lmBaseURL = "fixmygrammar.lmBaseURL"
        static let model = "fixmygrammar.model"
        static let apiKey = "fixmygrammar.apiKey"
        static let captureOrder = "fixmygrammar.captureOrder"
        static let hotkeyKeyCode = "fixmygrammar.hotkeyKeyCode"
        static let hotkeyMods = "fixmygrammar.hotkeyMods"
        static let bringResultsToFront = "fixmygrammar.bringResultsToFront"
        static let showFullReportInResults = "fixmygrammar.showFullReportInResults"
        static let maxModelContextTokens = "fixmygrammar.maxModelContextTokens"
        static let replyReserveTokens = "fixmygrammar.replyReserveTokens"
        static let queryServerContextLimit = "fixmygrammar.queryServerContextLimit"
    }
}

struct GrammarRunResult: Identifiable {
    let id = UUID()
    let sourceText: String
    let rawResponse: String
    let parsed: GrammarReviewPayload?
    let inputWasTruncated: Bool
    let truncationNote: String?

    init(
        sourceText: String,
        rawResponse: String,
        parsed: GrammarReviewPayload?,
        inputWasTruncated: Bool = false,
        truncationNote: String? = nil
    ) {
        self.sourceText = sourceText
        self.rawResponse = rawResponse
        self.parsed = parsed
        self.inputWasTruncated = inputWasTruncated
        self.truncationNote = truncationNote
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : self
    }
}
