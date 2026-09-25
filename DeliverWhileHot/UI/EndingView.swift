//
//  EndingView.swift
//  DeliverWhileHot
//

import SwiftUI

struct EndingView: View {
    let reason: GameEndReason
    let onRestart: () -> Void

    private var title: String {
        switch reason {
        case .delivered: return String(localized: "ending.delivered.title")
        case .healthDepleted: return String(localized: "ending.health_depleted.title")
        case .foodTooCold: return String(localized: "ending.food_too_cold.title")
        case .insufficientFood: return String(localized: "ending.insufficient_food.title")
        }
    }

    private var message: String {
        switch reason {
        case .delivered: return String(localized: "ending.delivered.message")
        case .healthDepleted: return String(localized: "ending.health_depleted.message")
        case .foodTooCold: return String(localized: "ending.food_too_cold.message")
        case .insufficientFood: return String(localized: "ending.insufficient_food.message")
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(GameStyle.displayFont)
                .multilineTextAlignment(.center)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(GameStyle.bodyFont)
            Button("common.restart", action: onRestart)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 20)
        .tint(GameStyle.accent)
    }
}
