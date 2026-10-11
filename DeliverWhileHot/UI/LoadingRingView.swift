//
//  LoadingRingView.swift
//  DeliverWhileHot
//

import SwiftUI

struct LoadingRingView: View {
    var size: CGFloat = 84

    var body: some View {
        Image("DeliverWhileHotLoadingRing")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .modifier(ContinuousLoadingRotation())
            .accessibilityLabel("Loading")
    }
}

private struct ContinuousLoadingRotation: ViewModifier {
    @State private var isRotating = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
            }
    }
}

struct LoadingTransitionView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            LoadingRingView(size: 92)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Loading game")
    }
}
