import SwiftUI

struct ContentView: View {
    @State private var currentUser: BBSUser?
    @State private var route: Route = .landing

    enum Route { case landing, game, stats }

    var body: some View {
        ZStack {
            Color.felt.ignoresSafeArea()

            switch route {
            case .landing:
                LandingView { user in
                    currentUser = user
                    route = .game
                }
            case .game:
                if let user = currentUser {
                    GameView(
                        user: user,
                        onStats: { route = .stats },
                        onExit:  { route = .landing }
                    )
                }
            case .stats:
                if let user = currentUser {
                    StatsView(user: user, onBack: { route = .game })
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
