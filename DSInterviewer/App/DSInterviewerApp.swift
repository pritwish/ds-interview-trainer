import SwiftUI

@main
struct DSInterviewerApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
                .environmentObject(sessionStore)
        }
    }
}
