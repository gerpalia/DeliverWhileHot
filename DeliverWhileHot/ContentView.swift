//
//  ContentView.swift
//  DeliverWhileHot
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene = GameScene()
    @State private var gameState = GameState()
    @State private var endReason: GameEndReason?
    @State private var sceneID = UUID()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
                    .id(sceneID)

                VStack {
                    GameHUDView(state: gameState) {
                        scene.consumeFood()
                    }
                    Spacer()
                }

                if let endReason {
                    EndingView(reason: endReason) {
                        startGame(in: geometry.size)
                    }
                }
            }
            .onAppear {
                startGame(in: geometry.size)
            }
        }
    }

    private func startGame(in size: CGSize) {
        gameState = GameState()
        endReason = nil
        scene = GameScene()
        sceneID = UUID()
        scene.configure(for: size,
                        onStateChanged: { state in
                            gameState = state
                        },
                        onFinished: { reason in
                            endReason = reason
                        })
    }
}
