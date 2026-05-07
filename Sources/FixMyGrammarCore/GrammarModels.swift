import Foundation

/// JSON contract between the app and the local LLM (grammar/style review).
public struct GrammarReviewPayload: Codable, Equatable, Sendable {
    public let correctedText: String
    public let issues: [GrammarIssue]

    public struct GrammarIssue: Codable, Equatable, Sendable {
        public let title: String
        public let detail: String
        public let severity: String?

        public init(title: String, detail: String, severity: String?) {
            self.title = title
            self.detail = detail
            self.severity = severity
        }
    }

    public init(correctedText: String, issues: [GrammarIssue]) {
        self.correctedText = correctedText
        self.issues = issues
    }
}

public enum GrammarJSONParser: Sendable {
    public static func parse(from raw: String) throws -> GrammarReviewPayload {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped = stripMarkdownCodeFence(from: trimmed)
        guard let data = stripped.data(using: .utf8) else {
            throw GrammarParseError.notUTF8
        }
        do {
            return try JSONDecoder().decode(GrammarReviewPayload.self, from: data)
        } catch {
            throw GrammarParseError.invalidJSON(underlying: error.localizedDescription, snippet: String(stripped.prefix(400)))
        }
    }

    private static func stripMarkdownCodeFence(from string: String) -> String {
        var s = string
        if s.hasPrefix("```") {
            s.removeFirst(3)
            if s.lowercased().hasPrefix("json") {
                s = String(s.dropFirst(4))
            }
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let end = s.range(of: "```", options: .backwards) {
                s = String(s[..<end.lowerBound])
            }
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum GrammarParseError: LocalizedError, Sendable {
    case notUTF8
    case invalidJSON(underlying: String, snippet: String)

    public var errorDescription: String? {
        switch self {
        case .notUTF8:
            return "The model response could not be read as UTF-8 text."
        case let .invalidJSON(underlying, snippet):
            return "Could not parse JSON from the model (\(underlying)). Snippet: \(snippet)"
        }
    }
}

public enum GrammarPrompt: Sendable {
    public static let systemMessage = """
    You are a copy editor. The user message is the text to fix for grammar, spelling, punctuation, and clear, natural style in the same language.
    Output one JSON object only. No markdown, no code fences, no text before or after the JSON, no chain-of-thought, no explanation outside JSON.
    Schema:
    {
      "correctedText": "<full revised text, minimal edits, same meaning, no new facts>",
      "issues": [ { "title": "<4–8 words max>", "detail": "<one short line, no bullet lists, no long paragraphs, no teaching>", "severity": "<grammar|spelling|style|clarity|other>" } ]
    }
    If nothing notable changed or issues would be redundant, return "issues": [].
    "detail" is optional brevity: prefer a single phrase; never write multi-sentence lessons or long reasoning.
    """
}
