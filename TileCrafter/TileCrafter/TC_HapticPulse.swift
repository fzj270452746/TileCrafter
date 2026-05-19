import UIKit

enum TC_HapticPulse {
    case soft
    case crisp
    case heavy
    case success
    case warning

    func emit(enabled: Bool) {
        guard enabled else { return }
        switch self {
        case .soft:
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.prepare(); gen.impactOccurred()
        case .crisp:
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.prepare(); gen.impactOccurred()
        case .heavy:
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.prepare(); gen.impactOccurred()
        case .success:
            let gen = UINotificationFeedbackGenerator()
            gen.prepare(); gen.notificationOccurred(.success)
        case .warning:
            let gen = UINotificationFeedbackGenerator()
            gen.prepare(); gen.notificationOccurred(.warning)
        }
    }
}
