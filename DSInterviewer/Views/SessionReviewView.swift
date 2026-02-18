import SwiftUI

struct SessionReviewView: View {
    let session: InterviewSession
    @State private var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case incorrectOnly = "Incorrect"
        case correctionsOnly = "Corrections"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                scoreCard
                statsGrid
                filterPicker
                messageList
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 12) {
            if let score = session.overallScore {
                Text(String(format: "%.1f", score))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreGradient(score))

                Text(verdict(for: score))
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: session.topic.icon)
                Text(session.topic.rawValue)
                    .font(.subheadline)
            }
            .foregroundStyle(.indigo)

            Text(session.difficulty.rawValue)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.indigo.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ReviewStat(label: "Questions", value: "\(session.questionsAsked)", icon: "questionmark.circle")
            ReviewStat(label: "Correct", value: "\(session.correctAnswers)", icon: "checkmark.circle")
            ReviewStat(label: "Incorrect", value: "\(incorrectCount)", icon: "xmark.circle")
            ReviewStat(label: "Duration", value: session.formattedDuration, icon: "clock")
        }
    }

    // MARK: - Filter

    private var filterPicker: some View {
        Picker("Filter", selection: $filterMode) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Message List

    private var messageList: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(filteredMessages) { message in
                ReviewMessageCard(message: message)
            }
        }
    }

    // MARK: - Filtered Messages

    private var filteredMessages: [InterviewMessage] {
        switch filterMode {
        case .all:
            return session.messages
        case .incorrectOnly:
            return session.messages.filter { $0.evaluation == .incorrect || $0.evaluation == .partiallyCorrect }
        case .correctionsOnly:
            return session.messages.filter { $0.correction != nil }
        }
    }

    // MARK: - Helpers

    private var incorrectCount: Int {
        session.messages.filter { $0.evaluation == .incorrect }.count
    }

    private func scoreGradient(_ score: Double) -> Color {
        switch score {
        case 8...10: return .green
        case 6..<8: return .yellow
        case 4..<6: return .orange
        default: return .red
        }
    }

    private func verdict(for score: Double) -> String {
        switch score {
        case 9...10: return "Strong Hire"
        case 7.5..<9: return "Hire"
        case 6..<7.5: return "Lean Hire"
        case 4.5..<6: return "Lean No Hire"
        default: return "No Hire"
        }
    }
}

// MARK: - Review Stat

struct ReviewStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.indigo)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Review Message Card

struct ReviewMessageCard: View {
    let message: InterviewMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Role header
            HStack {
                Image(systemName: message.role == .interviewer ? "brain.head.profile" : "person.fill")
                    .foregroundStyle(message.role == .interviewer ? .indigo : .blue)
                Text(message.role == .interviewer ? "Interviewer" : "You")
                    .font(.caption.bold())
                    .foregroundStyle(message.role == .interviewer ? .indigo : .blue)

                Spacer()

                if let eval = message.evaluation {
                    EvaluationBadge(evaluation: eval)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(message.content)
                .font(.body)

            // Correction
            if let correction = message.correction {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.green)
                        Text("Correct Answer:")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    Text(correction)
                        .font(.callout)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
