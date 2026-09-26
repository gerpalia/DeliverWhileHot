//
//  BackgroundMusicPlayer.swift
//  DeliverWhileHot
//

import AVFoundation
import Combine

final class BackgroundMusicPlayer: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    private var currentResourceName: String?

    func play(resourceName: String, volume: Float) {
        guard currentResourceName != resourceName || player == nil else {
            player?.volume = volume
            if player?.isPlaying == false {
                player?.play()
            }
            return
        }

        stop()

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: nil) else {
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, options: [.mixWithOthers])
            try audioSession.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = volume
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
            currentResourceName = resourceName
        } catch {
            player = nil
            currentResourceName = nil
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentResourceName = nil
    }

    deinit {
        player?.stop()
    }
}
