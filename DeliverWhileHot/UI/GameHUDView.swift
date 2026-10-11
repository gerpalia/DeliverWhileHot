//
//  GameHUDView.swift
//  DeliverWhileHot
//

import SwiftUI

struct GameHUDView: View {
    let state: GameState
    let molotovCount: Int

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 7) {
                StatCapsule {
                    HStack(spacing: 6) {
                        ForEach(0..<GameState.maximumHealth, id: \.self) { index in
                            Image(systemName: "heart.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(index < state.health ? Color(red: 0.88, green: 0.24, blue: 0.22) : .white.opacity(0.22))
                                .frame(width: 20, height: 22)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Health: \(state.health) of \(GameState.maximumHealth)")
                }

                StatCapsule {
                    HStack(spacing: 5) {
                        ForEach(0..<4, id: \.self) { index in
                            let isAvailable = state.foodRemaining >= Double(index + 1) / 4
                            Image("DeliverWhileHotPizzaSliceIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 19, height: 22)
                                .opacity(isAvailable ? 1 : 0.20)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Food: \(Int((state.foodRemaining * 4).rounded(.down))) of 4 slices")
                }

                StatCapsule {
                    HStack(spacing: 2) {
                        ForEach(0..<GameConstants.maximumMolotovCount, id: \.self) { index in
                            Image(index < molotovCount
                                  ? "DeliverWhileHotMolotovReady"
                                  : "DeliverWhileHotMolotovEmpty")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17, height: 24)
                                .opacity(index < molotovCount ? 1 : 0.52)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Molotovs: \(molotovCount) of \(GameConstants.maximumMolotovCount)")
                }
            }

            TemperatureBar(value: state.foodTemperature)
                .padding(.horizontal, 1)
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 7)
        .background(.black.opacity(0.48))
        .foregroundStyle(.white)
    }

    private struct StatCapsule<Content: View>: View {
        @ViewBuilder let content: () -> Content

        var body: some View {
            content()
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .padding(.horizontal, 5)
                .background(
                    LinearGradient(colors: [
                        Color(red: 0.20, green: 0.22, blue: 0.27),
                        Color(red: 0.12, green: 0.14, blue: 0.18)
                    ], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.19), lineWidth: 1)
                }
        }
    }

    private struct TemperatureBar: View {
        let value: Double

        private var progress: CGFloat {
            CGFloat(max(0, min(1, value)))
        }

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.20, green: 0.22, blue: 0.27))

                    Capsule()
                        .fill(LinearGradient(colors: [
                            Color(red: 0.72, green: 0.34, blue: 0.19),
                            Color(red: 0.96, green: 0.24, blue: 0.18)
                        ], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geometry.size.width * progress))

                    HStack {
                        temperatureIcon(
                            symbol: "snowflake",
                            tint: Color(red: 0.72, green: 0.88, blue: 0.96)
                        )
                        Spacer(minLength: 0)
                        temperatureIcon(
                            symbol: "flame.fill",
                            tint: Color(red: 1.0, green: 0.66, blue: 0.28)
                        )
                    }
                    .padding(.horizontal, 3)
                }
                .overlay {
                    Capsule().stroke(.white.opacity(0.20), lineWidth: 1)
                }
                .clipShape(Capsule())
            }
            .frame(height: 24)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Food temperature")
            .accessibilityValue("\(Int(progress * 100)) percent")
        }

        private func temperatureIcon(symbol: String, tint: Color) -> some View {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 21, height: 21)
                .background(tint.opacity(0.16), in: Circle())
                .overlay {
                    Circle().stroke(tint.opacity(0.48), lineWidth: 0.8)
                }
                .shadow(color: tint.opacity(0.25), radius: 2)
        }
    }

}
