//
//  ViewController.swift
//  PhaseFixer
//
//  Created by Esraa Gamal on 20/01/2022.
//

import UIKit
import Accelerate

class ViewController: UIViewController {
    
    @IBOutlet weak var stackView : UIStackView!
    @IBOutlet weak var playButton : UIButton!
    
    let viewModel = PhaseViewModel(.rushingWater, .rushingWaterRecorded)
    
    var waveform : WaveForm?
    var secondWaveform : WaveForm?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    //MARK:- Setup UI
    
    func configureUI() {
        configureWaveForm()
    }
    
    @IBAction func trackSliderValueChanged(_ sender: UISlider) {
        let value = sender.value
        
        viewModel.audioPlayerManager.changeVolume(micValue: 1 - value, wifiValue: value)
    }
    
    func configureWaveForm() {
        let rushingWaterURL = Bundle.main.url(forResource: TestCase.rushingWater.rawValue, withExtension: "m4a")!
        let rushingWaterPhasedURL = Bundle.main.url(forResource: TestCase.rushingWaterPhased.rawValue, withExtension: "m4a")!
        do {
            
            waveform = try WaveForm(audioURL: rushingWaterURL,
                                    sampleCount: viewModel.sampleRate,
                                    amplificationFactor: 450, audioPlayer: self.viewModel.audioPlayerManager.micAudioPlayer)
            secondWaveform = try WaveForm(audioURL: rushingWaterPhasedURL,
                                          sampleCount: viewModel.sampleRate,
                                          amplificationFactor: 450, audioPlayer: self.viewModel.audioPlayerManager.wifiAudioPlayer)
            waveform?.normalColor = #colorLiteral(red: 0.3882352941, green: 0.5019607843, blue: 0.6509803922, alpha: 1)
            waveform?.progressColor = #colorLiteral(red: 0.5411764706, green: 0.231372549, blue: 0.7490196078, alpha: 1)
            waveform?.backgroundColor = #colorLiteral(red: 0.1803921569, green: 0.2039215686, blue: 0.2509803922, alpha: 1)
            waveform?.allowSpacing = false
            
            secondWaveform?.normalColor = #colorLiteral(red: 0.3882352941, green: 0.5019607843, blue: 0.6509803922, alpha: 1)
            secondWaveform?.progressColor = #colorLiteral(red: 0.5411764706, green: 0.231372549, blue: 0.7490196078, alpha: 1)
            secondWaveform?.backgroundColor = #colorLiteral(red: 0.1803921569, green: 0.2039215686, blue: 0.2509803922, alpha: 1)
            secondWaveform?.allowSpacing = false
            
            stackView.insertArrangedSubview(waveform ?? UIView(), at: 1)
            stackView.addArrangedSubview(secondWaveform ?? UIView())
            
            //ASWaveformPlayerView supports both manual and AutoLayout
            waveform?.translatesAutoresizingMaskIntoConstraints = false
            waveform?.heightAnchor.constraint(equalToConstant: 120).isActive = true
            
            secondWaveform?.translatesAutoresizingMaskIntoConstraints = false
            secondWaveform?.heightAnchor.constraint(equalToConstant: 120).isActive = true
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //MARK:- Actions
    
    @IBAction func play(_ sender: UIButton) {
        if viewModel.isPlaying {
            UIView.animate(withDuration: 0.5) {
                self.playButton.setImage(UIImage(named: "play"), for: .normal)
                self.playButton.tintColor = #colorLiteral(red: 0.4745098039, green: 0.2156862745, blue: 0.6509803922, alpha: 1)
            }
            viewModel.pauseAudio()
        } else {
            UIView.animate(withDuration: 0.5) {
                self.playButton.setImage(UIImage(named: "stop"), for: .normal)
                self.playButton.tintColor = #colorLiteral(red: 0.2980392157, green: 0.1490196078, blue: 0.4509803922, alpha: 1)
            }
            viewModel.playAudio()
        }
    }
    
    @IBAction func playInPhase(_ sender: UIButton) {
        viewModel.playAudio(value: 0)
        //        resetAudios()
        //        startSynchronizedPlayback(with: 0)
    }
}

