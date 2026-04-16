import SwiftUI

struct LandingView: View {
    let onContinue: (BBSUser) -> Void

    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Better Basic Strategy")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.cream)
                    .multilineTextAlignment(.center)
                Text("Master blackjack basic strategy")
                    .font(.subheadline)
                    .foregroundColor(.muted)
            }

            HStack(spacing: 12) {
                FeatureBlurb(icon: "🃏", title: "6-Deck Shoe",  desc: "Realistic penetration")
                FeatureBlurb(icon: "📋", title: "All Rules",    desc: "H17, DAS, surrender")
                FeatureBlurb(icon: "📊", title: "Your Stats",   desc: "Track your progress")
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                TextField("Enter username", text: $username)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .foregroundColor(.cream)
                    .padding(14)
                    .background(Color.feltDark)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.5), lineWidth: 1))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if let err = errorMessage {
                    Text(err).foregroundColor(.red).font(.caption)
                }

                Button(action: submit) {
                    ZStack {
                        if isLoading { ProgressView().tint(.feltDark) }
                        else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.feltDark)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(canSubmit ? Color.gold : Color.gold.opacity(0.4))
                    .cornerRadius(8)
                }
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(Color.felt.ignoresSafeArea())
        .onAppear {
            if let saved = UserDefaults.standard.string(forKey: "bbs_username") { username = saved }
        }
    }

    private var canSubmit: Bool { !username.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading }

    private func submit() {
        let name = username.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isLoading = true; errorMessage = nil
        Task {
            do {
                let user = try await SupabaseService.shared.upsertUser(username: name)
                UserDefaults.standard.set(name, forKey: "bbs_username")
                onContinue(user)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private struct FeatureBlurb: View {
    let icon: String
    let title: String
    let desc: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 26))
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.cream)
            Text(desc).font(.system(size: 11)).foregroundColor(.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.feltDark)
        .cornerRadius(8)
    }
}
