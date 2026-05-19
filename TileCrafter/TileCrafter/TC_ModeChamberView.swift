import SwiftUI

struct TC_ModeChamberView: View {

    @Environment(\.presentationMode) private var presentation
    @State private var pickedMode: TC_GameMode?

    var body: some View {
        ZStack {
            Color.tc(TC_AtelierLore.Palette.backdropWood).ignoresSafeArea()

            VStack(spacing: 18) {
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
                    Text("Choose a Ritual")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14),
                                        GridItem(.flexible(), spacing: 14)],
                              spacing: 14) {
                        ForEach(TC_GameMode.allCases, id: \.self) { mode in
                            modeCard(mode)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                }

                if let mode = pickedMode {
                    NavigationLink(
                        destination: TC_WorkshopStage(mode: mode, onExit: {
                            pickedMode = nil
                        }),
                        isActive: Binding(
                            get: { pickedMode != nil },
                            set: { if !$0 { pickedMode = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func modeCard(_ mode: TC_GameMode) -> some View {
        Button {
            pickedMode = mode
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: glyph(for: mode))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.tc(TC_AtelierLore.Palette.gold))
                Text(mode.displayTitle)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentWarm))
                Text(mode.blurb)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.tc(TC_AtelierLore.Palette.parchmentDeep))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusLarge)
                    .fill(Color.tc(TC_AtelierLore.Palette.backdropFelt, alpha: 0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusLarge)
                            .stroke(Color.tc(TC_AtelierLore.Palette.gold, alpha: 0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func glyph(for mode: TC_GameMode) -> String {
        switch mode {
        case .classic: return "infinity"
        case .puzzle:  return "puzzlepiece.extension"
        case .rush:    return "bolt.fill"
        case .zen:     return "leaf.fill"
        }
    }
}
