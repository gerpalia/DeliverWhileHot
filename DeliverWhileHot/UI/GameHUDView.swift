//
//  GameHUDView.swift
//  DeliverWhileHot
//

import SwiftUI

struct GameHUDView: View {
    let state: GameState
    let molotovCount: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                StatCapsule {
                    HStack(spacing: 2) {
                        ForEach(0..<GameState.maximumHealth, id: \.self) { index in
                            Text("♥")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(index < state.health ? .red : .white.opacity(0.22))
                                .frame(width: 24, height: 24)
                        }
                    }
                }

                StatCapsule {
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { index in
                            let isAvailable = state.foodRemaining >= Double(index + 1) / 4
                            Text("🍕")
                                .font(.system(size: 18))
                                .opacity(isAvailable ? 1 : 0.18)
                                .blur(radius: isAvailable ? 0 : 2)
                                .frame(width: 24, height: 24)
                        }
                    }
                }

                StatCapsule {
                    HStack(spacing: 2) {
                        ForEach(0..<GameConstants.maximumMolotovCount, id: \.self) { index in
                            Image(index < molotovCount
                                  ? "DeliverWhileHotMolotovReady"
                                  : "DeliverWhileHotMolotovEmpty")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .opacity(index < molotovCount ? 1 : 0.65)
                        }
                    }
                }
            }

            TemperatureBar(value: state.foodTemperature)

        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .padding(.bottom, 6)
        .background(.black.opacity(0.55))
        .foregroundStyle(.white)
    }
}

private struct StatCapsule<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(
                Color(red: 0.29, green: 0.31, blue: 0.37),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
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

                HStack {
                    Text("❄️")
                    Spacer(minLength: 0)
                    Text("🔥")
                }
                .font(.body)
                .padding(.horizontal, 3)
            }
        }
        .frame(height: 24)
    }

    private var temperatureColor: Color {
        Color(red: 1, green: 1 - value, blue: 1 - value)
    }
}
