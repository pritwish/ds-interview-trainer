import SwiftUI

struct InterviewView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var sessionStore: SessionStore
    @StateObject private var viewModel: InterviewViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEndConfirmation = false
    @State private var hasStarted = false

    let topic: InterviewTopic
    let difficulty: InterviewSession.Difficulty

    init(topic: InterviewTopic, difficulty: InterviewSession.Difficulty, settingsManager: SettingsManager, sessionStore: SessionStore) {
        self.topic = topic
        self.difficulty = difficulty
        _viewModel = StateObject(wrappedValue: InterviewViewModel(
            topic: topic,
            difficulty: difficulty,
            settingsManager: settingsManager,
            sessionStore: sessionStore
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            interviewHeader
            Divider()
            transcriptView
            Divider()
            correctionBanner
            inputArea
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(topic.rawValue)
                        .font(.headline)
                    Text(viewModel.interviewEngine.interviewPhase.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") {
                    showEndConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
        .alert("End Interview?", isPresented: $showEndConfirmation) {
            Button("End & Get Assessment", role: .destructive) {
                Task { await viewModel.endInterview() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The interviewer will provide a final assessment of your performance.")
        }
        .onAppear {
            if !hasStarted {
                hasStarted = true
                Task {
                    let _ = await viewModel.requestPermissions()
                    await viewModel.beginInterview()
                }
            }
        }
        .navigationBarBackButtonHidden(viewModel.isInterviewActive)
    }

    // MARK: - Header

    private var interviewHeader: some View {
        HStack(spacing: 12) {
            // Phase indicator
            PhaseIndicator(phase: viewModel.interviewEngine.interviewPhase)

            Spacer()

            // Status
            HStack(spacing: 6) {
                if viewModel.interviewEngine.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Question count
            VStack(alignment: .trailing) {
                Text("Q\(viewModel.interviewEngine.session.questionsAsked)")
                    .font(.caption.bold().monospacedDigit())
                if let mastery = viewModel.interviewEngine.session.topicScores[topic.rawValue] {
                    Text("\(Int(mastery * 100))%")
                        .font(.caption2)
                        .foregroundStyle(masteryColor(mastery))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Transcript

    private var transcriptView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.interviewEngine.session.messages) { message in
                        MessageBubble(message: message, showBadges: settingsManager.showEvaluationBadges)
                            .id(message.id)
                    }

                    // Live transcription
                    if viewModel.speechRecognition.isListening
                        && !viewModel.speechRecognition.recognizedText.isEmpty {
                        LiveTranscriptBubble(text: viewModel.speechRecognition.recognizedText)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding()
            }
            .onChange(of: viewModel.interviewEngine.session.messages.count) {
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.speechRecognition.recognizedText) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Correction Banner

    @ViewBuilder
    private var correctionBanner: some View {
        if viewModel.showCorrectionBanner, let correction = viewModel.lastCorrection {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Correction")
                        .font(.caption.bold())
                    Spacer()
                    Button {
                        viewModel.showCorrectionBanner = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                Text(correction)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 8) {
            // Mode toggle
            Picker("Input Mode", selection: $viewModel.inputMode) {
                Label("Voice", systemImage: "mic.fill").tag(InterviewViewModel.InputMode.voice)
                Label("Text", systemImage: "keyboard").tag(InterviewViewModel.InputMode.text)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if viewModel.inputMode == .voice {
                voiceInput
            } else {
                textInput
            }
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var voiceInput: some View {
        HStack(spacing: 20) {
            // Stop speaking button
            if viewModel.speechSynthesis.isSpeaking {
                Button {
                    viewModel.stopSpeaking()
                } label: {
                    Image(systemName: "speaker.slash.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                }
            }

            // Main mic button
            Button {
                if viewModel.speechRecognition.isListening {
                    Task { await viewModel.submitVoiceAnswer() }
                } else {
                    viewModel.startListening()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.speechRecognition.isListening ? Color.red : Color.indigo)
                        .frame(width: 64, height: 64)

                    if viewModel.speechRecognition.isListening {
                        // Pulsing animation
                        Circle()
                            .stroke(Color.red.opacity(0.4), lineWidth: 3)
                            .frame(width: 76, height: 76)
                            .scaleEffect(viewModel.speechRecognition.isListening ? 1.2 : 1.0)
                            .opacity(viewModel.speechRecognition.isListening ? 0 : 1)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: viewModel.speechRecognition.isListening)
                    }

                    Image(systemName: viewModel.speechRecognition.isListening ? "stop.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .disabled(viewModel.interviewEngine.isProcessing || viewModel.speechSynthesis.isSpeaking)

            // Skip button
            Button {
                Task { await viewModel.submitVoiceAnswer() }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Color.indigo.opacity(0.15))
                    .clipShape(Circle())
            }
            .disabled(!viewModel.speechRecognition.isListening)
        }
        .padding(.horizontal)
    }

    private var textInput: some View {
        HStack(spacing: 12) {
            TextField("Type your answer...", text: $viewModel.candidateInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)

            Button {
                Task { await viewModel.submitTextAnswer() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(.indigo)
            }
            .disabled(viewModel.candidateInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      || viewModel.interviewEngine.isProcessing)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func masteryColor(_ mastery: Double) -> Color {
        switch mastery {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - Phase Indicator

struct PhaseIndicator: View {
    let phase: InterviewEngine.InterviewPhase

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)
            Text(phase.rawValue)
                .font(.caption2.bold())
                .foregroundStyle(phaseColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(phaseColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var phaseColor: Color {
        switch phase {
        case .notStarted: return .gray
        case .introduction: return .blue
        case .questioning: return .indigo
        case .drilling: return .purple
        case .correcting: return .orange
        case .wrappingUp: return .yellow
        case .completed: return .green
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: InterviewMessage
    let showBadges: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .interviewer {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundStyle(.indigo)
                    .frame(width: 32)
            }

            VStack(alignment: message.role == .interviewer ? .leading : .trailing, spacing: 6) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(bubbleColor)
                    .foregroundStyle(message.role == .candidate ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                if showBadges, let eval = message.evaluation {
                    EvaluationBadge(evaluation: eval)
                }

                if let correction = message.correction {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(correction)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .interviewer ? .leading : .trailing)

            if message.role == .candidate {
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 32)
            }
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .interviewer: return Color(.secondarySystemGroupedBackground)
        case .candidate: return .indigo
        case .system: return Color.yellow.opacity(0.15)
        }
    }
}

// MARK: - Evaluation Badge

struct EvaluationBadge: View {
    let evaluation: InterviewMessage.Evaluation

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private var icon: String {
        switch evaluation {
        case .correct: return "checkmark.circle.fill"
        case .partiallyCorrect: return "circle.lefthalf.filled"
        case .incorrect: return "xmark.circle.fill"
        case .needsMoreDepth: return "arrow.down.circle.fill"
        }
    }

    private var label: String {
        switch evaluation {
        case .correct: return "Correct"
        case .partiallyCorrect: return "Partial"
        case .incorrect: return "Incorrect"
        case .needsMoreDepth: return "Go Deeper"
        }
    }

    private var color: Color {
        switch evaluation {
        case .correct: return .green
        case .partiallyCorrect: return .yellow
        case .incorrect: return .red
        case .needsMoreDepth: return .purple
        }
    }
}

// MARK: - Live Transcript Bubble

struct LiveTranscriptBubble: View {
    let text: String

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text(text)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.indigo.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.indigo.opacity(0.3))
            )
            Image(systemName: "person.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)
        }
    }
}
