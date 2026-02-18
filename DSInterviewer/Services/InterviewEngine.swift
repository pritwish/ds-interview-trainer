import Foundation
import Combine

/// Core interview orchestration engine. Manages the conversation flow between
/// the candidate and Claude Opus, enforcing the adaptive questioning protocol.
@MainActor
final class InterviewEngine: ObservableObject {
    @Published var session: InterviewSession
    @Published var isProcessing = false
    @Published var error: String?
    @Published var conversationHistory: [ClaudeMessage] = []
    @Published var interviewPhase: InterviewPhase = .notStarted
    @Published var currentTopicAttempts: Int = 0

    private let apiService: ClaudeAPIService
    private let maxAttemptsPerTopic = 5  // Max follow-ups on same sub-topic before moving on

    enum InterviewPhase: String {
        case notStarted = "Not Started"
        case introduction = "Introduction"
        case questioning = "In Progress"
        case drilling = "Deep Dive"
        case correcting = "Correction"
        case wrappingUp = "Wrapping Up"
        case completed = "Completed"
    }

    init(apiService: ClaudeAPIService, topic: InterviewTopic, difficulty: InterviewSession.Difficulty) {
        self.apiService = apiService
        self.session = InterviewSession(topic: topic, difficulty: difficulty)
    }

    // MARK: - Build System Prompt

    private func buildSystemPrompt() -> String {
        var prompt = ClaudeAPIService.interviewerSystemPrompt
        prompt += "\n\nINTERVIEW CONFIGURATION:\n"
        prompt += "- Topic: \(session.topic.rawValue)\n"
        prompt += "- \(session.topic.topicPromptContext)\n"
        prompt += "- \(session.difficulty.systemModifier)\n"
        prompt += "- Questions asked so far: \(session.questionsAsked)\n"
        prompt += "- Current topic attempts: \(currentTopicAttempts)/\(maxAttemptsPerTopic)\n"

        if !session.topicScores.isEmpty {
            prompt += "- Topic mastery scores so far: \(session.topicScores)\n"
        }

        prompt += """

        ADAPTIVE DIFFICULTY RULES:
        - If the candidate gets 3+ answers correct in a row, INCREASE difficulty significantly.
        - If the candidate gets 2+ answers wrong in a row, stay on the same concept but rephrase \
        to build understanding before moving on.
        - After correcting a wrong answer, ALWAYS ask a verification question on the same concept.
        - For a 10-year veteran, do NOT soften questions. Maintain high standards throughout.
        - If the candidate says "I don't know", probe whether they can reason through it from first principles.

        ANTI-GAMING RULES:
        - If answers sound memorized or textbook-like, ask the candidate to explain with a concrete example from their experience.
        - If answers are vague, demand specifics: exact algorithms, complexity, production numbers.
        - If the candidate tries to redirect to their strengths, bring them back to the current topic.
        """

        return prompt
    }

    // MARK: - Start Interview

    func startInterview() async -> InterviewerResponse? {
        interviewPhase = .introduction
        isProcessing = true
        error = nil

        let systemPrompt = buildSystemPrompt()

        // Initial message to kick off the interview
        conversationHistory = [
            ClaudeMessage(role: "user", content: "[SYSTEM: Interview session started. The candidate is ready. Begin with your introduction and first question.]")
        ]

        do {
            let response = try await apiService.sendMessage(
                systemPrompt: systemPrompt,
                conversationHistory: conversationHistory
            )

            // Add interviewer's response to history
            conversationHistory.append(ClaudeMessage(role: "assistant", content: response.spoken))

            // Record in session
            let message = InterviewMessage(role: .interviewer, content: response.spoken)
            session.messages.append(message)

            interviewPhase = .questioning
            isProcessing = false
            return response
        } catch {
            self.error = error.localizedDescription
            isProcessing = false
            return nil
        }
    }

    // MARK: - Submit Candidate Answer

    func submitAnswer(_ answer: String) async -> InterviewerResponse? {
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        isProcessing = true
        error = nil
        currentTopicAttempts += 1

        // Record candidate message
        let candidateMessage = InterviewMessage(role: .candidate, content: answer)
        session.messages.append(candidateMessage)

        // Add to conversation history
        conversationHistory.append(ClaudeMessage(role: "user", content: answer))

        let systemPrompt = buildSystemPrompt()

        do {
            let response = try await apiService.sendMessage(
                systemPrompt: systemPrompt,
                conversationHistory: conversationHistory
            )

            // Add interviewer response to conversation history
            let fullResponse = formatFullResponse(response)
            conversationHistory.append(ClaudeMessage(role: "assistant", content: fullResponse))

            // Update session with evaluation
            updateSessionWithEvaluation(response)

            // Record interviewer message
            let interviewerMessage = InterviewMessage(
                role: .interviewer,
                content: response.spoken,
                evaluation: mapEvaluation(response.evaluation?.verdict),
                correction: response.correction,
                followUpReason: response.followUpReason
            )
            session.messages.append(interviewerMessage)

            // Update topic mastery
            if let mastery = response.topicMastery {
                session.topicScores[session.topic.rawValue] = mastery
            }

            // Update phase
            updatePhase(response)

            isProcessing = false
            return response
        } catch {
            self.error = error.localizedDescription
            isProcessing = false
            return nil
        }
    }

    // MARK: - End Interview

    func endInterview() async -> InterviewerResponse? {
        interviewPhase = .wrappingUp
        isProcessing = true

        conversationHistory.append(ClaudeMessage(
            role: "user",
            content: "[SYSTEM: The candidate has ended the interview. Provide a comprehensive final assessment including: overall verdict (Strong Hire / Hire / Lean Hire / Lean No Hire / No Hire), key strengths, critical gaps, specific areas for improvement, and a numeric score out of 10. Be brutally honest.]"
        ))

        let systemPrompt = buildSystemPrompt()

        do {
            let response = try await apiService.sendMessage(
                systemPrompt: systemPrompt,
                conversationHistory: conversationHistory
            )

            conversationHistory.append(ClaudeMessage(role: "assistant", content: response.spoken))

            let message = InterviewMessage(role: .interviewer, content: response.spoken)
            session.messages.append(message)

            session.overallScore = response.topicMastery.map { $0 * 10 }
            session.endedAt = Date()
            session.status = .completed
            interviewPhase = .completed
            isProcessing = false
            return response
        } catch {
            self.error = error.localizedDescription
            session.endedAt = Date()
            session.status = .completed
            interviewPhase = .completed
            isProcessing = false
            return nil
        }
    }

    // MARK: - Private Helpers

    private func formatFullResponse(_ response: InterviewerResponse) -> String {
        // For conversation history, include the spoken part plus any correction
        var text = response.spoken
        if let correction = response.correction {
            text += "\n\n[Correction provided: \(correction)]"
        }
        return text
    }

    private func updateSessionWithEvaluation(_ response: InterviewerResponse) {
        guard let eval = response.evaluation,
              let idx = session.messages.lastIndex(where: { $0.role == .candidate }) else { return }

        session.messages[idx].evaluation = mapEvaluation(eval.verdict)
    }

    private func mapEvaluation(_ verdict: String?) -> InterviewMessage.Evaluation? {
        guard let verdict = verdict?.lowercased() else { return nil }
        switch verdict {
        case "correct": return .correct
        case "partially_correct": return .partiallyCorrect
        case "incorrect": return .incorrect
        case "needs_more_depth": return .needsMoreDepth
        default: return nil
        }
    }

    private func updatePhase(_ response: InterviewerResponse) {
        if response.shouldContinueTopic {
            if response.evaluation?.verdict == "incorrect" || response.evaluation?.verdict == "partially_correct" {
                interviewPhase = .correcting
            } else {
                interviewPhase = .drilling
            }
        } else {
            currentTopicAttempts = 0
            interviewPhase = .questioning
        }
    }
}
