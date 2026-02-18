import Foundation
import SwiftUI

@MainActor
final class SettingsManager: ObservableObject {
    @AppStorage("anthropic_api_key") var apiKey: String = ""
    @AppStorage("auto_listen_after_speech") var autoListenAfterSpeech: Bool = true
    @AppStorage("silence_detection_enabled") var silenceDetectionEnabled: Bool = true
    @AppStorage("silence_threshold_seconds") var silenceThresholdSeconds: Double = 2.5
    @AppStorage("speech_rate") var speechRate: Double = 0.92
    @AppStorage("default_difficulty") var defaultDifficultyRaw: String = InterviewSession.Difficulty.staff.rawValue
    @AppStorage("vocalize_corrections") var vocalizeCorrections: Bool = true
    @AppStorage("show_evaluation_badges") var showEvaluationBadges: Bool = true

    var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var defaultDifficulty: InterviewSession.Difficulty {
        get { InterviewSession.Difficulty(rawValue: defaultDifficultyRaw) ?? .staff }
        set { defaultDifficultyRaw = newValue.rawValue }
    }
}
