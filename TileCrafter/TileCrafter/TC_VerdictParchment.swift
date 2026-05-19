import SwiftUI

enum TC_VerdictKind {
    case victory
    case defeat
    case confirm

    var accentColor: Color {
        switch self {
        case .victory: return .tc(TC_AtelierLore.Palette.gold)
        case .defeat:  return .tc(TC_AtelierLore.Palette.lacquerRed)
        case .confirm: return .tc(TC_AtelierLore.Palette.jadeGreen)
        }
    }

    var glyph: String {
        switch self {
        case .victory: return "sparkles"
        case .defeat:  return "hourglass"
        case .confirm: return "pause.circle.fill"
        }
    }
}

struct TC_VerdictParchment: View {
    let kind: TC_VerdictKind
    let headline: String
    let message: String
    let primaryTitle: String
    var secondaryTitle: String? = nil
    var onPrimary: () -> Void
    var onSecondary: (() -> Void)? = nil

    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: kind.glyph)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(kind.accentColor)
                    .padding(.top, 24)

                Text(headline)
                    .font(.system(size: 22, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.tc(TC_AtelierLore.Palette.inkBrown))

                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.tc(TC_AtelierLore.Palette.inkSoft))
                    .padding(.horizontal, 24)

                VStack(spacing: 10) {
                    Button(action: onPrimary) {
                        Text(primaryTitle)
                            .font(.system(size: 16, weight: .heavy))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                                    .fill(kind.accentColor)
                            )
                            .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                    }

                    if let secondaryTitle = secondaryTitle, let onSecondary = onSecondary {
                        Button(action: onSecondary) {
                            Text(secondaryTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                                        .stroke(Color.tc(TC_AtelierLore.Palette.inkSoft, alpha: 0.4),
                                                lineWidth: 1)
                                )
                                .foregroundColor(.tc(TC_AtelierLore.Palette.inkBrown))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: TC_AtelierLore.Layout.parchmentMaxWidth)
            .background(
                RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusLarge)
                    .fill(Color.tc(TC_AtelierLore.Palette.parchmentWarm))
                    .overlay(
                        RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusLarge)
                            .stroke(Color.tc(TC_AtelierLore.Palette.parchmentDeep), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 8)
            )
            .padding(.horizontal, 24)
            .scaleEffect(appear ? 1.0 : 0.85)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78, blendDuration: 0)) {
                appear = true
            }
        }
    }
}
