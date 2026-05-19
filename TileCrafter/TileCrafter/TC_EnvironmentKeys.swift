import SwiftUI

private struct TC_TimbreSpinnerKey: EnvironmentKey {
    static let defaultValue = TC_TimbreSpinner()
}
private struct TC_RelicVaultKey: EnvironmentKey {
    static let defaultValue = TC_RelicVault()
}
private struct TC_BannerEnvoyKey: EnvironmentKey {
    static let defaultValue = TC_BannerEnvoy()
}

extension EnvironmentValues {
    var timbreSpinner: TC_TimbreSpinner {
        get { self[TC_TimbreSpinnerKey.self] }
        set { self[TC_TimbreSpinnerKey.self] = newValue }
    }
    var relicVault: TC_RelicVault {
        get { self[TC_RelicVaultKey.self] }
        set { self[TC_RelicVaultKey.self] = newValue }
    }
    var bannerEnvoy: TC_BannerEnvoy {
        get { self[TC_BannerEnvoyKey.self] }
        set { self[TC_BannerEnvoyKey.self] = newValue }
    }
}

extension Color {
    static func tc(_ hex: UInt32, alpha: Double = 1.0) -> Color {
        let red   = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue  = Double(hex & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension UIColor {
    static func tc(_ hex: UInt32, alpha: CGFloat = 1.0) -> UIColor {
        let red   = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue  = CGFloat(hex & 0xFF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
