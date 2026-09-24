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
        case .delivered: return "DELIVERY COMPLETE"
        case .healthDepleted: return "RIDER DOWN"
        case .foodTooCold: return "TOO COLD"
        case .insufficientFood: return "ORDER TOO SMALL"
        }
    }

    private var message: String {
        switch reason {
        case .delivered: return "You made it with an acceptable order."
        case .healthDepleted: return "The neighborhood won this round."
        case .foodTooCold: return "The order lost too much heat on the way."
        case .insufficientFood: return "You ate too much of the delivery."
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(title).font(.title.bold())
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("RESTART", action: onRestart)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 20)
    }
}
