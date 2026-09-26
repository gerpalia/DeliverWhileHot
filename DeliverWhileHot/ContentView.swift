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
    @StateObject private var stageMusic = BackgroundMusicPlayer()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
                    .id(sceneID)

                VStack {
                    GameHUDView(state: gameState)
                    Spacer()
                    if endReason == nil {
                        GameControlsView(
                            canEat: !scene.isEating &&
                                gameState.health < GameState.maximumHealth &&
                                gameState.foodRemaining >= GameRules.foodCostPerMeal,
                            onMove: { vector in
                                scene.setPlayerInput(horizontal: vector.dx, vertical: vector.dy)
                            },
                            onEat: { scene.consumeFood() }
                        )
                    }
                }

                if let endReason {
                    EndingView(reason: endReason) {
                        startGame(in: geometry.size)
                    }
                }
            }
            .onAppear {
                stageMusic.play(resourceName: "kulakovka-epic-beat-278463.mp3", volume: 0.22)
                startGame(in: geometry.size)
            }
            .onDisappear {
                stageMusic.stop()
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
