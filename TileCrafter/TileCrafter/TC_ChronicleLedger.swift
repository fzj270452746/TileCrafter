import SwiftUI

struct TC_ChronicleLedger: View {

    @Environment(\.relicVault) private var vault
    @Environment(\.presentationMode) private var presentation

    @State private var bestByMode: [TC_GameMode: Int] = [:]
    @State private var totals: (chains: Int, cascades: Int, sessions: Int) = (0, 0, 0)

    var body: some View {
        ZStack {
            Color.tc(TC_AtelierLore.Palette.backdropWood).ignoresSafeArea()

            VStack(spacing: 18) {
                header
                ScrollView {
                    VStack(spacing: 14) {
                        statBlock(title: "Total Sessions", value: "\(totals.sessions)")
                        statBlock(title: "Total Chains", value: "\(totals.chains)")
                        statBlock(title: "Total Cascades", value: "\(totals.cascades)")

                        Divider()
                            .background(Color.tc(TC_AtelierLore.Palette.gold, alpha: 0.18))
                            .padding(.vertical, 8)

                        ForEach(TC_GameMode.allCases, id: \.self) { mode in
                            modeRow(mode: mode, best: bestByMode[mode] ?? 0)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadStats() }
    }

    private var header: some View {
        HStack {
            Button {
                presentation.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 40, height: 40)
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                    .background(
                        Circle().fill(Color.tc(TC_AtelierLore.Palette.inkBrown, alpha: 0.7))
                    )
            }
            Spacer()
            Text("Chronicle")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func statBlock(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentDeep))
            Spacer()
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.tc(TC_AtelierLore.Palette.gold))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                .fill(Color.tc(TC_AtelierLore.Palette.backdropFelt, alpha: 0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                        .stroke(Color.tc(TC_AtelierLore.Palette.gold, alpha: 0.18), lineWidth: 1)
                )
        )
    }

    private func modeRow(mode: TC_GameMode, best: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.displayTitle)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                Text(mode.blurb)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentDeep))
            }
            Spacer()
            Text("\(best)")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.tc(TC_AtelierLore.Palette.gold))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                .fill(Color.tc(TC_AtelierLore.Palette.inkBrown, alpha: 0.55))
        )
    }

    private func loadStats() {
        var fresh: [TC_GameMode: Int] = [:]
        for mode in TC_GameMode.allCases { fresh[mode] = vault.loadBest(for: mode) }
        bestByMode = fresh
        totals = vault.loadTotals()
    }
}
