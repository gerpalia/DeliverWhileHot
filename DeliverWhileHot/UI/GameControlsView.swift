//
//  GameControlsView.swift
//  DeliverWhileHot
//

import SwiftUI

struct GameControlsView: View {
    let canEat: Bool
    let canThrowMolotov: Bool
    let onMove: (CGVector) -> Void
    let onEat: () -> Void
    let onThrowMolotov: () -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            VirtualJoystick(onMove: onMove)

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    CommandButton(title: "controls.eat", symbol: "🍕", isEnabled: canEat, action: onEat)
                    CommandButton(title: "controls.block", symbol: "🛡️", isEnabled: false, action: {})
                }
                HStack(spacing: 8) {
                    CommandButton(title: "controls.molotov", symbol: "🔥", isEnabled: canThrowMolotov, action: onThrowMolotov)
                    CommandButton(title: "controls.item", symbol: "🎒", isEnabled: false, action: {})
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct VirtualJoystick: View {
    let onMove: (CGVector) -> Void
    @State private var knobOffset: CGSize = .zero

    private let baseDiameter: CGFloat = 104
    private let knobDiameter: CGFloat = 46
    private let deadZone: CGFloat = 0.12

    private var maximumOffset: CGFloat {
        (baseDiameter - knobDiameter) / 2
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(.black.opacity(0.62))
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.55), lineWidth: 2)
                    }

                Circle()
                    .fill(GameStyle.accent.opacity(0.9))
                    .frame(width: knobDiameter, height: knobDiameter)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.75), lineWidth: 2)
                    }
                    .offset(knobOffset)
            }
            .frame(width: baseDiameter, height: baseDiameter)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateInput(for: value.location, in: geometry.size)
                    }
                    .onEnded { _ in
                        resetInput()
                    }
            )
            .accessibilityLabel("Virtual joystick")
            .accessibilityHint("Drag in any direction to move")
        }
        .frame(width: baseDiameter, height: baseDiameter)
    }

    private func updateInput(for location: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let rawOffset = CGSize(width: location.x - center.x,
                               height: location.y - center.y)
        let distance = hypot(rawOffset.width, rawOffset.height)
        let scale = distance > maximumOffset ? maximumOffset / distance : 1
        let clampedOffset = CGSize(width: rawOffset.width * scale,
                                   height: rawOffset.height * scale)

        knobOffset = clampedOffset

        guard distance > maximumOffset * deadZone else {
            onMove(CGVector.zero)
            return
        }

        let horizontal = clampedOffset.width / maximumOffset
        let vertical = -clampedOffset.height / maximumOffset
        onMove(CGVector(dx: horizontal, dy: vertical))
    }

    private func resetInput() {
        withAnimation(.easeOut(duration: 0.12)) {
            knobOffset = .zero
        }
        onMove(CGVector.zero)
    }
}

private struct CommandButton: View {
    let title: LocalizedStringKey
    let symbol: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(symbol)
                Text(title)
                    .font(.caption2.weight(.bold))
            }
            .frame(width: 62, height: 48)
            .background(.black.opacity(isEnabled ? 0.72 : 0.35), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(isEnabled ? 0.55 : 0.2), lineWidth: 1)
            }
        }
        .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.35))
        .disabled(!isEnabled)
    }
}
