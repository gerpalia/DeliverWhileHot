//
//  ContentView.swift
//  DeliverWhileHot
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    let onReturnToMenu: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var scene = GameScene()
    @State private var gameState = GameState()
    @State private var endReason: GameEndReason?
    @State private var endingSequenceStarted = false
    @State private var endingPromptStep: EndingPromptStep?
    @State private var endingPromptProgress: CGFloat = 0.5
    @State private var isPaused = false
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
                    if endReason == nil && !endingSequenceStarted {
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

                if endReason == nil && !endingSequenceStarted {
                    PauseHandleView(action: pauseGame)
                        .padding(.top, geometry.safeAreaInsets.top + 154)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .zIndex(5)
                }

                if let endingPromptStep {
                    EndingPromptView(step: endingPromptStep,
                                     progress: endingPromptProgress,
                                     onTap: { scene.submitEndingPromptTap() })
                    .transition(.opacity)
                }

                if isPaused && endReason == nil && !endingSequenceStarted {
                    PauseOverlayView(
                        onClose: resumeGame,
                        onResume: resumeGame,
                        onReturnToMenu: leaveToMenu
                    )
                    .transition(.opacity)
                    .zIndex(20)
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
        endingSequenceStarted = false
        endingPromptStep = nil
        endingPromptProgress = 0.5
        isPaused = false
        scene = GameScene()
        sceneID = UUID()
        scene.configure(for: size,
                        onStateChanged: { state in
                            gameState = state
                        },
                        onFinished: { reason in
                            endReason = reason
                        },
                        onEndingPromptChanged: { step, progress in
                            if step != nil {
                                endingSequenceStarted = true
                            }
                            endingPromptStep = step
                            endingPromptProgress = progress
                        })
    }

    private func pauseGame() {
        guard endReason == nil, !endingSequenceStarted, !isPaused else { return }
        scene.pauseRun()
        isPaused = true
    }

    private func resumeGame() {
        scene.resumeRun()
        isPaused = false
    }

    private func leaveToMenu() {
        scene.resumeRun()
        isPaused = false
        onReturnToMenu()
    }
}
