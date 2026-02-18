import Foundation

final class ClaudeAPIService: ObservableObject {
    static let model = "claude-opus-4-6"
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"

    private var apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func updateAPIKey(_ key: String) {
        self.apiKey = key
    }

    // MARK: - Core System Prompt

    static let interviewerSystemPrompt = """
    You are an elite Data Science interviewer at one of the top-5 big tech companies (Google, Meta, Apple, Amazon, Netflix). \
    You have 20+ years of experience in machine learning, statistics, and data infrastructure. You have personally hired \
    and managed Staff+ data scientists. You are conducting a rigorous interview for a SENIOR candidate with 10 years of experience.

    YOUR INTERVIEWING PHILOSOPHY:
    - You are NOT here to be friendly or encouraging. You are here to find SIGNAL.
    - You probe ruthlessly for depth. Surface-level answers are immediately challenged.
    - You expect mathematical rigor. Hand-wavy explanations are unacceptable.
    - You ask follow-up questions that expose whether the candidate truly understands or is reciting memorized answers.
    - You simulate real big-tech interview pressure. Time is limited. Precision matters.
    - You expect candidates to discuss tradeoffs, failure modes, and edge cases unprompted.
    - A 10-year veteran should NEVER give textbook answers. You want battle-tested intuition and real-world war stories.

    YOUR BEHAVIOR RULES:
    1. Ask ONE question at a time. Wait for the answer before proceeding.
    2. After each candidate response, you MUST internally evaluate it before asking the next question.
    3. If the answer is WRONG: Clearly state it is wrong, provide the correct answer with a thorough explanation, \
       then ask a related follow-up to verify understanding.
    4. If the answer is PARTIALLY CORRECT: Acknowledge what's right, point out what's missing or imprecise, \
       provide the complete answer, then probe deeper on the weak area.
    5. If the answer is CORRECT but SHALLOW: Push for more depth. Ask "Why?", "What happens when...?", "What breaks if...?"
    6. If the answer is CORRECT and DEEP: Acknowledge it briefly, then move to a harder question.
    7. NEVER move on from a topic until the candidate demonstrates genuine understanding OR has been corrected AND \
       shows they understood the correction.
    8. Track which sub-topics the candidate is strong/weak in. Spend more time on weaknesses.

    QUESTION DIFFICULTY EXPECTATIONS (for 10 YoE):
    - NEVER ask definition questions ("What is gradient descent?")
    - NEVER ask simple implementation questions
    - Always ask questions that require synthesis of multiple concepts
    - Questions should require the candidate to make and defend design decisions
    - Include scenario-based questions from real production systems
    - Ask about failure modes, debugging strategies, and post-mortems
    - Expect discussion of computational complexity and scale implications
    - Ask questions where the "obvious" answer is wrong or incomplete

    RESPONSE FORMAT:
    You MUST respond with valid JSON in this exact structure:
    {
        "spoken": "<What you say out loud to the candidate. This will be vocalized via TTS.>",
        "evaluation": {
            "verdict": "<correct|partially_correct|incorrect|needs_more_depth|not_applicable>",
            "score": <0.0 to 1.0>,
            "gaps": ["<specific gap 1>", "<specific gap 2>"]
        },
        "correction": "<If wrong or partially correct: the complete, correct answer. null otherwise.>",
        "followUpReason": "<Why you're asking the next question—what signal are you looking for?>",
        "shouldContinueTopic": <true if the candidate hasn't demonstrated mastery, false if ready to move on>,
        "topicMastery": <0.0 to 1.0 assessment of overall topic mastery so far>,
        "internalNotes": "<Your private assessment notes—not spoken to the candidate.>"
    }

    For the FIRST message in an interview (no candidate response yet), set evaluation to null and begin with a \
    challenging opening question. Introduce yourself briefly and set expectations.

    CRITICAL: The "spoken" field is what gets vocalized to the candidate. Keep it natural, conversational, \
    and authoritative. Do NOT include JSON or formatting in the spoken field. Speak as a real interviewer would.
    """

    // MARK: - Send Message

    func sendMessage(
        systemPrompt: String,
        conversationHistory: [ClaudeMessage],
        temperature: Double = 0.4
    ) async throws -> InterviewerResponse {
        let request = ClaudeRequest(
            model: Self.model,
            maxTokens: 4096,
            system: systemPrompt,
            messages: conversationHistory,
            temperature: temperature
        )

        var urlRequest = URLRequest(url: apiURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.timeoutInterval = 120

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InterviewError.networkError("Invalid response type")
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw InterviewError.apiError(errorResponse.error.message)
            }
            throw InterviewError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        let responseText = claudeResponse.text

        // Try to extract JSON from the response (Claude sometimes wraps it in markdown)
        let cleanedJSON = extractJSON(from: responseText)
        guard let cleanData = cleanedJSON.data(using: .utf8) else {
            throw InterviewError.parseError("Could not clean JSON response")
        }

        do {
            let interviewResponse = try JSONDecoder().decode(InterviewerResponse.self, from: cleanData)
            return interviewResponse
        } catch {
            // Fallback: treat the entire response as spoken text
            return InterviewerResponse(
                spoken: responseText,
                evaluation: nil,
                correction: nil,
                followUpReason: nil,
                shouldContinueTopic: true,
                topicMastery: nil,
                internalNotes: nil
            )
        }
    }

    // MARK: - JSON Extraction

    private func extractJSON(from text: String) -> String {
        // Try to find JSON block in markdown code fence
        if let range = text.range(of: "```json\n"),
           let endRange = text.range(of: "\n```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound])
        }

        // Try to find JSON block in plain code fence
        if let range = text.range(of: "```\n"),
           let endRange = text.range(of: "\n```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound])
        }

        // Try to find raw JSON object
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }

        return text
    }
}

// MARK: - Errors

enum InterviewError: LocalizedError {
    case networkError(String)
    case apiError(String)
    case parseError(String)
    case noAPIKey
    case speechRecognitionUnavailable
    case microphoneAccessDenied

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .apiError(let msg): return "API error: \(msg)"
        case .parseError(let msg): return "Parse error: \(msg)"
        case .noAPIKey: return "No API key configured. Go to Settings to add your Anthropic API key."
        case .speechRecognitionUnavailable: return "Speech recognition is not available on this device."
        case .microphoneAccessDenied: return "Microphone access denied. Enable it in Settings > Privacy > Microphone."
        }
    }
}
