//
//  ContentView.swift
//  DeliverWhileHot
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    private let scene = GameScene()

    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                .onAppear {
                    scene.configure(for: geometry.size)
                }
                .overlay(alignment: .top) {
                    Text("DRAG LEFT OR RIGHT TO STEER")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(.top, 18)
                }
        }
    }
}
