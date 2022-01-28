//
//  Cross.swift
//  PhaseFixer
//
//  Created by Esraa Gamal on 28/01/2022.
//

import Accelerate
/*
// Cross-correlation of a signal [x], with another signal [y]. The signal [y]
// is padded so that it is the same length as [x].
public func xcorr(_ x: [Float], _ y: [Float]) -> [Float] {
//    precondition(x.count >= y.count, "Input vector [x] must have at least as many elements as [y]")
    var yPadded = y
    if x.count > y.count {
        let padding = repeatElement(Float(0.0), count: x.count - y.count)
        yPadded = y + padding
    } 
    
    let resultSize = x.count + yPadded.count - 1
    var result = [Float](repeating: 0, count: resultSize)
    let xPad = repeatElement(Float(0.0), count: yPadded.count-1)
    let xPadded = xPad + x + xPad
    vDSP_conv(xPadded, 1, yPadded, 1, &result, 1, vDSP_Length(resultSize), vDSP_Length(yPadded.count))
    
    return result
}
 
//        let signalGenerator = SignalGenerator(signalProvider: self,
//                                              sampleRate: samples.naturalTimeScale)
//        try? signalGenerator.start()
 
 func detectPhasingForTheSameTrack(originalSamples : [Float], delayedSample: [Float]) {
     
     let value = originalSamples.filter({$0 > 1}).first ?? 0.0
     let index1 = originalSamples.firstIndex(of: value) ?? 0
     let index2 = delayedSample.firstIndex(of: value) ?? 0
     print(index1, index2)
     
     viewModel.secondsToRemoveFromTheBeginning = viewModel.getTheSecondsNeededToFixPhasing(numberOfIndices: index2 - index1)
     startSynchronizedPlayback(bool: true, time: 0)
 }
 
 //MARK:- Detect Phasing
 
 func detectPhasingForTheDifferentTracks(originalSamples : [Float], delayedSample: [Float]) {
     let value = originalSamples.filter({$0 != 0}).first ?? 0.0
     let value2 = originalSamples.filter({$0 != 0}).first ?? 0.0
     let ratioBetweenFirstTrackSamples = viewModel.getDiffernceRatio(originalSamples)
     let ratioBetweenSecondTrackSamples = viewModel.getDiffernceRatio(delayedSample)
 }
 
 
 func append_zeros_at_shortest(_ audio_1: [Float],_ audio_2: [Float]) -> ([Float], [Float]) {
     if audio_1.count == audio_2.count {
         return (audio_1, audio_2)
     }
     if audio_1.count < audio_2.count {
         return (append_zeros(at: audio_1, new_len: audio_2.count), audio_2)
     }
     //if audio_2.count < audio_1.count ...
     return (audio_1, append_zeros(at: audio_2, new_len: audio_1.count))
 }
 
 
 
 func append_zeros(at old_array: [Float], new_len: Int) -> [Float] {
     var new_array = Array<Float>(repeating: 0, count: new_len)
     new_array[0..<old_array.count] = old_array[0..<old_array.count]
     return new_array
 }
 
 //MARK:- check if there is fade
 
 //MARK:- finding the first matched value
 //MARK:- up and down
 //MARK:- check the difference between peak and minimum
 //MARK:- multiply by -1
 //MARK:- fingerprint
 
 
 
 func phaseInversion(_ x: [Float], _ y: [Float]) {
     var yPadded = y
     if x.count > y.count {
         let padding = repeatElement(Float(0.0), count: x.count - y.count)
         yPadded = y + padding
     }
     
     let resultSize = x.count + yPadded.count - 1
     result = [Float](repeating: 0, count: resultSize)
     let xPad = repeatElement(Float(0.0), count: yPadded.count-1)
     let xPadded = xPad + x + xPad
     vDSP_conv(xPadded, 1, yPadded, 1, &result, 1, vDSP_Length(resultSize), vDSP_Length(yPadded.count))
 }
 
 
 //MARK:- check if The Phase Is Fixed
 func checkIfPhaseIsFixed() {
//        let result = xcorr(secondTrackSamples, firstTrackSamples)
   //            print("result", result)
   //            self.phaseInversion(secondTrackSamples, firstTrackSamples)
               //check if there is fade
               //which track has fade
               //finding the first matched value
   //            self.getMatchedValues(secondTrackSamples, firstTrackSamples)
//                  completion()
               //ratio
               //up and down
               //check the difference between peak and minimum
               //multiply by -1
               //fingerprint
 }
 
 
 //MARK:- which track has fade

 func getWhichSignalHasPhase() {
     
 }
 
 func getAnalytics() {
     
 }
 
 //MARK:- ratio

 func getSamplesRatio(_ array : [Float]) -> [Float] {
     var ratios = [Float](repeating: 0, count: array.count - 1)
     if !array.isEmpty {
         vDSP.divide(array.dropFirst(1), array.dropLast(1), result: &ratios)
     }
     print("*****************************")
     print(ratios)
     print("*****************************")
     return ratios
 }
 
 func getSamplesStatistics() {
     
 }
 
 func getMatchedValues(_ firstTrackSamples : [Float], _ secondTrackSamples: [Float]) {
     let firstFlooredSamples = floorSilence(firstTrackSamples)
     let secondFlooredSamples = floorSilence(secondTrackSamples)
     //10337, 10465, 10472, 10570, 10628, 10647, 10648, 10780, 10820, 11567, 11569, 11597, 11599, 11644, 11847, 11864
     
//        let value = firstFlooredSamples.first(where: {$0 > 1}) ?? 0.0
     let index1 = firstFlooredSamples.firstIndex(of: 16.365528) ?? 0
     let index2 = secondFlooredSamples.firstIndex(of: 16.365528) ?? 0
     print(firstFlooredSamples[index1...(index1 + 100)])
     print(secondFlooredSamples[index2...(index2 + 100)])
//        let indices = secondFlooredSamples.allIndices(of: value)
//        print(indices)
//        print(value)
//        print(firstFlooredSamples[index1...(index1 + 100)])
//        print(secondFlooredSamples[index2...(index2 + 100)])
//        var bool = true
//        while(bool) {
//
//            for i in index1...(index1 + 100) {
//                guard i < 44100 else {
//                    break
//                }
//                if secondFlooredSamples[i] == firstFlooredSamples[i] {
//                    ///
//                } else {
//
//                }
//            }
//        }
//        print(firstTrackSamples[index1...(index1 + 100)])
//        print(secondTrackSamples[index2...(index2 + 100)])
//
//        let silenceToAdd = index1 - index2
//        secondsToRemoveFromTheBeginning = getTheSecondsNeededToFixPhasing(numberOfIndices: silenceToAdd)
//        print(secondsToRemoveFromTheBeginning)
//        print("Double", secondsToRemoveFromTheBeginning)
     
     
//        let peak = firstFlooredSamples.prefix(44100).max(
//        let peak2 = secondFlooredSamples.prefix(44100).max()
//        print("peak1" , peak)
//        print("peak2" , peak2)
//        let index1 = firstTrackSamples.firstIndex(of: peak) ?? 0
//        let index2 = secondTrackSamples.firstIndex(of: peak) ?? 0
//        print(firstTrackSamples[index1...(index1 + 10)])
//        print(secondTrackSamples[index2...(index2 + 10)])
//
//        let silenceToAdd = index1 - index2
//        secondsToRemoveFromTheBeginning = getTheSecondsNeededToFixPhasing(numberOfIndices: silenceToAdd)
//        print(secondsToRemoveFromTheBeginning)
//        print("Double", secondsToRemoveFromTheBeginning)
     
 }
 
 func floorSilence(_ samples: [Float]) -> [Float]{
     return vDSP.add(80, samples)
 }
 
 
 

 func detectPhasingForTheSameTrack(originalSamples : [Float], delayedSample: [Float]) {
     
     let value = originalSamples.filter({$0 != 0}).first ?? 0.0
     let index1 = originalSamples.firstIndex(of: value) ?? 0
     let index2 = delayedSample.firstIndex(of: value) ?? 0
     
//        secondsToRemoveFromTheBeginning = getTheSecondsNeededToFixPhasing(numberOfIndices: index2 - index1)
 }
 
 func detectPhasingForTheDifferentTracks(originalSamples : [Float], delayedSample: [Float]) {
     let value = originalSamples.filter({$0 != 0}).first ?? 0.0
     let value2 = originalSamples.filter({$0 != 0}).first ?? 0.0
     let ratioBetweenFirstTrackSamples = getDiffernceRatio(originalSamples)
     let ratioBetweenSecondTrackSamples = getDiffernceRatio(delayedSample)
     
 }
 func getDiffernceRatio(_ array : [Float]) -> [Float]{
     var ratios = [Float](repeating: 0, count: array.count - 1)
     if !array.isEmpty {
         vDSP.divide(array.dropFirst(1), array.dropLast(1), result: &ratios)
     }
     print("*****************************")
//        print(ratios)
     print("*****************************")
     return ratios
 }
 
 
 /*
  AudioContext.load(fromAudioURL: url1, completionHandler: { audioContext in
      guard let audioContext = audioContext else {
          fatalError("Couldn't create the audioContext")
      }
      outputArray = Array(AudioUtilities.render(audioContext: audioContext, targetSamples: audioContext.totalSamples).prefix(44100))
      let samplesOfFirstAudio = vDSP.add(80, outputArray)
      AudioContext.load(fromAudioURL: url2, completionHandler: { audioContext in
          guard let audioContext = audioContext else {
              fatalError("Couldn't create the audioContext")
          }
          outputArray = Array(AudioUtilities.render(audioContext: audioContext, targetSamples: audioContext.totalSamples).prefix(44100))
          let samplesOfSecondAudio = vDSP.add(80, outputArray)
          
          completion(samplesOfFirstAudio, samplesOfSecondAudio)
      })
  })
  */
}
/*
func trial3() {
  for _ in 0...1
  {
      audioFilePlayer.append(AVAudioPlayerNode())
      // audioEngine code
  }
  do {
      
      // For each note, read the note URL into an AVAudioFile,
      // setup the AVAudioPCMBuffer using data read from the file,
      // and read the AVAudioFile into the corresponding buffer
      for i in 0...1
      {
          noteFileURL.append(URL(fileURLWithPath: noteFilePath[i]))
          
          // Read the corresponding url into the audio file
          try noteAudioFile.append(AVAudioFile(forReading: noteFileURL[i]))
          
          // Read data from the audio file, and store it in the correct buffer
          let noteAudioFormat = noteAudioFile[i].processingFormat
          
          let noteAudioFrameCount = UInt32(noteAudioFile[i].length)
          
          noteAudioFileBuffer.append(AVAudioPCMBuffer(pcmFormat: noteAudioFormat, frameCapacity: noteAudioFrameCount)!)
          
          // Read the audio file into the buffer
          try noteAudioFile[i].read(into: noteAudioFileBuffer[i])
      }
      
      mainMixer = audioEngine.mainMixerNode
      
      // For each note, attach the corresponding node to the audioEngine, and connect the node to the audioEngine's mixer.
      for i in 0...1
      {
          audioEngine.attach(audioFilePlayer[i])
          
          audioEngine.connect(audioFilePlayer[i], to: mainMixer, fromBus: 0, toBus: i, format: noteAudioFileBuffer[i].format)
      }
      
      // Start the audio engine
      try audioEngine.start()
      
      // Setup the audio session to play sound in the app, and activate the audio session
      try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.soloAmbient)
      try AVAudioSession.sharedInstance().setMode(AVAudioSession.Mode.default)
      try AVAudioSession.sharedInstance().setActive(true)
  }
  catch let error
  {
      print(error.localizedDescription)
  }
}

*/
/*

var audioFilePlayer = [AVAudioPlayerNode]()


private var audioFiles = [URL]()
private var audioEngine: AVAudioEngine = AVAudioEngine()
private var mixer: AVAudioMixerNode = AVAudioMixerNode()

let noteFilePath: [String] = [
  Bundle.main.path(forResource: TestCase.original.rawValue, ofType: "m4a")!,
  Bundle.main.path(forResource: TestCase.original.rawValue, ofType: "m4a")!]
var noteFileURL = [URL]()
var noteAudioFile = [AVAudioFile]()
var noteAudioFileBuffer = [AVAudioPCMBuffer]()

var mainMixer = AVAudioMixerNode()

func Play() {
  
  // do work in a background thread
  DispatchQueue.global(qos: .background).async {
    self.audioEngine.attach(self.mixer)
    self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: nil)
    // !important - start the engine *before* setting up the player nodes
    try! self.audioEngine.start()
    
    let fileManager = FileManager.default
    for audioFile in self.audioFiles {
      // Create and attach the audioPlayer node for this file
      let audioPlayer = AVAudioPlayerNode()
      self.audioEngine.attach(audioPlayer)
      // Notice the output is the mixer in this case
      self.audioEngine.connect(audioPlayer, to: self.mixer, format: nil)
//            let fileUrl = NSURL.init(fileURLWithPath: audioFile.removingPercentEncoding!)
      var file : AVAudioFile
//
//            // We should probably check if the file exists here ¯\_(ツ)_/¯
      file = try! AVAudioFile.init(forReading: audioFile)
      
      audioPlayer.scheduleFile(file, at: nil, completionHandler: nil)
      audioPlayer.play(at: nil)
//            var startFramePosition = audioPlayer.lastRenderTime?.sampleTime
//            if startFramePosition == nil {
//              audioPlayer.play(at: nil)
//              startFramePosition = (audioPlayer.lastRenderTime?.sampleTime)!
//              startTime = AVAudioTime.init(sampleTime: startFramePosition!, atRate: Double(self.mixer.rate))
//            } else {
//              audioPlayer.play(at: startTime!)
//            }
    }
      
  }
}
*/
/*
func scheduleWithOffset(_ offset: TimeInterval) {

let samplerate1 = file1.processingFormat.sampleRate
player1.scheduleSegment(file1,
startingFrame: 0,
frameCount: AVAudioFrameCount(file1.length),
at: AVAudioTime(sampleTime: 0, atRate: samplerate1))

let samplerate2 = file2.processingFormat.sampleRate
player2.scheduleSegment(file2,
startingFrame: 0,
frameCount: AVAudioFrameCount(file2.length),
at: AVAudioTime(sampleTime: AVAudioFramePosition(offset * samplerate2), atRate: samplerate2))

//This can take an indeterminate amount of time, so both files should be prepared before either starts.
player1.prepare(withFrameCount: 8192)
player2.prepare(withFrameCount: 8192)

// Start the files at common time slightly in the future to ensure a synchronous start.
let hostTimeNow = mach_absolute_time()
let hostTimeFuture = hostTimeNow + AVAudioTime.hostTime(forSeconds: 0.2);
let startTime = AVAudioTime(hostTime: hostTimeFuture)

player1.play(at: startTime)
player2.play(at: startTime)
}
 
 
 var pageNumber = 0
 var sampleCount = 1024
 
 let samples: (naturalTimeScale: Int32, data: [Float]) = {
     guard let samples = AudioUtilities.getAudioSamples(
         forResource: TestCase.sexOnFire.rawValue,
         withExtension: "m4a") else {
             fatalError("Unable to parse the audio resource.")
     }
     
     return samples
 }()
 
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
         let url1 = Bundle.main.url(forResource: TestCase.sexOnFire.rawValue, withExtension: "m4a")!
         
     }
 }
}

class SignalGenerator {
 private let engine = AVAudioEngine()
 
 /// The current page of single-precision audio samples
 private var page = [Float]()
 
 /// The object that provides audio samples.
 private let signalProvider: SignalProvider

 /// The sample rate for the input and output format.
 let sampleRate: CMTimeScale
 
 private lazy var format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate),
                                         channels: 1)
 
 private lazy var srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
     let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
     for frame in 0..<Int(frameCount) {
         let value = self.getSignalElement()
         
         for buffer in ablPointer {
             let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
             buf[frame] = value
         }
     }
     return noErr
 }
 
 init(signalProvider: SignalProvider, sampleRate: CMTimeScale) {
     self.signalProvider = signalProvider
     self.sampleRate = sampleRate
     
     engine.attach(srcNode)
     
     engine.connect(srcNode,
                    to: engine.mainMixerNode,
                    format: format)
     
     engine.connect(engine.mainMixerNode,
                    to: engine.outputNode,
                    format: format)
     
     engine.mainMixerNode.outputVolume = 0.5
 }
 
 public func start() throws {
     try engine.start()
 }
 
 private func getSignalElement() -> Float {
     if page.isEmpty {
         page = signalProvider.getSignal()
     }
     
     return page.isEmpty ? 0 : page.removeFirst()
 }
}

protocol SignalProvider {
 func getSignal() -> [Float]
}


extension ViewController: SignalProvider {
 // Returns a page containing `sampleCount` samples from the
 // `samples` array and increments `pageNumber`.
 func getSignal() -> [Float] {
     let start = pageNumber * sampleCount
     let end = (pageNumber + 1) * sampleCount
     
     let page = Array(samples.data[start ..< end])
     
     pageNumber += 1
     
     if (pageNumber + 1) * sampleCount >= samples.data.count {
         pageNumber = 0
     }
     
     let outputSignal: [Float] = []

     
     return outputSignal
 }
}

*/
*/
