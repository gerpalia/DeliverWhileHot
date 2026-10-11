//
//  PauseOverlayView.swift
//  DeliverWhileHot
//

import SwiftUI

struct PauseOverlayView: View {
    let onClose: () -> Void
    let onResume: () -> Void
    let onReturnToMenu: () -> Void

    @State private var showingMenuConfirmation = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Text(showingMenuConfirmation ? "LEAVE RUN?" : "PAUSED")
                        .font(GameStyle.displayFont)
                        .foregroundStyle(GameStyle.cream)
                    Spacer()
                    Button(action: onClose) {
                        Image("DeliverWhileHotCloseButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    }
                    .accessibilityIdentifier("pause.close")
                    .accessibilityLabel("Close pause menu")
                }

                if showingMenuConfirmation {
                    Text("Leave this run? Your current progress will be lost.")
                        .font(GameStyle.bodyFont)
                        .foregroundStyle(.white.opacity(0.86))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        pauseButton(title: "CANCEL", identifier: "pause.cancel") {
                            showingMenuConfirmation = false
                        }
                        pauseButton(title: "LEAVE", identifier: "pause.confirmLeave", action: onReturnToMenu)
                    }
                } else {
                    pauseButton(title: "RESUME", identifier: "pause.resume", action: onResume)
                    pauseButton(title: "MAIN MENU", identifier: "pause.mainMenu") {
                        showingMenuConfirmation = true
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.45), radius: 24, y: 12)
        }
        .accessibilityIdentifier("pause.overlay")
    }

    private func pauseButton(title: String,
                             identifier: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(GameStyle.secondaryButtonFont)
                .foregroundStyle(GameStyle.cream)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(GameStyle.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityIdentifier(identifier)
    }
}
