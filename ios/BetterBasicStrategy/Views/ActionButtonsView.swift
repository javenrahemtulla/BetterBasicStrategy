import SwiftUI

struct ActionButtonsView: View {
    let available: Set<DecisionCategory>
    let onAction: (DecisionCategory) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ActionBtn(.hit,       available, onAction)
                ActionBtn(.stand,     available, onAction)
            }
            HStack(spacing: 8) {
                ActionBtn(.double,    available, onAction)
                ActionBtn(.split,     available, onAction)
            }
            ActionBtn(.surrender, available, onAction)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct ActionBtn: View {
    let category: DecisionCategory
    let available: Set<DecisionCategory>
    let onAction: (DecisionCategory) -> Void

    init(_ category: DecisionCategory, _ available: Set<DecisionCategory>, _ onAction: @escaping (DecisionCategory) -> Void) {
        self.category = category; self.available = available; self.onAction = onAction
    }

    var isEnabled: Bool { available.contains(category) }

    var body: some View {
        Button { onAction(category) } label: {
            Text(category.display)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isEnabled ? category.color : Color.gray.opacity(0.25))
                .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}
