import UIKit

struct HapticManager {
    static func correct() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func incorrect() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
