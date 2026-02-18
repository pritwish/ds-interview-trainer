import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var isAvailable = false
    @Published var errorMessage: String?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // Silence detection
    private var silenceTimer: Timer?
    var silenceThreshold: TimeInterval = 2.5  // seconds of silence before auto-stop
    private var lastSpeechTimestamp = Date()
    var onSilenceDetected: (() -> Void)?

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkAvailability()
    }

    // MARK: - Permissions

    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self.isAvailable = true
                        continuation.resume(returning: true)
                    case .denied, .restricted, .notDetermined:
                        self.isAvailable = false
                        self.errorMessage = "Speech recognition not authorized."
                        continuation.resume(returning: false)
                    @unknown default:
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    func requestMicrophoneAccess() async -> Bool {
        return await AVAudioApplication.requestRecordPermission()
    }

    // MARK: - Start / Stop Listening

    func startListening() throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw InterviewError.speechRecognitionUnavailable
        }

        // Cancel any ongoing task
        stopListening()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                Task { @MainActor in
                    self.recognizedText = result.bestTranscription.formattedString
                    self.lastSpeechTimestamp = Date()
                }
            }

            if let error = error {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                    self.stopListening()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
        recognizedText = ""
        lastSpeechTimestamp = Date()
        startSilenceDetection()
    }

    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    func finalizeAndGetText() -> String {
        let text = recognizedText
        stopListening()
        return text
    }

    // MARK: - Silence Detection

    private func startSilenceDetection() {
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                let elapsed = Date().timeIntervalSince(self.lastSpeechTimestamp)
                if elapsed >= self.silenceThreshold && !self.recognizedText.isEmpty {
                    self.onSilenceDetected?()
                }
            }
        }
    }

    // MARK: - Availability

    private func checkAvailability() {
        isAvailable = speechRecognizer?.isAvailable ?? false
    }
}
