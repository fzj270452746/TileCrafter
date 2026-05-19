import SwiftUI

struct TC_AtelierSettings: View {

    @Environment(\.relicVault) private var vault
    @Environment(\.timbreSpinner) private var timbre
    @Environment(\.presentationMode) private var presentation

    @State private var sfxOn: Bool = true
    @State private var bgmOn: Bool = true
    @State private var hapticOn: Bool = true
    @State private var showAcknowledge: Bool = false

    var body: some View {
        ZStack {
            Color.tc(TC_AtelierLore.Palette.backdropWood).ignoresSafeArea()

            VStack(spacing: 16) {
                header
                ScrollView {
                    VStack(spacing: 14) {
                        toggleRow(title: "Sound Effects", glyph: "speaker.wave.2.fill",
                                  binding: $sfxOn) { newValue in
                            vault.saveSfxOn(newValue)
                            timbre.updatePreferences(sfxOn: newValue, bgmOn: bgmOn)
                        }
                        toggleRow(title: "Background Music", glyph: "music.note",
                                  binding: $bgmOn) { newValue in
                            vault.saveBgmOn(newValue)
                            timbre.updatePreferences(sfxOn: sfxOn, bgmOn: newValue)
                            if newValue { timbre.startBgm() } else { timbre.stopBgm() }
                        }
                        toggleRow(title: "Haptic Feedback", glyph: "waveform",
                                  binding: $hapticOn) { newValue in
                            vault.saveHapticOn(newValue)
                        }

                        infoRow(title: "Edition", value: "1.0")
                        infoRow(title: "Made With", value: "SpriteKit · SwiftUI")

                        Button {
                            showAcknowledge = true
                        } label: {
                            Text("Credits")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                                        .stroke(Color.tc(TC_AtelierLore.Palette.parchmentDeep, alpha: 0.7),
                                                lineWidth: 1)
                                )
                                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            }

            if showAcknowledge {
                TC_VerdictParchment(
                    kind: .confirm,
                    headline: "Credits",
                    message: "Crafted with care for tile-loving minds. All mahjong artwork supplied by the project.",
                    primaryTitle: "Close",
                    onPrimary: { showAcknowledge = false }
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            sfxOn = vault.loadSfxOn()
            bgmOn = vault.loadBgmOn()
            hapticOn = vault.loadHapticOn()
        }
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
            Text("Settings")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func toggleRow(title: String,
                           glyph: String,
                           binding: Binding<Bool>,
                           onChange: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: glyph)
                .font(.system(size: 18, weight: .bold))
                .frame(width: 32, height: 32)
                .foregroundColor(.tc(TC_AtelierLore.Palette.gold))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
            Spacer()
            Toggle("", isOn: Binding(
                get: { binding.wrappedValue },
                set: { newValue in
                    binding.wrappedValue = newValue
                    onChange(newValue)
                }
            ))
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: Color.tc(TC_AtelierLore.Palette.jadeGreen)))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                .fill(Color.tc(TC_AtelierLore.Palette.backdropFelt, alpha: 0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                        .stroke(Color.tc(TC_AtelierLore.Palette.gold, alpha: 0.2), lineWidth: 1)
                )
        )
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentDeep))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                .fill(Color.tc(TC_AtelierLore.Palette.inkBrown, alpha: 0.5))
        )
    }
}
