import Foundation
import AVFoundation

@MainActor
final class SpeechSynthesisService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    @Published var speakingProgress: Double = 0.0

    private let synthesizer = AVSpeechSynthesizer()
    private var completionHandler: (() -> Void)?
    private var totalCharacters: Int = 0
    var rate: Float = 0.92

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speak the given text with an authoritative interviewer voice.
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        stop()

        let utterance = AVSpeechUtterance(string: text)

        // Use a deep, professional voice
        if let voice = selectVoice() {
            utterance.voice = voice
        }

        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.pitchMultiplier = 0.95  // Slightly lower pitch
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.2

        self.completionHandler = completion
        self.totalCharacters = text.count
        self.isSpeaking = true
        self.speakingProgress = 0.0

        // Configure audio session for playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }

        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        speakingProgress = 0.0
        completionHandler = nil
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }

    // MARK: - Voice Selection

    private func selectVoice() -> AVSpeechSynthesisVoice? {
        let preferredVoices = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.enhanced.en-US.Evan",
            "com.apple.voice.enhanced.en-US.Aaron",
            "com.apple.ttsbundle.siri_Aaron_en-US_compact",
            "com.apple.ttsbundle.siri_male_en-US_compact"
        ]

        for voiceID in preferredVoices {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
                return voice
            }
        }

        // Fallback to any en-US voice
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.speakingProgress = 1.0
            self.completionHandler?()
            self.completionHandler = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if self.totalCharacters > 0 {
                self.speakingProgress = Double(characterRange.location + characterRange.length) / Double(self.totalCharacters)
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.speakingProgress = 0.0
            self.completionHandler = nil
        }
    }
}
