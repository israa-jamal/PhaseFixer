//
//  ViewController.swift
//  PhaseFixer
//
//  Created by Esraa Gamal on 20/01/2022.
//

import UIKit
import DSWaveformImage
import AVFoundation
import Accelerate

class ViewController: UIViewController {
  
    @IBOutlet weak var rushingWaterSoundView : WaveformImageView!
    @IBOutlet weak var rushingWaterPhasedSoundView : WaveformImageView!

    let viewModel = PhaseViewModel()

    private var audioPlayer: AVAudioPlayer?
    private var audioPlayer2: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        configureUI()
        viewModel.playAudio(.rushingWater, .rushingWaterPhased)
    }
    
    //MARK:- Setup UI
    
    func configureUI() {
        rushingWaterSoundView.layer.cornerRadius = 4
        rushingWaterPhasedSoundView.layer.cornerRadius = 4
        rushingWaterSoundView.configuration = Waveform.Configuration(style: .filled(#colorLiteral(red: 0.3019607843, green: 0.6392156863, blue: 1, alpha: 1)))
        rushingWaterPhasedSoundView.configuration = Waveform.Configuration(style: .filled(#colorLiteral(red: 0.3019607843, green: 0.6392156863, blue: 1, alpha: 1)))
        configureWaveForm()
    }
    
    func configureWaveForm() {
        let rushingWaterURL = Bundle.main.url(forResource: TestCase.rushingWater.rawValue, withExtension: "m4a")!
        let rushingWaterPhasedURL = Bundle.main.url(forResource: TestCase.rushingWaterPhased.rawValue, withExtension: "m4a")!
        
        rushingWaterSoundView.waveformAudioURL = rushingWaterURL
        rushingWaterPhasedSoundView.waveformAudioURL = rushingWaterPhasedURL
    }
    
    //MARK:- Actions
    
    @IBAction func play(_ sender: UIButton) {
        resetAudios()
        startSynchronizedPlayback(with: viewModel.buffer)
    }
    
    @IBAction func stop(_ sender: UIButton) {
        resetAudios()
    }
    
    @IBAction func playInPhase(_ sender: UIButton) {
        resetAudios()
        startSynchronizedPlayback(with: 0)
    }
    
 //MARK:- Helpers
    
    func resetAudios() {
        audioPlayer?.stop()
        audioPlayer2?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer2?.currentTime = 0
    }
}

//MARK:- Playing Audio

extension ViewController : AudioViewModelProtocol{

    func playAudios(_ firstTrackURl: URL, _ secondTrackURl: URL, _ buffer: Double) {
        do {
            let data = try Data(contentsOf: firstTrackURl)
            let data2 = try Data(contentsOf: secondTrackURl)
            
            self.audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
            self.audioPlayer2 = try AVAudioPlayer(data: data2, fileTypeHint: AVFileType.caf.rawValue)
            
            startSynchronizedPlayback(with: buffer)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
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
       
        let timeOffset = audioPlayer2?.deviceCurrentTime ?? 0.0 + 0.1
        
        self.audioPlayer?.prepareToPlay()
        self.audioPlayer2?.prepareToPlay()
        self.audioPlayer?.volume = 0.5
        self.audioPlayer2?.volume = 0.5
        
        audioPlayer2?.play(atTime: timeOffset)
        audioPlayer?.play(atTime: timeOffset + buffer)
    }
    
    //TODO
    func updateProgressWaveform(_ progress: Double) {
        let fullRect = rushingWaterSoundView.bounds
        let newWidth = Double(fullRect.size.width) * progress
        
        let maskLayer = CAShapeLayer()
        let maskRect = CGRect(x: 0.0, y: 0.0, width: newWidth, height: Double(fullRect.size.height))
        
        let path = CGPath(rect: maskRect, transform: nil)
        maskLayer.path = path
        
        rushingWaterSoundView.layer.mask = maskLayer
    }
}
