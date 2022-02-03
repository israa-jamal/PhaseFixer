//
//  File.swift
//  PhaseFixer
//
//  Created by Esraa Gamal on 27/01/2022.
//

import AVFoundation
import Accelerate

class AudioUtilities {
    
    let noiseFloor: Float = -80

    static func getAudioSamples(forResource: String,
                                withExtension: String) -> (naturalTimeScale: CMTimeScale,
                                                           data: [Float])? {
        
        guard let path = Bundle.main.url(forResource: forResource,
                                         withExtension: withExtension) else {
                                            return nil
        }
        
        let asset = AVAsset(url: path.absoluteURL)
        
        guard
            let reader = try? AVAssetReader(asset: asset),
            let track = asset.tracks.first else {
                return nil
        }
        
        let outputSettings: [String: Int] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVNumberOfChannelsKey: 1,
            AVLinearPCMIsBigEndianKey: 0,
            AVLinearPCMIsFloatKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsNonInterleaved: 1
        ]
        
        let output = AVAssetReaderTrackOutput(track: track,
                                              outputSettings: outputSettings)

        reader.add(output)
        reader.startReading()
        
        var samplesData = [Float]()
        
        while reader.status == .reading {
            if
                let sampleBuffer = output.copyNextSampleBuffer(),
                let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                
                    let bufferLength = CMBlockBufferGetDataLength(dataBuffer)
                
                    var data = [Float](repeating: 0,
                                       count: bufferLength / 4)
                    CMBlockBufferCopyDataBytes(dataBuffer,
                                               atOffset: 0,
                                               dataLength: bufferLength,
                                               destination: &data)
                
                    samplesData.append(contentsOf: data)
            }
        }

        return (naturalTimeScale: track.naturalTimeScale,
                data: samplesData)
    }
    
    static func render(audioContext: AudioContext?, targetSamples: Int = 100) -> [Float]{
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
        
        guard reader.status == .completed else {
            fatalError("Couldn't read the audio file")
        }
        
        return outputSamples
    }
    
    static func processSamples(fromData sampleBuffer: inout Data,
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
    
    static func getdB(from normalizedSamples: inout [Float]) {
        
        var zero: Float = 32768.0
        vDSP_vdbcon(normalizedSamples, 1, &zero, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count), 1)
        
        
        var ceil: Float = 0.0
        var noiseFloorMutable : Float = -80.0
        vDSP_vclip(normalizedSamples, 1, &noiseFloorMutable, &ceil, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count))
    }
}
