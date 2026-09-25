//
//  GameStyle.swift
//  DeliverWhileHot
//

import SwiftUI

enum GameStyle {
    static let accent = Color(red: 1.0, green: 0.32, blue: 0.08)
    static let panel = Color.black.opacity(0.78)
    static let displayFont = Font.system(size: 24, weight: .black, design: .rounded)
    static let buttonFont = Font.system(size: 16, weight: .black, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
}

struct GameMenuButtonStyle: ButtonStyle {
    var filled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GameStyle.buttonFont)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                filled ? GameStyle.accent : GameStyle.panel,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        filled ? .white.opacity(0.25) : .white.opacity(0.7),
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
