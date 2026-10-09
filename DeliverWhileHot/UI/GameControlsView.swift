//
//  GameControlsView.swift
//  DeliverWhileHot
//

import SwiftUI

struct GameControlsView: View {
    let canEat: Bool
    let eatCooldownProgress: CGFloat
    let canThrowMolotov: Bool
    let molotovCooldownProgress: CGFloat
    let onMove: (CGVector) -> Void
    let onEat: () -> Void
    let onThrowMolotov: () -> Void
    let onBlockChanged: (Bool) -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            VirtualJoystick(onMove: onMove)

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    CommandButton(title: "controls.eat",
                                  symbol: "takeoutbag.and.cup.and.straw",
                                  isEnabled: canEat,
                                  action: onEat,
                                  imageName: "DeliverWhileHotEatingIcon",
                                  cooldownProgress: eatCooldownProgress,
                                  identifier: "controls.eat")
                    CommandButton(title: "controls.block",
                                  symbol: "shield.fill",
                                  isEnabled: true,
                                  action: {},
                                  imageName: "DeliverWhileHotBlockIcon",
                                  onPressChanged: onBlockChanged,
                                  identifier: "controls.block")
                }
                HStack(spacing: 8) {
                    CommandButton(title: "controls.molotov",
                                  symbol: "flame.fill",
                                  isEnabled: canThrowMolotov,
                                  action: onThrowMolotov,
                                  imageName: "DeliverWhileHotMolotovActionIcon",
                                  cooldownProgress: molotovCooldownProgress,
                                  identifier: "controls.molotov")
                    CommandButton(title: "controls.item", symbol: "backpack.fill", isEnabled: false, action: {}, identifier: "controls.item")
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
            .accessibilityIdentifier("controls.joystick")
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
    var imageName: String? = nil
    var cooldownProgress: CGFloat = 1
    var onPressChanged: ((Bool) -> Void)? = nil
    var identifier: String
    @State private var showReadyShimmer = false

    var body: some View {
        Button(action: action) {
            Group {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(imageName == "DeliverWhileHotMolotovActionIcon" ? 4 : 6)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 25, weight: .semibold))
                }
            }
            .frame(width: 58, height: 58)
            .background(.black.opacity(isEnabled ? 0.72 : 0.35), in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(isEnabled ? 0.55 : 0.2), lineWidth: 1)
            }
            .clipShape(Circle())
            .overlay {
                CooldownShadeShape(progress: cooldownProgress)
                    .fill(.black.opacity(0.64))
                .clipShape(Circle())
            }
            .overlay {
                Circle()
                    .stroke(GameStyle.accent.opacity(showReadyShimmer ? 0.72 : 0), lineWidth: 2)
                    .scaleEffect(showReadyShimmer ? 1.08 : 1)
                    .blur(radius: showReadyShimmer ? 0.4 : 0)
                    .animation(.easeOut(duration: 0.28), value: showReadyShimmer)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPressChanged?(true) }
                .onEnded { _ in onPressChanged?(false) },
            including: onPressChanged == nil ? .subviews : .all
        )
        .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.35))
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
        .disabled(!isEnabled)
        .onChange(of: cooldownProgress) { oldValue, newValue in
            guard oldValue < 0.999, newValue >= 0.999 else { return }
            showReadyShimmer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                showReadyShimmer = false
            }
        }
    }
}

private struct CooldownShadeShape: Shape {
    var progress: CGFloat

    func path(in rect: CGRect) -> Path {
        let clampedProgress = max(0, min(1, progress))
        if clampedProgress <= 0 { return Path(ellipseIn: rect) }
        if clampedProgress >= 1 { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) * 0.8
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle - (1 - clampedProgress) * CGFloat.pi * 2
        let shadeStartPoint = CGPoint(x: center.x + cos(endAngle) * radius,
                                      y: center.y + sin(endAngle) * radius)

        var path = Path()
        path.move(to: center)
        path.addLine(to: shadeStartPoint)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: Angle(radians: Double(endAngle)),
                    endAngle: Angle(radians: Double(startAngle)),
                    clockwise: false)
        path.closeSubpath()
        return path
    }
}
