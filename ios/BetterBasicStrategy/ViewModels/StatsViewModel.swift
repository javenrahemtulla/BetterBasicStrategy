import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var stats: StatsData?
    @Published var isLoading = false
    @Published var error: String?

    func load(userId: String) async {
        isLoading = true; error = nil
        do {
            stats = try await SupabaseService.shared.fetchStats(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
