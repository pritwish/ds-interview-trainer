import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selectedTopic: InterviewTopic = .mlSystemDesign
    @State private var selectedDifficulty: InterviewSession.Difficulty = .staff
    @State private var navigateToInterview = false
    @State private var showAPIKeyAlert = false

    let navigateToSettings: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    difficultySelector
                    topicGrid
                    startButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("DS Interviewer")
            .navigationDestination(isPresented: $navigateToInterview) {
                InterviewView(
                    topic: selectedTopic,
                    difficulty: selectedDifficulty,
                    settingsManager: settingsManager,
                    sessionStore: sessionStore
                )
            }
            .alert("API Key Required", isPresented: $showAPIKeyAlert) {
                Button("Go to Settings") {
                    navigateToSettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Add your Anthropic API key in Settings to start an interview.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.indigo)

            Text("Data Science Interview")
                .font(.title.bold())

            Text("Staff+ level. Big Tech caliber.\nPowered by Claude Opus 4.6")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                StatBadge(value: "\(sessionStore.sessions.count)", label: "Sessions")
                StatBadge(
                    value: averageScore,
                    label: "Avg Score"
                )
                StatBadge(
                    value: "\(totalQuestions)",
                    label: "Questions"
                )
            }
            .padding(.top, 8)
        }
        .padding(.top, 8)
    }

    // MARK: - Difficulty

    private var difficultySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DIFFICULTY")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Picker("Difficulty", selection: $selectedDifficulty) {
                ForEach(InterviewSession.Difficulty.allCases, id: \.self) { diff in
                    Text(diff.rawValue).tag(diff)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Topic Grid

    private var topicGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT TOPIC")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(InterviewTopic.allCases) { topic in
                    TopicCard(
                        topic: topic,
                        isSelected: selectedTopic == topic
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTopic = topic
                        }
                    }
                }
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            if settingsManager.hasAPIKey {
                navigateToInterview = true
            } else {
                showAPIKeyAlert = true
            }
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Interview")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.indigo)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 8)
    }

    // MARK: - Computed

    private var averageScore: String {
        let scores = sessionStore.sessions.compactMap { $0.overallScore }
        guard !scores.isEmpty else { return "—" }
        let avg = scores.reduce(0, +) / Double(scores.count)
        return String(format: "%.1f", avg)
    }

    private var totalQuestions: Int {
        sessionStore.sessions.reduce(0) { $0 + $1.questionsAsked }
    }
}

// MARK: - Supporting Views

struct TopicCard: View {
    let topic: InterviewTopic
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: topic.icon)
                .font(.title2)
                .foregroundStyle(isSelected ? .white : .indigo)

            Text(topic.rawValue)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(12)
        .background(isSelected ? Color.indigo : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.indigo : Color.clear, lineWidth: 2)
        )
    }
}

struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.indigo)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
