import SwiftUI

struct ActionButtonsView: View {
    let available: Set<DecisionCategory>
    let onAction: (DecisionCategory) -> Void

    private let allActions: [DecisionCategory] = [.hit, .stand, .double, .split, .surrender]

    var body: some View {
        VStack(spacing: 10) {
            // Primary row: Hit + Stand
            HStack(spacing: 10) {
                ActionButton(category: .hit, available: available, onAction: onAction)
                ActionButton(category: .stand, available: available, onAction: onAction)
            }
            // Secondary row: Double + Split + Surrender
            HStack(spacing: 10) {
                ActionButton(category: .double, available: available, onAction: onAction)
                ActionButton(category: .split, available: available, onAction: onAction)
                ActionButton(category: .surrender, available: available, onAction: onAction)
            }
        }
        .padding(.horizontal, Theme.padding)
    }
}

private struct ActionButton: View {
    let category: DecisionCategory
    let available: Set<DecisionCategory>
    let onAction: (DecisionCategory) -> Void

    private var isEnabled: Bool { available.contains(category) }

    var body: some View {
        Button {
            onAction(category)
        } label: {
            Text(category.displayName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: Theme.buttonCornerRadius)
                        .fill(isEnabled ? category.buttonColor : Color.white.opacity(0.06))
                )
                .foregroundColor(isEnabled ? .white : Theme.textSecondary)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
    }
}

extension DecisionCategory {
    var displayName: String {
        switch self {
        case .hit: return "Hit"
        case .stand: return "Stand"
        case .double: return "Double"
        case .split: return "Split"
        case .surrender: return "Surrender"
        }
    }
}
