import SwiftUI

struct ContentView: View {
    @State private var vm = GameViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            GameView()
                .tabItem {
                    Label("Play", systemImage: "suit.club.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView(vm: vm)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Theme.gold)
        .onAppear {
            // Share vm with GameView via environment or direct injection
            // TabView shares the same vm instance via @State binding
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 0.95)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
