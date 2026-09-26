//
//  ContentView.swift
//  DeliverWhileHot
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
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
                    GameHUDView(state: gameState,
                                molotovCount: scene.availableMolotovs)
                    Spacer()
                    if endReason == nil {
                        GameControlsView(
                            canEat: scene.canEat,
                            eatCooldownProgress: scene.eatCooldownProgress,
                            canThrowMolotov: scene.canThrowMolotov,
                            molotovCooldownProgress: scene.molotovCooldownProgress,
                            onMove: { vector in
                                scene.setPlayerInput(horizontal: vector.dx, vertical: vector.dy)
                            },
                            onEat: { scene.consumeFood() },
                            onThrowMolotov: { scene.throwMolotov() },
                            onBlockChanged: { isBlocking in
                                scene.setBlocking(isBlocking)
                            }
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
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    stageMusic.play(resourceName: "kulakovka-epic-beat-278463.mp3", volume: 0.22)
                } else {
                    stageMusic.stop()
                }
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
