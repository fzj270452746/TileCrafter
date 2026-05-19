import SwiftUI

struct TC_AtelierGate: View {

    @Environment(\.timbreSpinner) private var timbre
    @Environment(\.relicVault) private var vault

    @State private var goToModes: Bool = false
    @State private var goToChronicle: Bool = false
    @State private var goToSettings: Bool = false
    @State private var pulse: CGFloat = 0.9

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.tc(TC_AtelierLore.Palette.backdropWood),
                        Color.tc(TC_AtelierLore.Palette.backdropFelt)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                decorativeTiles

                VStack(spacing: 24) {
                    Spacer(minLength: 32)

                    VStack(spacing: 8) {
                        Text("MAHJONG")
                            .font(.system(size: 16, weight: .heavy))
                            .tracking(8)
                            .foregroundColor(.tc(TC_AtelierLore.Palette.gold))
                        Text("TileCrafter")
                            .font(.system(size: 44, weight: .black))
                            .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                        Text("Forge runs, kongs and combos")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentDeep))
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        NavigationLink(destination: TC_ModeChamberView(), isActive: $goToModes) {
                            EmptyView()
                        }
                        primaryButton(title: "Begin Crafting") {
                            goToModes = true
                        }
                        .scaleEffect(pulse)

                        NavigationLink(destination: TC_ChronicleLedger(), isActive: $goToChronicle) {
                            EmptyView()
                        }
                        secondaryButton(title: "Chronicle") { goToChronicle = true }

                        NavigationLink(destination: TC_AtelierSettings(), isActive: $goToSettings) {
                            EmptyView()
                        }
                        secondaryButton(title: "Settings") { goToSettings = true }
                    }
                    .padding(.horizontal, 36)
                    .padding(.bottom, 36)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = 1.04
                }
                let vaultSnapshot = vault
                timbre.updatePreferences(
                    sfxOn: vaultSnapshot.loadSfxOn(),
                    bgmOn: vaultSnapshot.loadBgmOn()
                )
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    private var decorativeTiles: some View {
        GeometryReader { geo in
            let tiles = [
                "TileCrafter-Lines-5",
                "TileCrafter-Million-7",
                "TileCrafter-Bing-3",
                "TileCrafter-RedZhong",
                "TileCrafter-GreenFa"
            ]
            ZStack {
                ForEach(Array(tiles.enumerated()), id: \.offset) { entry in
                    Image(entry.element)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .opacity(0.08)
                        .rotationEffect(.degrees(Double(entry.offset) * 23 - 14))
                        .position(
                            x: CGFloat([0.18, 0.78, 0.30, 0.72, 0.50][entry.offset]) * geo.size.width,
                            y: CGFloat([0.20, 0.28, 0.62, 0.68, 0.46][entry.offset]) * geo.size.height
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                        .fill(Color.tc(TC_AtelierLore.Palette.lacquerRed))
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 4)
                )
                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
        }
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                        .stroke(Color.tc(TC_AtelierLore.Palette.parchmentDeep, alpha: 0.7),
                                lineWidth: 1)
                )
                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
        }
    }
}
