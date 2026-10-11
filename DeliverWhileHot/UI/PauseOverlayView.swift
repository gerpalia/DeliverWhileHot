//
//  PauseOverlayView.swift
//  DeliverWhileHot
//

import SwiftUI

struct PauseOverlayView: View {
    let onResume: () -> Void
    let onReturnToMenu: () -> Void

    @State private var showingMenuConfirmation = false

    var body: some View {
        GeometryReader { geometry in
            let panelWidth = min(220,
                                 min(geometry.size.width - 32,
                                     (geometry.size.height - 80) * 815 / 990))
            let panelHeight = panelWidth * 990 / 815
            let buttonWidth = panelWidth * 0.78
            let resumeArtworkHeight = buttonWidth * 245 / 915
            let menuArtworkHeight = buttonWidth * 276 / 915
            let buttonTapHeight = max(64, max(resumeArtworkHeight, menuArtworkHeight) + 10)

            ZStack {
                Color.black.opacity(0.68)
                    .ignoresSafeArea()

                ZStack {
                    Image("DeliverWhileHotPausePanel")
                        .resizable()
                        .scaledToFit()
                        .frame(width: panelWidth, height: panelHeight)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(showingMenuConfirmation ? "LEAVE RUN?" : "PAUSED")
                            .font(GameStyle.displayFont)
                            .foregroundStyle(GameStyle.cream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity)

                        if showingMenuConfirmation {
                            Text("Leave this run? Your current progress will be lost.")
                                .font(GameStyle.secondaryFont)
                                .foregroundStyle(.white.opacity(0.86))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            pauseButton(imageName: "DeliverWhileHotPauseMainMenu",
                                        title: "CANCEL",
                                        identifier: "pause.cancel",
                                        width: buttonWidth,
                                        artworkHeight: menuArtworkHeight,
                                        tapHeight: buttonTapHeight) {
                                showingMenuConfirmation = false
                            }

                            pauseButton(imageName: "DeliverWhileHotPauseMainMenu",
                                        title: "LEAVE",
                                        identifier: "pause.confirmLeave",
                                        width: buttonWidth,
                                        artworkHeight: menuArtworkHeight,
                                        tapHeight: buttonTapHeight,
                                        action: onReturnToMenu)
                        } else {
                            pauseButton(imageName: "DeliverWhileHotPauseResume",
                                        title: "RESUME",
                                        identifier: "pause.resume",
                                        width: buttonWidth,
                                        artworkHeight: resumeArtworkHeight,
                                        tapHeight: buttonTapHeight,
                                        action: onResume)

                            pauseButton(imageName: "DeliverWhileHotPauseMainMenu",
                                        title: "MAIN MENU",
                                        identifier: "pause.mainMenu",
                                        width: buttonWidth,
                                        artworkHeight: menuArtworkHeight,
                                        tapHeight: buttonTapHeight) {
                                showingMenuConfirmation = true
                            }
                        }

                    }
                    .padding(.horizontal, panelWidth * 0.13)
                    .frame(width: panelWidth, height: panelHeight)
                }
                .frame(width: panelWidth, height: panelHeight)
                .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
            }
        }
    }

    private func pauseButton(imageName: String,
                             title: String,
                             identifier: String,
                             width: CGFloat,
                             artworkHeight: CGFloat,
                             tapHeight: CGFloat,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: artworkHeight)
                    .accessibilityHidden(true)

                Text(title)
                    .font(GameStyle.primaryButtonFont)
                    .foregroundStyle(GameStyle.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(width: width, height: artworkHeight, alignment: .center)
                    .offset(y: imageName == "DeliverWhileHotPauseResume" ? 3 : 0)
            }
            .frame(width: width, height: tapHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
