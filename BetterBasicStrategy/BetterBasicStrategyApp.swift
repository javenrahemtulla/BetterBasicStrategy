import SwiftUI
import SwiftData

@main
struct BetterBasicStrategyApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([GameSession.self, HandRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
        }
    }
}
