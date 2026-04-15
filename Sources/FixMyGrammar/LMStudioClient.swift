import Foundation

struct LMStudioClient: Sendable {
    var baseURL: String
    var model: String
    var apiKey: String?

    func review(text: String) async throws -> String {
        let url = try makeChatCompletionsURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "system", content: GrammarPrompt.systemMessage),
                .init(role: "user", content: text),
            ],
            temperature: 0.2
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LMStudioError.badResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw LMStudioError.httpStatus(http.statusCode, text)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices?.first?.message?.content else {
            throw LMStudioError.emptyChoices
        }
        return content
    }

    private func makeChatCompletionsURL() throws -> URL {
        var trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.last == "/" {
            trimmed.removeLast()
        }
        guard var components = URLComponents(string: trimmed) else {
            throw LMStudioError.invalidBaseURL
        }
        if components.path.isEmpty || components.path == "/" {
            components.path = "/v1/chat/completions"
        } else if !components.path.hasSuffix("/chat/completions") {
            if components.path.hasSuffix("/v1") {
                components.path += "/chat/completions"
            } else {
                components.path += "/v1/chat/completions"
            }
        }
        guard let url = components.url else {
            throw LMStudioError.invalidBaseURL
        }
        return url
    }

    /// Best-effort context length from LM Studio `GET /v1/models` (shape varies by version).
    func fetchServerContextTokenLimit() async -> Int? {
        guard let url = try? makeModelsListURL() else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200 ... 299).contains(http.statusCode),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = root["data"] as? [[String: Any]]
        else {
            return nil
        }

        for row in rows where (row["id"] as? String) == model {
            if let n = contextLength(in: row) { return n }
        }
        return nil
    }

    private func contextLength(in dict: [String: Any]) -> Int? {
        let keys = ["context_length", "max_context", "n_ctx", "contextWindow", "context_window"]
        for k in keys {
            if let v = dict[k] as? Int { return max(0, v) }
            if let v = dict[k] as? Int64 { return max(0, Int(v)) }
            if let v = dict[k] as? Double { return max(0, Int(v)) }
        }
        if let meta = dict["meta"] as? [String: Any] {
            return contextLength(in: meta)
        }
        return nil
    }

    private func makeModelsListURL() throws -> URL {
        var trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.last == "/" {
            trimmed.removeLast()
        }
        guard var components = URLComponents(string: trimmed) else {
            throw LMStudioError.invalidBaseURL
        }
        if components.path.isEmpty || components.path == "/" {
            components.path = "/v1/models"
        } else if components.path.hasSuffix("/v1/models") {
            // ok
        } else if components.path.hasSuffix("/v1") {
            components.path += "/models"
        } else {
            components.path += "/v1/models"
        }
        guard let url = components.url else {
            throw LMStudioError.invalidBaseURL
        }
        return url
    }
}

enum LMStudioError: LocalizedError {
    case invalidBaseURL
    case badResponse
    case httpStatus(Int, String)
    case emptyChoices

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "The LM Studio base URL is invalid. Try http://127.0.0.1:1234"
        case .badResponse:
            return "Unexpected response from LM Studio."
        case let .httpStatus(code, body):
            return "LM Studio returned HTTP \(code): \(body)"
        case .emptyChoices:
            return "LM Studio returned no message content."
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message?
    }

    let choices: [Choice]?
}
