import SwiftUI

enum EndingPromptStep: Equatable {
    case prepare
    case jump

    var title: String {
        switch self {
        case .prepare: String(localized: "ending.prompt.prepare")
        case .jump: String(localized: "ending.prompt.jump")
        }
    }

    var instruction: String {
        switch self {
        case .prepare: String(localized: "ending.prompt.prepare_hint")
        case .jump: String(localized: "ending.prompt.jump_hint")
        }
    }
}

struct EndingPromptView: View {
    let step: EndingPromptStep
    let progress: CGFloat
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("ending.prompt.title")
                .font(GameStyle.displayFont)
                .foregroundStyle(Color.white.opacity(0.94))
                .multilineTextAlignment(.center)

            Button(action: onTap) {
                ZStack {
                    timingRing
                        .frame(width: 158, height: 158)

                    Circle()
                        .fill(Color(red: 0.19, green: 0.17, blue: 0.16))
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.65), lineWidth: 2)
                        }
                        .frame(width: 118, height: 118)
                        .overlay {
                            Text(step.title)
                                .font(GameStyle.displayFont)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.96, green: 0.88, blue: 0.72))
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.52)
                                .padding(.horizontal, 9)
                        }
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step.title)
            .accessibilityHint(step.instruction)

            Text(step.instruction)
                .font(GameStyle.bodyFont)
                .foregroundStyle(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(Color.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.55), radius: 24, y: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: 118)
        .background(Color.black.opacity(0.18).ignoresSafeArea())
    }

    private var timingRing: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.20), lineWidth: 8)

            Circle()
                .trim(from: 0, to: 0.08)
                .stroke(Color(red: 0.98, green: 0.72, blue: 0.32),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .trim(from: 0.92, to: 1)
                .stroke(Color(red: 0.98, green: 0.72, blue: 0.32),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Capsule()
                .fill(Color.white)
                .frame(width: 4, height: 17)
                .offset(y: -69)
                .rotationEffect(.degrees(progress * 360))
                .shadow(color: .white.opacity(0.7), radius: 5)
        }
        .accessibilityHidden(true)
    }
}
