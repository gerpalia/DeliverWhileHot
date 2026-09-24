//
//  GameHUDView.swift
//  DeliverWhileHot
//

import SwiftUI

struct GameHUDView: View {
    let state: GameState

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(String(repeating: "♥ ", count: state.health).trimmingCharacters(in: .whitespaces))
                    .foregroundStyle(.red)
                    .font(.headline.weight(.bold))

                Spacer()

                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { index in
                        let isAvailable = state.foodRemaining >= Double(index + 1) / 4
                        Text("🍕")
                            .opacity(isAvailable ? 1 : 0.18)
                            .blur(radius: isAvailable ? 0 : 2)
                    }
                }
            }

            HStack(spacing: 8) {
                Text("❄️")
                TemperatureBar(value: state.foodTemperature)
                Text("🔥")
            }

        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .padding(.bottom, 6)
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
