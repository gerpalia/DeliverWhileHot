//
//  GameStyle.swift
//  DeliverWhileHot
//

import SwiftUI

enum GameStyle {
    static let accent = Color(red: 1.0, green: 0.22, blue: 0.08)
    static let panel = Color.black.opacity(0.78)
    static let cream = Color(red: 0.94, green: 0.87, blue: 0.72)
    static let displayFont = Font.custom("NewRocker-Regular", size: 24)
    static let primaryButtonFont = Font.custom("SpecialElite-Regular", size: 24)
    static let secondaryButtonFont = Font.custom("SpecialElite-Regular", size: 13)
    static let bodyFont = Font.custom("SyneMono-Regular", size: 17)
    static let secondaryFont = Font.custom("SyneMono-Regular", size: 12)
}

struct GameMenuButtonStyle: ButtonStyle {
    var filled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(GameStyle.cream)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity)
            .frame(height: filled ? 62 : 60)
            .padding(.horizontal, filled ? 22 : 18)
            .background {
                Image(filled ? "DeliverWhileHotMenuButtonPrimary" : "DeliverWhileHotMenuButtonSecondary")
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            }
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
