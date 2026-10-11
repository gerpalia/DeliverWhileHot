//
//  StartView.swift
//  DeliverWhileHot
//

import SwiftUI

struct StartView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isGameStarted = false
    @State private var isLaunchingGame = false
    @State private var presentedPage: MenuPage?
    @StateObject private var menuMusic = BackgroundMusicPlayer()

    var body: some View {
        ZStack {
            Group {
                if isGameStarted {
                    ContentView(onReturnToMenu: {
                        isGameStarted = false
                    }, onReady: {
                        menuMusic.stop()
                        isLaunchingGame = false
                    })
                } else {
                    menuScreen
                }
            }

            if isLaunchingGame {
                LoadingTransitionView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .sheet(item: $presentedPage) { page in
            MenuInformationView(page: page)
        }
        .onAppear {
            syncMenuMusic()
        }
        .onDisappear {
            menuMusic.stop()
        }
        .onChange(of: scenePhase) { _, _ in
            syncMenuMusic()
        }
        .onChange(of: isGameStarted) { _, _ in
            syncMenuMusic()
        }
    }

    private func syncMenuMusic() {
        guard !isGameStarted, scenePhase == .active else {
            menuMusic.stop()
            return
        }

        menuMusic.play(resourceName: "aliabbasabasov-epic-heavy-type-beat-rap-instrumental-prod5xbeatz-524490.mp3",
                       volume: 0.32)
    }

    private var menuScreen: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image("DeliverWhileHotSplash")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.94)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 4) {
                    Spacer()

                    Button {
                        isLaunchingGame = true
                        // Give SwiftUI a run-loop to draw the loader before doing
                        // any work associated with the first gameplay scene.
                        DispatchQueue.main.async {
                            GameScene.prepareResources {
                                isGameStarted = true
                            }
                        }
                    } label: {
                        Text("menu.new_game")
                            .font(GameStyle.primaryButtonFont)
                            .fontWeight(.bold)
                    }
                    .buttonStyle(GameMenuButtonStyle(filled: true))
                    .offset(y: 22)
                    .accessibilityIdentifier("menu.newGame")

                    HStack(spacing: 10) {
                        menuButton(titleKey: "menu.how_to_play", page: .howToPlay)
                        menuButton(titleKey: "menu.about", page: .about)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, max(28, geometry.safeAreaInsets.bottom + 12))
            }
        }
        .ignoresSafeArea()
    }

    private func menuButton(titleKey: LocalizedStringKey, page: MenuPage) -> some View {
        Button {
            presentedPage = page
        } label: {
            Text(titleKey)
                .font(GameStyle.secondaryButtonFont)
        }
        .buttonStyle(GameMenuButtonStyle())
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityIdentifier(page == .howToPlay ? "menu.howToPlay" : "menu.about")
    }
}

private enum MenuPage: String, Identifiable {
    case howToPlay
    case about

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .howToPlay: return "menu.how_to_play"
        case .about: return "menu.about"
        }
    }
}

private struct MenuInformationView: View {
    let page: MenuPage
    @Environment(\.dismiss) private var dismiss
    @State private var showingCredits = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if page == .howToPlay {
                        Text("how_to_play.movement.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("howToPlay.movement")
                        Text("how_to_play.movement")
                        Text("how_to_play.food.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("howToPlay.food")
                        VStack(alignment: .leading, spacing: 10) {
                            GuideInfoRow(icon: .symbol("heart.fill", .red),
                                         description: "how_to_play.food.health",
                                         accessibilityIdentifier: "howToPlay.food.health")
                            GuideInfoRow(icon: .image("DeliverWhileHotPizzaSliceIcon"),
                                         description: "how_to_play.food.pizza",
                                         accessibilityIdentifier: "howToPlay.food.pizza")
                            GuideInfoRow(icon: .image("DeliverWhileHotMolotovReady"),
                                         description: "how_to_play.food.molotov",
                                         accessibilityIdentifier: "howToPlay.food.molotov")
                            GuideInfoRow(icon: .temperature,
                                         description: "how_to_play.food.temperature",
                                         accessibilityIdentifier: "howToPlay.food.temperature")
                        }
                        Text("how_to_play.actions.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("howToPlay.actions")
                        VStack(alignment: .leading, spacing: 10) {
                            ActionGuideRow(imageName: "DeliverWhileHotBlockIcon",
                                           description: "how_to_play.action.block",
                                           accessibilityIdentifier: "howToPlay.action.block")
                            ActionGuideRow(imageName: "DeliverWhileHotEatingIcon",
                                           description: "how_to_play.action.eat",
                                           accessibilityIdentifier: "howToPlay.action.eat")
                            ActionGuideRow(imageName: "DeliverWhileHotMolotovActionIcon",
                                           description: "how_to_play.action.molotov",
                                           accessibilityIdentifier: "howToPlay.action.molotov")
                        }
                        Text("how_to_play.goal.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("howToPlay.goal")
                        Text("how_to_play.goal")
                        VStack(alignment: .leading, spacing: 10) {
                            ActionGuideRow(imageName: "EndingPreparePrompt",
                                           description: "how_to_play.goal.prepare",
                                           accessibilityIdentifier: "howToPlay.goal.prepare")
                            ActionGuideRow(imageName: "EndingJumpPrompt",
                                           description: "how_to_play.goal.jump",
                                           accessibilityIdentifier: "howToPlay.goal.jump")
                        }
                    } else {
                        AboutGameContent(showingCredits: $showingCredits)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .font(GameStyle.bodyFont)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image("DeliverWhileHotCloseButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 38, height: 38)
                            .contentShape(Circle())
                    }
                    .accessibilityIdentifier("common.done")
                    .accessibilityLabel("Close")
                }
            }
        }
        .tint(GameStyle.accent)
        .sheet(isPresented: $showingCredits) {
            CreditsView()
        }
    }
}

private struct AboutGameContent: View {
    @Binding var showingCredits: Bool

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version.map { "v\($0)" } ?? "v1.0"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Image("DeliverWhileHotGameLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 226, height: 156)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(GameStyle.cream.opacity(0.7), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("about.tagline")
                    .font(GameStyle.displayFont)
                    .foregroundStyle(GameStyle.cream)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("about.tagline")

                Text("about.description")
                    .font(GameStyle.bodyFont)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("about.description")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("about.story")
                    .font(GameStyle.secondaryFont)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("about.story")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)

            VStack(spacing: 5) {
                Text("about.made_by")
                    .font(GameStyle.secondaryFont)
                    .foregroundStyle(.secondary)
                    .tracking(2)
                Text("Gerson da Cunha")
                    .font(GameStyle.primaryButtonFont)
                    .foregroundStyle(GameStyle.cream)
                    .accessibilityIdentifier("about.author")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            Button {
                showingCredits = true
            } label: {
                Text("about.credits_button")
                    .font(GameStyle.secondaryButtonFont)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GameMenuButtonStyle())
            .accessibilityIdentifier("about.credits")

            Text(appVersion)
                .font(GameStyle.secondaryFont)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("about.version")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("about.credits_title")
                        .font(GameStyle.displayFont)
                        .accessibilityIdentifier("about.creditsTitle")
                    Text("about.credits_body")
                        .font(GameStyle.bodyFont)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("about.creditsBody")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image("DeliverWhileHotCloseButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 38, height: 38)
                    }
                    .accessibilityIdentifier("credits.close")
                    .accessibilityLabel("Close")
                }
            }
        }
        .tint(GameStyle.accent)
    }
}

private struct ActionGuideRow: View {
    let imageName: String
    let description: LocalizedStringKey
    let accessibilityIdentifier: String

    var body: some View {
        HStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding(5)
                .frame(width: 56, height: 56)
                .background(.black.opacity(0.72), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.45), lineWidth: 1)
                }
                .accessibilityHidden(true)

            Text(description)
                .font(GameStyle.secondaryFont)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct GuideInfoRow: View {
    enum Icon {
        case image(String)
        case symbol(String, Color)
        case temperature
    }

    let icon: Icon
    let description: LocalizedStringKey
    let accessibilityIdentifier: String

    var body: some View {
        HStack(spacing: 12) {
            iconView
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)

            Text(description)
                .font(GameStyle.secondaryFont)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case let .image(name):
            Image(name)
                .resizable()
                .scaledToFit()
                .padding(5)
                .background(.black.opacity(0.72), in: Circle())
                .overlay { Circle().stroke(.white.opacity(0.45), lineWidth: 1) }
        case let .symbol(name, color):
            Image(systemName: name)
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(.black.opacity(0.72), in: Circle())
                .overlay { Circle().stroke(.white.opacity(0.45), lineWidth: 1) }
        case .temperature:
            HStack(spacing: 2) {
                Image(systemName: "snowflake")
                    .foregroundStyle(Color(red: 0.72, green: 0.88, blue: 0.96))
                Capsule()
                    .fill(LinearGradient(colors: [.blue, .orange, .red], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 23, height: 8)
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.orange)
            }
            .font(.system(size: 12, weight: .bold))
            .frame(width: 56, height: 56)
            .background(.black.opacity(0.72), in: Capsule())
            .overlay { Capsule().stroke(.white.opacity(0.45), lineWidth: 1) }
        }
    }
}
