//
//  File.swift
//  PhaseFixer
//
//  Created by Esraa Gamal on 1/02/2022.
//

import UIKit
import AVFoundation
import Accelerate

public class WaveForm: UIView, AudioPlayerProtocol {
    func updateView(currentTime: CMTime) {
        self.updatePlotWith(currentTime)
    }
    
    //MARK: Public properties
    public var normalColor = UIColor.lightGray
    
    public var progressColor = UIColor.orange
    
    public var allowSpacing = true
    
    //MARK: Private properties
    
    private var audioAnalyzer = AudioAnalyzer()
    
    private var waveformDataArray = [Float]()
    
    private var waveforms = [CALayer]()
    
    private var shouldAutoUpdateWaveform = true
    
    private var audioPlayer : AudioPlayer
    
    //MARK: Initialization
    init(audioURL: URL,
         sampleCount: Int,
         amplificationFactor: Float, audioPlayer : AudioPlayer) throws {
        self.audioPlayer = audioPlayer
        guard sampleCount > 0 else {
            throw WaveFormViewInitError.incorrectSampleCount
        }
        
        let rawWaveformDataArray = try audioAnalyzer.analyzeAudioFile(url: audioURL)
        let resampledDataArray = audioAnalyzer.resample(rawWaveformDataArray, to: sampleCount)
        waveformDataArray = audioAnalyzer.amplify(resampledDataArray, by: amplificationFactor)
        super.init(frame: .zero)
        audioPlayer.delegate = self
        
        self.updatePlotWith(audioPlayer.currentPlaybackTime)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        audioPlayer = AudioPlayer(trackURL: URL(fileURLWithPath: ""))
        super.init(coder: aDecoder)
    }
    
    deinit {
        
        print("\(self) dealloc")
    }
    
    //MARK: Methods
    override public func layoutSubviews() {
        super.layoutSubviews()
        populateWithData()
        addOverlay()
    }
    
    private func populateWithData() {
        clear()
        
        let barWidth: CGFloat
        
        if allowSpacing {
            barWidth = bounds.width / CGFloat(waveformDataArray.count) - 0.5
        } else {
            barWidth = bounds.width / CGFloat(waveformDataArray.count)
        }
        
        var offset: CGFloat = (bounds.width / CGFloat(waveformDataArray.count)) / 2
        for value in waveformDataArray {
            
            let waveformBarRect = CGRect(x: offset,
                                         y:   bounds.height / 2,
                                         width: barWidth,
                                         height: -CGFloat(value))
            
            let barLayer = CALayer()
            barLayer.drawsAsynchronously = true
            barLayer.bounds = waveformBarRect
            barLayer.position = CGPoint(x: offset + (bounds.width / CGFloat(waveformDataArray.count)) / 2,
                                        y: bounds.height / 2)
            
            barLayer.backgroundColor = self.normalColor.cgColor
            
            self.layer.addSublayer(barLayer)
            self.waveforms.append(barLayer)
            
            offset += self.frame.width / CGFloat(waveformDataArray.count)
            
        }
        
    }
    
    private func updatePlotWith(_ location: Float) {
        
        let percentageInSelf = location / Float(bounds.width)
        
        let waveformsToBeRecolored = Float(waveforms.count) * percentageInSelf
        
        for (idx, item) in waveforms.enumerated() {
            
            if (0..<lrintf(waveformsToBeRecolored)).contains(idx) {
                item.backgroundColor = progressColor.cgColor
            } else {
                item.backgroundColor = normalColor.cgColor
            }
            
        }
        
    }
    
    private func updatePlotWith(_ currentTime: CMTime) {
        
        guard shouldAutoUpdateWaveform == true else {
            return
        }
        
        let totalAudioDuration = audioPlayer.duration
        
        let currentTimeSeconds = CMTimeGetSeconds(currentTime)
                
        let totalAudioDurationSeconds = CMTimeGetSeconds(totalAudioDuration)
        
        let percentagePlayed = currentTimeSeconds / totalAudioDurationSeconds
        
        let waveformBarsToBeUpdated = lrint(Double(waveforms.count) * percentagePlayed)
        
        for (idx, item) in waveforms.enumerated() {
            
            if (0..<waveformBarsToBeUpdated).contains(idx) {
                item.backgroundColor = progressColor.cgColor
            } else {
                item.backgroundColor = normalColor.cgColor
            }
            
        }
    }
    
    private func addOverlay() {
        
        let maskLayer = CALayer()
        maskLayer.frame = bounds
        
        let upperOverlayLayer = CALayer()
        let bottomOverlayLayer = CALayer()
        
        upperOverlayLayer.backgroundColor = UIColor.black.cgColor
        bottomOverlayLayer.backgroundColor = UIColor.black.cgColor
        
        upperOverlayLayer.opacity = 1
        bottomOverlayLayer.opacity = 0.75
        
        maskLayer.addSublayer(upperOverlayLayer)
        maskLayer.addSublayer(bottomOverlayLayer)
        
        upperOverlayLayer.frame = CGRect(origin: .zero,
                                         size: CGSize(width: maskLayer.bounds.width,
                                                      height: (maskLayer.bounds.height / 2) - 0.25))
        
        bottomOverlayLayer.frame = CGRect(origin: CGPoint(x: 0,
                                                          y: (maskLayer.bounds.height / 2) + 0.25),
                                          size: CGSize(width: maskLayer.bounds.width,
                                                       height: maskLayer.bounds.height / 2))
        
        layer.mask = maskLayer
        
    }
    
    public func reset() {
        waveforms.forEach {
            $0.backgroundColor = normalColor.cgColor
        }
    }
    
    public func clear() {
        layer.sublayers?.forEach {
            $0.removeFromSuperlayer()
        }
        waveforms = []
    }
    
}

enum WaveFormViewInitError: Error {
    case incorrectSampleCount
}
public class AudioAnalyzer {
    
    public func analyzeAudioFile(url: URL) throws -> [Float] {
        
        //Read File into AVAudioFile
        let file = try AVAudioFile(forReading: url)
        
        //Format of the file
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: file.fileFormat.sampleRate,
                                   channels: file.fileFormat.channelCount,
                                   interleaved: false)
        
        let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(file.length))
        
        try file.read(into: pcmBuffer!)
        
        let rawFloatData = Array(UnsafeBufferPointer(start: pcmBuffer?.floatChannelData?[0],
                                                     count: Int(pcmBuffer!.frameLength)))
        
        var resultVector = [Float](repeating: 0.0, count: rawFloatData.count)
        
        vDSP_vabs(rawFloatData,
                  1,
                  &resultVector,
                  1,
                  vDSP_Length(rawFloatData.count))
        
        return resultVector
        
    }
    
    public func amplify(_ inputArray: [Float], by amplificationFactor: Float) -> [Float] {
        
        let amplificationVector = [Float](repeating: amplificationFactor, count: inputArray.count)
        
        var resultVector = [Float](repeating: 0.0, count: inputArray.count)
        
        vDSP_vmul(inputArray,
                  1,
                  amplificationVector,
                  1,
                  &resultVector,
                  1,
                  vDSP_Length(inputArray.count))
        
        return resultVector
        
    }
    
    public func resample(_ inputArray: [Float], to targetSize: Int) -> [Float] {
        
        let stride = vDSP_Stride(inputArray.count / targetSize)
        
        let filterVector = [Float](repeating: 0.002, count: stride)
        
        var resultVector = [Float](repeating:0.0, count: targetSize)
        
        vDSP_desamp(inputArray,
                    stride,
                    filterVector,
                    &resultVector,
                    vDSP_Length(resultVector.count),
                    vDSP_Length(filterVector.count))
        
        return resultVector
        
    }
    
}
