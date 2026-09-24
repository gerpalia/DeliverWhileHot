//
//  GameHUDView.swift
//  DeliverWhileHot
//

import SwiftUI

struct GameHUDView: View {
    let state: GameState
    let onEatFood: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(String(repeating: "♥ ", count: state.health).trimmingCharacters(in: .whitespaces))
                    .foregroundStyle(.red)
                    .font(.title3.weight(.bold))

                Spacer()

                Button("EAT 🍕", action: onEatFood)
                    .font(.caption.weight(.bold))
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(state.health >= GameState.maximumHealth ||
                              state.foodRemaining < GameRules.foodCostPerMeal)
            }

            HStack(spacing: 8) {
                Text("❄️")
                TemperatureBar(value: state.foodTemperature)
                Text("🔥")
            }

            HStack(spacing: 4) {
                Text("ORDER")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
                ForEach(0..<4, id: \.self) { index in
                    Text("🍕")
                        .opacity(state.foodRemaining >= Double(index + 1) / 4 ? 1 : 0.22)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .background(.black.opacity(0.55))
        .foregroundStyle(.white)
    }
}

private struct TemperatureBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule().fill(.white.opacity(0.28))
                HStack(spacing: 0) {
                    Capsule()
                        .fill(temperatureColor)
                        .frame(width: geometry.size.width * value)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: 10)
    }

    private var temperatureColor: Color {
        Color(red: 1, green: 1 - value, blue: 1 - value)
    }
}
