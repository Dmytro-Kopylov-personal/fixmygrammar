import Foundation

/// JSON contract between the app and the local LLM (grammar/style review).
struct GrammarReviewPayload: Codable, Equatable {
    let correctedText: String
    let issues: [GrammarIssue]

    struct GrammarIssue: Codable, Equatable {
        let title: String
        let detail: String
        let severity: String?
    }
}

enum GrammarJSONParser {
    static func parse(from raw: String) throws -> GrammarReviewPayload {
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

enum GrammarParseError: LocalizedError {
    case notUTF8
    case invalidJSON(underlying: String, snippet: String)

    var errorDescription: String? {
        switch self {
        case .notUTF8:
            return "The model response could not be read as UTF-8 text."
        case let .invalidJSON(underlying, snippet):
            return "Could not parse JSON from the model (\(underlying)). Snippet: \(snippet)"
        }
    }
}

enum GrammarPrompt {
    static let systemMessage = """
    You are an expert copy editor. The user will send text to review for grammar, spelling, punctuation, and clear style.
    Respond with a single JSON object only (no markdown fences, no commentary). Use this exact shape and keys:
    {
      "correctedText": "<full improved text, same language as input>",
      "issues": [
        {
          "title": "<short label>",
          "detail": "<what to change and why>",
          "severity": "<grammar|spelling|style|clarity|other>"
        }
      ]
    }
    If there are no issues, use an empty array for "issues". Preserve meaning; do not add new facts.
    """
}
