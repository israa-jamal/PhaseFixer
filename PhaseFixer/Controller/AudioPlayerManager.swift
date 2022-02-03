//
//  AudioPlayerManager.swift
//  PhaseFixer
//
//  Created by Esraa Gamal on 02/02/2022.
//

import Foundation
import AVFoundation

class AudioPlayerManager {
    let micAudioPlayer: AudioPlayer
    let wifiAudioPlayer: AudioPlayer
    var micTimer : Timer?
    var wifiTimer : Timer?
    var isReset = true

    init(firstTrackURl: URL, secondTrackURl: URL) {
        micAudioPlayer = AudioPlayer(trackURL: firstTrackURl)
        wifiAudioPlayer = AudioPlayer(trackURL: secondTrackURl)
    }
    
    func startPlaying(with buffer: Double) {
//        if isReset {
            stopAudios()
            startSynchronizedPlayback(with: buffer)
//            isReset = false
//        } else {
//            resume()
//        }
    }
    
    func resume() {
        let timeOffset = micAudioPlayer.audioPlayer.deviceCurrentTime + 0.01
//        micAudioPlayer.playAudio(time: timeOffset)
//        wifiAudioPlayer.playAudio(time: timeOffset)
    }
    
    func pauseAudios() {
//        micAudioPlayer.pauseAudios()
//        wifiAudioPlayer.pauseAudios()
        stopAudios()
    }
    
    func stopAudios() {
        micAudioPlayer.resetAudios()
        wifiAudioPlayer.resetAudios()
        isReset = true
    }
    
    func changeVolume(micValue: Float, wifiValue: Float) {
        micAudioPlayer.volume = micValue
        wifiAudioPlayer.volume = wifiValue
//        print("orignal:", micValue, "phased:", wifiValue)
    }
    
    func startSynchronizedPlayback(with buffer: Double) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        
        let timeOffset = micAudioPlayer.audioPlayer.deviceCurrentTime + 0.1

        wifiAudioPlayer.playAudio(time: timeOffset, timer: 0.1)
        micAudioPlayer.playAudio(time: timeOffset + buffer, timer: 0.1 + buffer)
    }
}

