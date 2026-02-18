import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingAPIKey = false
    @State private var tempAPIKey = ""

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                interviewDefaultsSection
                voiceSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        Section {
            HStack {
                if showingAPIKey {
                    TextField("sk-ant-...", text: $tempAPIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(.body, design: .monospaced))
                        .onAppear { tempAPIKey = settingsManager.apiKey }
                        .onChange(of: tempAPIKey) { _, newVal in
                            settingsManager.apiKey = newVal
                        }
                } else {
                    Text(settingsManager.hasAPIKey ? "sk-ant-•••••••••" : "Not configured")
                        .foregroundStyle(settingsManager.hasAPIKey ? .primary : .red)
                }

                Spacer()

                Button(showingAPIKey ? "Hide" : "Edit") {
                    showingAPIKey.toggle()
                }
                .font(.caption)
            }
        } header: {
            Text("Anthropic API Key")
        } footer: {
            Text("Required. Your key is stored locally on-device and used to call Claude Opus 4.6. Get one at console.anthropic.com.")
        }
    }

    // MARK: - Interview Defaults

    private var interviewDefaultsSection: some View {
        Section("Interview Defaults") {
            Picker("Default Difficulty", selection: $settingsManager.defaultDifficultyRaw) {
                ForEach(InterviewSession.Difficulty.allCases, id: \.rawValue) { diff in
                    Text(diff.rawValue).tag(diff.rawValue)
                }
            }

            Toggle("Show Evaluation Badges", isOn: $settingsManager.showEvaluationBadges)
            Toggle("Vocalize Corrections", isOn: $settingsManager.vocalizeCorrections)
        }
    }

    // MARK: - Voice Settings

    private var voiceSection: some View {
        Section("Voice & Speech") {
            Toggle("Auto-Listen After Interviewer Speaks", isOn: $settingsManager.autoListenAfterSpeech)

            Toggle("Silence Detection (auto-submit)", isOn: $settingsManager.silenceDetectionEnabled)

            if settingsManager.silenceDetectionEnabled {
                HStack {
                    Text("Silence Threshold")
                    Spacer()
                    Text("\(settingsManager.silenceThresholdSeconds, specifier: "%.1f")s")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settingsManager.silenceThresholdSeconds, in: 1.0...5.0, step: 0.5)
            }

            HStack {
                Text("Speech Rate")
                Spacer()
                Text("\(settingsManager.speechRate, specifier: "%.2f")x")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $settingsManager.speechRate, in: 0.5...1.5, step: 0.05)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Model")
                Spacer()
                Text("Claude Opus 4.6")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Target Experience")
                Spacer()
                Text("10+ YoE, Staff+")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
