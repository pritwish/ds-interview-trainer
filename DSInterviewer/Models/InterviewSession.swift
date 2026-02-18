import Foundation

struct InterviewSession: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    var topic: InterviewTopic
    var difficulty: Difficulty
    var messages: [InterviewMessage]
    var overallScore: Double?
    var topicScores: [String: Double]
    var status: SessionStatus

    enum SessionStatus: String, Codable {
        case active
        case completed
        case abandoned
    }

    enum Difficulty: String, Codable, CaseIterable {
        case staff = "Staff / L6+"
        case principal = "Principal / L7+"
        case distinguished = "Distinguished / L8+"

        var systemModifier: String {
            switch self {
            case .staff:
                return "Ask questions at Staff-level (L6+) difficulty. Expect deep expertise in system design, ML pipelines at scale, and leadership of cross-functional initiatives."
            case .principal:
                return "Ask questions at Principal-level (L7+) difficulty. Expect mastery of org-wide technical strategy, novel algorithm design, and mentorship of senior ICs. Probe for first-principles thinking."
            case .distinguished:
                return "Ask questions at Distinguished Engineer (L8+) difficulty. Expect industry-defining contributions, ability to set multi-year technical vision, and deep theoretical grounding. Accept nothing less than exceptional depth."
            }
        }
    }

    init(topic: InterviewTopic, difficulty: Difficulty) {
        self.id = UUID()
        self.startedAt = Date()
        self.topic = topic
        self.difficulty = difficulty
        self.messages = []
        self.topicScores = [:]
        self.status = .active
    }

    var duration: TimeInterval? {
        guard let end = endedAt else { return nil }
        return end.timeIntervalSince(startedAt)
    }

    var formattedDuration: String {
        guard let dur = duration else { return "In Progress" }
        let minutes = Int(dur) / 60
        let seconds = Int(dur) % 60
        return "\(minutes)m \(seconds)s"
    }

    var questionsAsked: Int {
        messages.filter { $0.role == .interviewer }.count
    }

    var correctAnswers: Int {
        messages.filter { $0.role == .candidate && $0.evaluation == .correct }.count
    }
}

struct InterviewMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    var evaluation: Evaluation?
    var correction: String?
    var followUpReason: String?

    enum Role: String, Codable {
        case interviewer
        case candidate
        case system
    }

    enum Evaluation: String, Codable {
        case correct
        case partiallyCorrect
        case incorrect
        case needsMoreDepth
    }

    init(role: Role, content: String, evaluation: Evaluation? = nil, correction: String? = nil, followUpReason: String? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.evaluation = evaluation
        self.correction = correction
        self.followUpReason = followUpReason
    }
}
