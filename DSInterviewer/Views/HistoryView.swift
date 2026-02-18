import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selectedSession: InterviewSession?
    @State private var showDeleteAllConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if sessionStore.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !sessionStore.sessions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All", role: .destructive) {
                            showDeleteAllConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .alert("Delete All Sessions?", isPresented: $showDeleteAllConfirmation) {
                Button("Delete All", role: .destructive) {
                    sessionStore.deleteAll()
                }
                Button("Cancel", role: .cancel) {}
            }
            .navigationDestination(item: $selectedSession) { session in
                SessionReviewView(session: session)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Interview History")
                .font(.headline)
            Text("Complete an interview to see your history and performance here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var sessionList: some View {
        List {
            ForEach(sessionStore.sessions) { session in
                SessionRow(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSession = session
                    }
            }
            .onDelete { indexSet in
                for idx in indexSet {
                    sessionStore.delete(sessionStore.sessions[idx])
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: InterviewSession

    var body: some View {
        HStack(spacing: 12) {
            // Topic icon
            Image(systemName: session.topic.icon)
                .font(.title2)
                .foregroundStyle(.indigo)
                .frame(width: 40, height: 40)
                .background(Color.indigo.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.topic.rawValue)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(session.difficulty.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.indigo.opacity(0.1))
                        .clipShape(Capsule())

                    Text("\(session.questionsAsked) questions")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(session.startedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Score
            if let score = session.overallScore {
                VStack {
                    Text(String(format: "%.1f", score))
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(scoreColor(score))
                    Text("/10")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(session.status == .active ? "Active" : "N/A")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 8...10: return .green
        case 6..<8: return .yellow
        case 4..<6: return .orange
        default: return .red
        }
    }
}

// Make InterviewSession Hashable for navigation
extension InterviewSession: Hashable {
    static func == (lhs: InterviewSession, rhs: InterviewSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
