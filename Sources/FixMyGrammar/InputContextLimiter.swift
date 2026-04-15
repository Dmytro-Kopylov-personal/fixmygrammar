import Foundation

/// Keeps chat requests within a rough token budget (UTF-8 length heuristics; conservative for mixed languages).
enum InputContextLimiter {
    /// Rough input-side tokens from UTF-8 length (conservative vs. English-only /4).
    static func estimatedInputTokens(_ text: String) -> Int {
        max(1, text.utf8.count / 3)
    }

    /// Truncates user text so system prompt + user + headroom stay under `maxModelContextTokens`.
    static func truncateUserText(
        _ userText: String,
        maxModelContextTokens: Int,
        replyReserveTokens: Int,
        systemPrompt: String
    ) -> (text: String, wasTruncated: Bool, originalUTF8Count: Int) {
        let originalUTF8Count = userText.utf8.count
        let systemEst = max(200, (systemPrompt.utf8.count + 2) / 3)
        let cap = maxModelContextTokens - replyReserveTokens - systemEst
        let userTokenBudget = max(256, cap)
        let maxUTF8 = max(256, userTokenBudget * 3)

        guard userText.utf8.count > maxUTF8 else {
            return (userText, false, originalUTF8Count)
        }

        let data = Data(userText.utf8.prefix(maxUTF8))
        let truncated = String(decoding: data, as: UTF8.self)
        return (truncated, true, originalUTF8Count)
    }
}
