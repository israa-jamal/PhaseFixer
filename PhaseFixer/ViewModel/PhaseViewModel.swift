//
//  PhaseViewModel.swift
//  PhaseFixer
//
//  Created by Esraa Gamal on 25/01/2022.
//

import Foundation
import Accelerate
import AVFoundation

enum TestCase : String {
    case rushingWater = "RushingWater"
    case rushingWaterPhased = "RushingWaterPhased"
}

protocol AudioViewModelProtocol : AnyObject {
    func playAudios(_ firstTrackURl: URL, _ secondTrackURl: URL, _ buffer: Double)
}

class PhaseViewModel {
    
    weak var delegate : AudioViewModelProtocol?
    
    let sampleRate = 44100
    var buffer : Float64 = 0.0
    var firstTrackURL : URL?
    var secondTrackURL : URL?
    
    func playAudio(_ firstFileName : TestCase, _ secondFileName : TestCase) {
        firstTrackURL = Bundle.main.url(forResource: firstFileName.rawValue, withExtension: "m4a")
        secondTrackURL = Bundle.main.url(forResource: secondFileName.rawValue, withExtension: "m4a")
        
        guard let firstTrackURL = firstTrackURL else {
            print("Error: Couldn't find file")
            return
        }
        
        guard let secondTrackURL = secondTrackURL  else {
            print("Error: Couldn't find file")
            return
        }
        
        analysisAudios(url1: firstTrackURL, url2: secondTrackURL, completion: {
            self.delegate?.playAudios(firstTrackURL, secondTrackURL, self.buffer)
        })
    }
    
    //MARK:- Processing audio
    
    func analysisAudios(url1 : URL, url2: URL, completion:@escaping ()->()) {
        processAndGetSamplesOfAudiosWith(url1: url1, url2: url2) { firstSamples, secondSamples in
            let firstTrackSamples = Array(firstSamples.prefix((self.sampleRate * 3)))
            let secondTrackSamples = Array(secondSamples.prefix((self.sampleRate * 3)))
            do {
                let result = try self.getDelay(firstTrackSamples, secondTrackSamples)
                let timeDelay: Float = self.getTimeAtPeak(result, sample_rate: self.sampleRate)
                self.buffer = Float64(abs(timeDelay))
                
                completion()
            } catch {
                print("Couldn't process files")
            }
        }
    }
    
    func getDelay(_ firstSamples : [Float], _ secondSamples: [Float]) throws -> [Float] {
        let secondSamplesPadded = secondSamples
        let resultSize = firstSamples.count + secondSamplesPadded.count - 1
        var result = [Float](repeating: 0, count: resultSize)
        let firstSamplesPad = repeatElement(Float(0.0), count: secondSamplesPadded.count-1)
        let firstSamplesPadded = firstSamplesPad + firstSamples + firstSamplesPad
        vDSP_conv(firstSamplesPadded, 1, secondSamplesPadded, 1, &result, 1, vDSP_Length(resultSize), vDSP_Length(secondSamplesPadded.count))
        return result
    }
    
    func getTimeAtPeak(_ array: [Float], sample_rate sr: Int) -> Float {
        var center_index =  Float(array.count / 2)
        if array.count % 2 == 0 {
            center_index -= 0.5
        }
        if let value = array.max() {
            let max_index = Float(array.firstIndex(of: value) ?? 0)
            return (max_index - center_index) / Float(sr)
        }
        return 0
    }
    
    //MARK:- Helpers
    
    func processAndGetSamplesOfAudiosWith(url1 : URL, url2: URL, completion: @escaping ([Float], [Float]) -> ()) {
        AudioContext.load(fromAudioURL: url1, completionHandler: { audioContext in
            guard let audioContext = audioContext else {
                fatalError("Couldn't create the audioContext")
            }
            let samplesOfFirstAudio : [Float] = Array(AudioUtilities.render(audioContext: audioContext, targetSamples: audioContext.totalSamples))
            AudioContext.load(fromAudioURL: url2, completionHandler: { audioContext in
                guard let audioContext = audioContext else {
                    fatalError("Couldn't create the audioContext")
                }
                let samplesOfSecondAudio : [Float] = Array(AudioUtilities.render(audioContext: audioContext, targetSamples: audioContext.totalSamples))
                completion(samplesOfFirstAudio, samplesOfSecondAudio)
            })
        })
    }
    
    func readAudio(filename: String, file_extension: String) -> ([Float], Int) {
        let audioUrl = Bundle.main.url(forResource: filename, withExtension: file_extension)!
        let audioFile = try! AVAudioFile(forReading: audioUrl)
        let audioFileFormat = audioFile.processingFormat
        let audioFileSize = UInt32(audioFile.length)
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFileFormat, frameCapacity: audioFileSize)!
        try! audioFile.read(into: audioBuffer)
        return (Array(UnsafeBufferPointer(start: audioBuffer.floatChannelData![0], count: Int(audioBuffer.frameLength))), Int(audioFile.fileFormat.sampleRate))
    }
    
}
