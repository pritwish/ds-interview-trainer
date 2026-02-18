import Foundation

// MARK: - Claude API Request/Response Models

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [ClaudeMessage]
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
        case temperature
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let usage: Usage

    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }

    struct Usage: Codable {
        let inputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }

    var text: String {
        content.compactMap { $0.text }.joined()
    }
}

struct ClaudeErrorResponse: Codable {
    let type: String
    let error: ClaudeError

    struct ClaudeError: Codable {
        let type: String
        let message: String
    }
}

// MARK: - Structured Interview Response

struct InterviewerResponse: Codable {
    let spoken: String
    let evaluation: EvaluationBlock?
    let correction: String?
    let followUpReason: String?
    let shouldContinueTopic: Bool
    let topicMastery: Double?
    let internalNotes: String?

    struct EvaluationBlock: Codable {
        let verdict: String
        let score: Double
        let gaps: [String]
    }
}
