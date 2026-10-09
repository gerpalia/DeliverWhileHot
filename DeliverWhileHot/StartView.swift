//
//  StartView.swift
//  DeliverWhileHot
//

import SwiftUI

struct StartView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isGameStarted = false
    @State private var presentedPage: MenuPage?
    @StateObject private var menuMusic = BackgroundMusicPlayer()

    var body: some View {
        Group {
            if isGameStarted {
                ContentView()
            } else {
                menuScreen
            }
        }
        .sheet(item: $presentedPage) { page in
            MenuInformationView(page: page)
        }
        .onAppear {
            if !isGameStarted {
                menuMusic.play(resourceName: "aliabbasabasov-epic-heavy-type-beat-rap-instrumental-prod5xbeatz-524490.mp3", volume: 0.32)
            }
        }
        .onDisappear {
            menuMusic.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            guard !isGameStarted else {
                menuMusic.stop()
                return
            }

            if phase == .active {
                menuMusic.play(resourceName: "aliabbasabasov-epic-heavy-type-beat-rap-instrumental-prod5xbeatz-524490.mp3", volume: 0.32)
            } else {
                menuMusic.stop()
            }
        }
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
                        menuMusic.stop()
                        isGameStarted = true
                    } label: {
                        Text("menu.new_game")
                            .font(GameStyle.primaryButtonFont)
                            .fontWeight(.bold)
                    }
                    .buttonStyle(GameMenuButtonStyle(filled: true))
                    .offset(y: 16)
                    .accessibilityIdentifier("menu.newGame")

                    HStack(spacing: 16) {
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if page == .howToPlay {
                        Text("how_to_play.movement.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("howToPlay.movement")
                        Text("how_to_play.movement")
                        Text("how_to_play.actions.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("howToPlay.actions")
                        Text("how_to_play.actions")
                        Text("how_to_play.food.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("howToPlay.food")
                        Text("how_to_play.food")
                        Text("how_to_play.goal.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("howToPlay.goal")
                        Text("how_to_play.goal")
                    } else {
                        Text("about.title")
                            .font(GameStyle.displayFont)
                            .accessibilityIdentifier("about.title")
                        Text("about.description")
                        Text("about.version")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .font(GameStyle.bodyFont)
            .navigationTitle(Text(page.titleKey))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                        .accessibilityIdentifier("common.done")
                }
            }
        }
        .tint(GameStyle.accent)
    }
}
