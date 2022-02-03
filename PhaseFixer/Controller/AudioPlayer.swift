//
//  AudioPlayer.swift
//  PhaseFixer
//
//  Created by Esraa Gamal on 01/02/2022.
//

import Foundation
import AVFoundation

protocol AudioPlayerProtocol : AnyObject {
    func updateView(currentTime: CMTime)
}

class AudioPlayer {
    
    var audioPlayer: AVAudioPlayer!

    var duration: CMTime
    var volume : Float = 0.5 {
        didSet {
            self.audioPlayer?.volume = volume
        }
    }
    var timer: Timer?
    var currentPlaybackTime: CMTime

    weak var delegate: AudioPlayerProtocol?
    
    init(trackURL: URL) {
        duration = CMTime(seconds: 0, preferredTimescale: 1000000)
        currentPlaybackTime = CMTime(seconds: 0, preferredTimescale: 1000000)

        do {
            let data = try Data(contentsOf: trackURL)
            self.audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
            duration = AVURLAsset.init(url: trackURL, options: nil).duration
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
    }
    
    func playAudio(time: TimeInterval, timer: Double) {
        self.audioPlayer?.prepareToPlay()
        self.audioPlayer?.volume = volume
        audioPlayer.play(atTime: time)
        DispatchQueue.main.asyncAfter(deadline: .now() + timer) {
            self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.drawProgress), userInfo: nil, repeats: true)
        }
    }
    
    @objc func drawProgress() {
        self.currentPlaybackTime = CMTime(seconds: audioPlayer.currentTime, preferredTimescale: 1000000)
        if currentPlaybackTime < duration {
            delegate?.updateView(currentTime: currentPlaybackTime)
        } else {
            
            timer?.invalidate()
        }
    }
    
    func resetAudios() {
        pauseAudios()
        self.currentPlaybackTime = CMTime(seconds: 0, preferredTimescale: 1000000)
        delegate?.updateView(currentTime: currentPlaybackTime)
        audioPlayer?.currentTime = 0
    }
    
    func pauseAudios() {
        audioPlayer?.stop()
        timer?.invalidate()
    }
}

