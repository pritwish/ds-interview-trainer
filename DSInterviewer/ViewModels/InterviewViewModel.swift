import Foundation
import Combine

/// Coordinates the interview UI state, bridging the InterviewEngine,
/// SpeechRecognition, and SpeechSynthesis services.
@MainActor
final class InterviewViewModel: ObservableObject {
    // MARK: - Published State
    @Published var interviewEngine: InterviewEngine
    @Published var isInterviewActive = false
    @Published var showingEndConfirmation = false
    @Published var candidateInput = ""
    @Published var inputMode: InputMode = .voice
    @Published var statusMessage = "Ready to begin"
    @Published var lastEvaluation: InterviewerResponse.EvaluationBlock?
    @Published var lastCorrection: String?
    @Published var showCorrectionBanner = false

    let speechRecognition: SpeechRecognitionService
    let speechSynthesis: SpeechSynthesisService

    private let sessionStore: SessionStore
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    enum InputMode {
        case voice
        case text
    }

    init(
        topic: InterviewTopic,
        difficulty: InterviewSession.Difficulty,
        settingsManager: SettingsManager,
        sessionStore: SessionStore
    ) {
        let apiService = ClaudeAPIService(apiKey: settingsManager.apiKey)
        self.interviewEngine = InterviewEngine(apiService: apiService, topic: topic, difficulty: difficulty)
        self.speechRecognition = SpeechRecognitionService()
        self.speechSynthesis = SpeechSynthesisService()
        self.sessionStore = sessionStore
        self.settingsManager = settingsManager

        speechRecognition.silenceThreshold = settingsManager.silenceThresholdSeconds
        speechSynthesis.rate = Float(settingsManager.speechRate)

        setupSilenceDetection()
    }

    // MARK: - Interview Lifecycle

    func beginInterview() async {
        isInterviewActive = true
        statusMessage = "Interviewer is preparing..."

        guard let response = await interviewEngine.startInterview() else {
            statusMessage = interviewEngine.error ?? "Failed to start interview"
            return
        }

        statusMessage = "Interviewer is speaking..."
        await speakResponse(response.spoken)

        if settingsManager.autoListenAfterSpeech && inputMode == .voice {
            startListening()
        }

        statusMessage = "Your turn — answer the question"
    }

    func submitVoiceAnswer() async {
        let answer = speechRecognition.finalizeAndGetText()
        guard !answer.isEmpty else {
            statusMessage = "No speech detected. Try again."
            return
        }
        await processAnswer(answer)
    }

    func submitTextAnswer() async {
        let answer = candidateInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return }
        candidateInput = ""
        await processAnswer(answer)
    }

    func endInterview() async {
        statusMessage = "Generating final assessment..."
        speechRecognition.stopListening()
        speechSynthesis.stop()

        guard let response = await interviewEngine.endInterview() else {
            statusMessage = "Interview ended"
            return
        }

        await speakResponse(response.spoken)
        sessionStore.save(interviewEngine.session)
        statusMessage = "Interview complete"
        isInterviewActive = false
    }

    // MARK: - Voice Controls

    func startListening() {
        do {
            try speechRecognition.startListening()
            statusMessage = "Listening... Speak your answer"
        } catch {
            statusMessage = "Microphone error: \(error.localizedDescription)"
        }
    }

    func stopListening() {
        speechRecognition.stopListening()
    }

    func stopSpeaking() {
        speechSynthesis.stop()
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speechAuth = await speechRecognition.requestAuthorization()
        let micAuth = await speechRecognition.requestMicrophoneAccess()
        return speechAuth && micAuth
    }

    // MARK: - Private

    private func processAnswer(_ answer: String) async {
        statusMessage = "Evaluating your answer..."

        guard let response = await interviewEngine.submitAnswer(answer) else {
            statusMessage = interviewEngine.error ?? "Error processing answer"
            return
        }

        // Handle evaluation display
        lastEvaluation = response.evaluation
        if let correction = response.correction {
            lastCorrection = correction
            showCorrectionBanner = true
        } else {
            showCorrectionBanner = false
            lastCorrection = nil
        }

        // Speak the response
        statusMessage = "Interviewer is speaking..."
        let textToSpeak: String
        if settingsManager.vocalizeCorrections, let correction = response.correction {
            textToSpeak = response.spoken + " The correct answer is: " + correction
        } else {
            textToSpeak = response.spoken
        }
        await speakResponse(textToSpeak)

        // Auto-listen after interviewer finishes
        if settingsManager.autoListenAfterSpeech
            && inputMode == .voice
            && interviewEngine.interviewPhase != .completed {
            startListening()
        }

        statusMessage = "Your turn — answer the question"

        // Save session progress
        sessionStore.save(interviewEngine.session)
    }

    private func speakResponse(_ text: String) async {
        await withCheckedContinuation { continuation in
            speechSynthesis.speak(text) {
                continuation.resume()
            }
        }
    }

    private func setupSilenceDetection() {
        guard settingsManager.silenceDetectionEnabled else { return }
        speechRecognition.onSilenceDetected = { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                await self.submitVoiceAnswer()
            }
        }
    }
}
