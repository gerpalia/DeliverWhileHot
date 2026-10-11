//
//  PauseHandleView.swift
//  DeliverWhileHot
//

import SwiftUI

struct PauseHandleView: View {
    let action: () -> Void
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        Button(action: action) {
            Image(systemName: "pause.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 42)
                .background(.black.opacity(0.68), in: UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: 14,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                ))
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14,
                        bottomLeadingRadius: 14,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                    .stroke(.white.opacity(0.28), lineWidth: 1)
                }
        }
        .offset(x: 10 + dragOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    dragOffset = max(-30, min(0, value.translation.width))
                }
                .onEnded { value in
                    if value.translation.width < -20 {
                        action()
                    }
                    withAnimation(.easeOut(duration: 0.16)) {
                        dragOffset = 0
                    }
                }
        )
        .accessibilityIdentifier("game.pause")
        .accessibilityLabel("Pause game")
    }
}
