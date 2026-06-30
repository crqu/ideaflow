import Foundation

/// Processed note output from Claude API
struct ClaudeProcessedNote: Codable, Sendable {
    let title: String
    let content: String
    let tags: [String]
    let actionItems: [String]

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case tags
        case actionItems = "action_items"
    }
}

// MARK: - Raw Claude API Response Structures

/// Top-level response from Claude Messages API
struct ClaudeAPIResponse: Codable, Sendable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContentBlock]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: ClaudeUsage

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

/// Content block in Claude response
struct ClaudeContentBlock: Codable, Sendable {
    let type: String
    let text: String?
}

/// Token usage information
struct ClaudeUsage: Codable, Sendable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Request Structures

/// Request body for Claude Messages API
struct ClaudeAPIRequest: Codable, Sendable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
    }

    init(model: String, maxTokens: Int, messages: [ClaudeMessage], system: String? = nil) {
        self.model = model
        self.maxTokens = maxTokens
        self.messages = messages
        self.system = system
    }
}

/// Individual message in Claude conversation
struct ClaudeMessage: Codable, Sendable {
    let role: String
    let content: String
}
