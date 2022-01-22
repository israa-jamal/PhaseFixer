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

enum TestCase : String {
    case original = "starmanOriginal"
    case originalEqualized = "starmanOriginalEqualized"
    case delayed = "starmanDelayed"
    case delayedEqualized = "starmanDelayedEqualized"
}

class ViewController: UIViewController {
    
    @IBOutlet weak var originalSoundView : WaveformImageView!
    @IBOutlet weak var delayedSoundView : WaveformImageView!
    
    @IBOutlet weak var orignalLabel : UILabel!
    @IBOutlet weak var delayedLabel : UILabel!
    
    @IBOutlet weak var fixPhasing : UIButton!
    
    let noiseFloor: Float = -80
    var progress = 0.0
    
    var audioFile:AVAudioFile!
    var firstTrackTime : Float64 = 0.0
    var secondTrackTime : Float64 = 0.0
    var secondsToRemoveFromTheBeginning : Float64 = 0.0
    
    private var audioPlayer: AVAudioPlayer?
    private var audioPlayer2: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalSoundView.layer.cornerRadius = 4
        delayedSoundView.layer.cornerRadius = 4
        originalSoundView.configuration = Waveform.Configuration(style: .filled(.blue))
        delayedSoundView.configuration = Waveform.Configuration(style: .filled(.blue))
        
        let url1 = Bundle.main.url(forResource: TestCase.original.rawValue, withExtension: "m4a")!
        let url2 = Bundle.main.url(forResource: TestCase.delayed.rawValue, withExtension: "m4a")!
        runTest(url1, url2)
    }
    
    //MARK:- Actions
    
    @IBAction func play(_ sender: UIButton) {
        playSounds()
    }
    
    @IBAction func stop(_ sender: UIButton) {
        audioPlayer?.stop()
        audioPlayer2?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer2?.currentTime = 0
    }
    
    @IBAction func fixPhasing(_ sender: UIButton) {
        audioPlayer?.stop()
        audioPlayer2?.stop()
        let startTime = CMTime(seconds: Double(secondsToRemoveFromTheBeginning), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(firstTrackTime), preferredTimescale: 1000)
        
        trimAudio(inURL: Bundle.main.url(forResource: TestCase.delayed.rawValue, withExtension: "m4a")!, startTime: startTime, endTime: endTime)
    }
    
    //MARK:- Run Test
    
    func runTest(_ url1 : URL, _ url2: URL) {
        
        do {
            let data = try Data(contentsOf: url1)
            let data2 = try Data(contentsOf: url2)
            
            self.audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
            self.audioPlayer2 = try AVAudioPlayer(data: data2, fileTypeHint: AVFileType.caf.rawValue)
            
            let asset1 = AVURLAsset.init(url: url1, options: nil)
            let asset2 = AVURLAsset.init(url: url2, options: nil)
            
            firstTrackTime = CMTimeGetSeconds(asset1.duration)
            secondTrackTime = CMTimeGetSeconds(asset2.duration)
            
            DispatchQueue.main.async {
                self.orignalLabel.text = "Orignal: \(self.firstTrackTime) seconds"
                self.delayedLabel.text = "Delayed: \(self.secondTrackTime) seconds"
                
                print(self.orignalLabel.text)
                print(self.delayedLabel.text)
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        originalSoundView.waveformAudioURL = url1
        
        delayedSoundView.waveformAudioURL = url2
        
        processTwoAudios(url1: url1, url2: url2) { result1, result2 in
            self.detectPhasingForTheSameTrack(originalSamples: result1, delayedSample: result2)
            //            self.detectPhasingForTheDifferentTracks(originalSamples: result1, delayedSample: result2)
        }
    }
    
    //MARK:- Processing audio
    
    func processTwoAudios(url1 : URL, url2: URL, completion: @escaping ([Float], [Float]) -> ()) {
        var outputArray : [Float] = []
        
        AudioContext.load(fromAudioURL: url1, completionHandler: { audioContext in
            guard let audioContext = audioContext else {
                fatalError("Couldn't create the audioContext")
            }
            outputArray = self.render(audioContext: audioContext, targetSamples: audioContext.totalSamples)
            let result1 = outputArray.map({return $0 + 80.0})
            AudioContext.load(fromAudioURL: url2, completionHandler: { audioContext in
                guard let audioContext = audioContext else {
                    fatalError("Couldn't create the audioContext")
                }
                outputArray = self.render(audioContext: audioContext, targetSamples: audioContext.totalSamples)
                let result2 = outputArray.map({return $0 + 80.0})
                completion(result1, result2)
            })
        })
    }
    
    //MARK:- Detect Phasing
    
    func detectPhasingForTheSameTrack(originalSamples : [Float], delayedSample: [Float]) {
        
        let value = originalSamples.filter({$0 != 0}).first ?? 0.0
        let index1 = originalSamples.firstIndex(of: value) ?? 0
        let index2 = delayedSample.firstIndex(of: value) ?? 0
        print(index1, index2)
        
        secondsToRemoveFromTheBeginning = getTheSecondsNeededToFixPhasing(numberOfIndices: index2 - index1)
        print("the second track delayed by \(secondsToRemoveFromTheBeginning) seconds")
    }
    
    func detectPhasingForTheDifferentTracks(originalSamples : [Float], delayedSample: [Float]) {
        let value = originalSamples.filter({$0 != 0}).first ?? 0.0
        let value2 = originalSamples.filter({$0 != 0}).first ?? 0.0
        let index1 = originalSamples.firstIndex(of: value) ?? 0
        let index2 = delayedSample.firstIndex(of: value2) ?? 0
        let a = originalSamples[index1 + 1] / originalSamples[index1]
        let b = delayedSample[index2 + 1] / delayedSample[index2]
        print(index1, index2)
        print(value, value2)
        print(a, b)
    }
    
    func getTheSecondsNeededToFixPhasing(numberOfIndices: Int) -> Float64 {
        return Float64(numberOfIndices) / Float64(44100)
    }
    
    func getDiffernceRatio(_ array : [Float]) -> [Float]{
        var ratios : [Float] = []
        if !array.isEmpty {
            for i in 1..<array.count {
                ratios.append(array[i] / array[i-1])
            }
        }
        return ratios
    }
    
    //MARK: Control Sounds
    func playSounds() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        
        let concurrentQueue = DispatchQueue(label: "PlayerConcurrentQueue", attributes: .concurrent)
        
        concurrentQueue.async { [weak self] in
            guard let self = self else {return}
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.volume = 1.0
            self.audioPlayer?.play()
            //            self.animate()
        }
        
        concurrentQueue.async {[weak self] in
            guard let self = self else {return}
            self.audioPlayer2?.prepareToPlay()
            self.audioPlayer2?.volume = 1.0
            self.audioPlayer2?.play()
        }
    }
    
    func updateProgressWaveform(_ progress: Double) {
        let fullRect = originalSoundView.bounds
        let newWidth = Double(fullRect.size.width) * progress
        
        let maskLayer = CAShapeLayer()
        let maskRect = CGRect(x: 0.0, y: 0.0, width: newWidth, height: Double(fullRect.size.height))
        
        let path = CGPath(rect: maskRect, transform: nil)
        maskLayer.path = path
        
        originalSoundView.layer.mask = maskLayer
    }
    
    func animate() {
        let factor = 1 / (self.audioPlayer?.duration ?? 0)
        UIView.animate(withDuration: self.audioPlayer?.duration ?? 0) {
            self.progress += factor
            self.updateProgressWaveform(self.progress)
        } completion: { done in
            if done {
                self.progress = 0.0
            }
        }
    }
    
    //MARK: Helpers
    func trimAudio(inURL: URL, startTime: CMTime, endTime:CMTime) {
        let asset = AVAsset(url: inURL)
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
        exporter.outputFileType = AVFileType.m4a
        exporter.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        exporter.outputURL = NSURL.fileURL(withPath: "file:///Users/concarsadmin-eg/Desktop/PhaseFixer/audio-fixed.m4a")
        
        exporter.exportAsynchronously(completionHandler: {
            switch exporter.status {
            case AVAssetExportSession.Status.failed:
                print("Export failed.")
            default:
                self.replaceAudio(url: URL(string: "file:///Users/concarsadmin-eg/Desktop/PhaseFixer/audio-fixed.m4a"))
            }
        })
    }
    
    func replaceAudio(url : URL?) {
        if let url = url {
            let url1 = Bundle.main.url(forResource: TestCase.original.rawValue, withExtension: "m4a")!
            runTest(url1, url)
        }
    }
}


//MARK:- ProccessingAudioData

extension ViewController {
    
    func render(audioContext: AudioContext?, targetSamples: Int = 100) -> [Float]{
        guard let audioContext = audioContext else {
            fatalError("Couldn't create the audioContext")
        }
        
        let sampleRange: CountableRange<Int> = 0..<audioContext.totalSamples
        
        guard let reader = try? AVAssetReader(asset: audioContext.asset)
        else {
            fatalError("Couldn't initialize the AVAssetReader")
        }
        
        reader.timeRange = CMTimeRange(start: CMTime(value: Int64(sampleRange.lowerBound), timescale: audioContext.asset.duration.timescale),
                                       duration: CMTime(value: Int64(sampleRange.count), timescale: audioContext.asset.duration.timescale))
        
        let outputSettingsDict: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioContext.assetTrack,
                                                    outputSettings: outputSettingsDict)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)
        
        var channelCount = 1
        let formatDescriptions = audioContext.assetTrack.formatDescriptions as! [CMAudioFormatDescription]
        for item in formatDescriptions {
            guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item) else {
                fatalError("Couldn't get the format description")
            }
            channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
        }
        
        let samplesPerPixel = max(1, channelCount * sampleRange.count / targetSamples)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        
        var outputSamples = [Float]()
        var sampleBuffer = Data()
        
        // 16-bit samples
        reader.startReading()
        defer { reader.cancelReading() }
        
        while reader.status == .reading {
            guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(),
                  let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                break
            }
            // Append audio sample buffer into our current sample buffer
            var readBufferLength = 0
            var readBufferPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(readBuffer,
                                        atOffset: 0,
                                        lengthAtOffsetOut: &readBufferLength,
                                        totalLengthOut: nil,
                                        dataPointerOut: &readBufferPointer)
            sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
            CMSampleBufferInvalidate(readSampleBuffer)
            
            let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
            let downSampledLength = totalSamples / samplesPerPixel
            let samplesToProcess = downSampledLength * samplesPerPixel
            
            guard samplesToProcess > 0 else { continue }
            
            processSamples(fromData: &sampleBuffer,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
        }
        
        // Process the remaining samples at the end which didn't fit into samplesPerPixel
        let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
        if samplesToProcess > 0 {
            let downSampledLength = 1
            let samplesPerPixel = samplesToProcess
            let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
            
            processSamples(fromData: &sampleBuffer,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
        }
        
        // if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown)
        guard reader.status == .completed else {
            fatalError("Couldn't read the audio file")
        }
        
        return outputSamples
    }
    
    func processSamples(fromData sampleBuffer: inout Data,
                        outputSamples: inout [Float],
                        samplesToProcess: Int,
                        downSampledLength: Int,
                        samplesPerPixel: Int,
                        filter: [Float]) {
        
        sampleBuffer.withUnsafeBytes { (samples: UnsafeRawBufferPointer) in
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
            
            let sampleCount = vDSP_Length(samplesToProcess)
            
            //Create an UnsafePointer<Int16> from samples
            let unsafeBufferPointer = samples.bindMemory(to: Int16.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!
            
            //Convert 16bit int samples to floats
            vDSP_vflt16(unsafePointer, 1, &processingBuffer, 1, sampleCount)
            
            //Take the absolute values to get amplitude
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
            
            //get the corresponding dB, and clip the results
            getdB(from: &processingBuffer)
            
            //Downsample and average
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            
            //Remove processed samples
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)
            
            outputSamples += downSampledData
        }
    }
    
    func getdB(from normalizedSamples: inout [Float]) {
        // Convert samples to a log scale
        var zero: Float = 32768.0
        vDSP_vdbcon(normalizedSamples, 1, &zero, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count), 1)
        
        //Clip to [noiseFloor, 0]
        var ceil: Float = 0.0
        var noiseFloorMutable = noiseFloor
        vDSP_vclip(normalizedSamples, 1, &noiseFloorMutable, &ceil, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count))
    }
}
