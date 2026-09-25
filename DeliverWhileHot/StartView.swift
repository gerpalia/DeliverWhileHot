//
//  StartView.swift
//  DeliverWhileHot
//

import SwiftUI

struct StartView: View {
    @State private var isGameStarted = false
    @State private var presentedPage: MenuPage?

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

                VStack(spacing: 12) {
                    Spacer()

                    Button {
                        isGameStarted = true
                    } label: {
                        Text("menu.new_game")
                    }
                    .buttonStyle(GameMenuButtonStyle(filled: true))

                    HStack(spacing: 12) {
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
        }
        .buttonStyle(GameMenuButtonStyle())
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
            VStack(alignment: .leading, spacing: 18) {
                if page == .howToPlay {
                    Text("how_to_play.movement")
                    Text("how_to_play.objective")
                } else {
                    Text("about.title")
                        .font(GameStyle.displayFont)
                    Text("about.description")
                    Text("about.version")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .font(GameStyle.bodyFont)
            .padding()
            .navigationTitle(Text(page.titleKey))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
        .tint(GameStyle.accent)
    }
}
