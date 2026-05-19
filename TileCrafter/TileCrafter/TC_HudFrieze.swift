import SwiftUI

struct TC_HudFrieze: View {

    let score: Int
    let best: Int
    let comboDepth: Int
    let hazardLevel: Double
    let clockRemaining: TimeInterval
    let mode: TC_GameMode
    var barrierCount: Int = 0
    var onPause: () -> Void
    var onExit: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 40, height: 40)
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                    .background(
                        Circle().fill(Color.tc(TC_AtelierLore.Palette.inkBrown, alpha: 0.7))
                    )
                    .overlay(
                        Circle().stroke(Color.tc(TC_AtelierLore.Palette.gold, alpha: 0.4), lineWidth: 1)
                    )
            }

            VStack(spacing: 4) {
                Text("Score")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentDeep))
                Text("\(score)")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text(secondaryHeader)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentDeep))
                Text(secondaryValue)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(secondaryColor)
            }
            .frame(maxWidth: .infinity)

            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 40, height: 40)
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                    .background(
                        Circle().fill(Color.tc(TC_AtelierLore.Palette.inkBrown, alpha: 0.7))
                    )
                    .overlay(
                        Circle().stroke(Color.tc(TC_AtelierLore.Palette.gold, alpha: 0.4), lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                .fill(Color.tc(TC_AtelierLore.Palette.backdropFelt, alpha: 0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                        .stroke(Color.tc(TC_AtelierLore.Palette.gold, alpha: 0.25), lineWidth: 1)
                )
        )
        .overlay(
            hazardStrip
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .offset(y: 8)
        )
    }

    private var secondaryHeader: String {
        switch mode {
        case .rush:
            return "Time"
        case .puzzle:
            return "Barriers"
        default:
            return comboDepth > 0 ? "Combo" : "Best"
        }
    }

    private var secondaryValue: String {
        switch mode {
        case .rush:
            return formattedClock
        case .puzzle:
            return "\(barrierCount)"
        default:
            return comboDepth > 0 ? "x\(comboDepth)" : "\(best)"
        }
    }

    private var secondaryColor: Color {
        if mode == .puzzle {
            return barrierCount == 0
                ? Color.tc(TC_AtelierLore.Palette.jadeGreen)
                : Color.tc(TC_AtelierLore.Palette.lacquerRed)
        }
        return Color.tc(TC_AtelierLore.Palette.gold)
    }

    private var formattedClock: String {
        let total = max(0, Int(ceil(clockRemaining)))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%01d:%02d", minutes, seconds)
    }

    private var hazardStrip: some View {
        GeometryReader { geo in
            let clamped = max(0, min(1, hazardLevel))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.tc(TC_AtelierLore.Palette.inkBrown, alpha: 0.55))
                Capsule()
                    .fill(hazardColor(level: clamped))
                    .frame(width: geo.size.width * clamped)
            }
            .frame(height: 6)
        }
        .frame(height: 6)
    }

    private func hazardColor(level: Double) -> Color {
        let warning = level >= TC_AtelierLore.Grid.hazardThresholdRatio
        return warning
            ? Color.tc(TC_AtelierLore.Palette.hazardCrimson)
            : Color.tc(TC_AtelierLore.Palette.jadeGreen)
    }
}
