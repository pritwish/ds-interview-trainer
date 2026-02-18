import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, history, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(navigateToSettings: { selectedTab = .settings })
                .tabItem {
                    Label("Interview", systemImage: "mic.badge.plus")
                }
                .tag(Tab.home)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(Tab.history)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.indigo)
    }
}
