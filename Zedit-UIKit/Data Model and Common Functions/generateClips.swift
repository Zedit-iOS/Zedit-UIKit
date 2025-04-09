//
//  generateClips.swift
//  Zedit-UIKit
//
//  Created by Avinash on 21/03/25.
//

import Foundation
import AVFoundation
import Speech

func generateClips(
    VideoURL: URL,
    minuites: Int,
    seconds: Int,
    numberOfClips: Int,
    projectName: String,
    isCreatingScenes: Bool,
    isLLmProcessing: Bool,
    isCreatingTimestamps: Bool,
    isCreatingClips: Bool,
    delegate: TrimVideoPreviewViewController
) {
    delegate.updateLoadingMessage("Analyzing video...")

    let minutes = minuites
    let seconds = seconds
    let minimumClipDuration = (minutes * 60) + seconds

    let scenes = processVideoForScenes(videoPath: VideoURL.path, minimumClipDuration: minimumClipDuration)

    let finalSceneRanges = scenes.map { $0.start...$0.end }
    let flatSceneRanges = finalSceneRanges.map { range in
        [range.lowerBound, range.upperBound]
    }

    print("Scenes are : \(flatSceneRanges)")

    delegate.updateLoadingMessage("Extracting audio...")

    extractAudioAndTranscribe(from: VideoURL, finalSceneRanges: flatSceneRanges, numberOfClips: numberOfClips, projectName: projectName, delegate: delegate)
}



func processVideoForScenes(videoPath: String, minimumClipDuration: Int) -> [SceneRange]{
    let scenesArray = NSMutableArray()
    let error = CV.detectSceneChanges(videoPath, scenes: scenesArray, minDuration: Double(minimumClipDuration))
    
    if let error = error, error.hasError {
        print("Error detecting scenes: \(error.message ?? "")")
        return []
    }
    
    var scenes: [SceneRange] = []
    
    scenes = scenesArray.compactMap { $0 as? SceneRange }
    print("Detected scenes: \(scenes)") // Debug output to verify scenes are detected.
    return scenes
}

func extractAudioAndTranscribe(from videoURL: URL, finalSceneRanges: [[Double]], numberOfClips: Int, projectName: String, delegate: TrimVideoPreviewViewController) {
    let asset = AVAsset(url: videoURL)
    guard let track = asset.tracks(withMediaType: .audio).first else {
        print("No audio track found in video.")
        return
    }
    
    let composition = AVMutableComposition()
    guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio,
                                                                   preferredTrackID: kCMPersistentTrackID_Invalid) else {
        print("Could not create audio composition track.")
        return
    }
    
    do {
        try audioCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration),
                                                  of: track,
                                                  at: .zero)
        
        let audioOutputURL = videoURL.deletingPathExtension().appendingPathExtension("m4a")
        // Remove any existing file
        try? FileManager.default.removeItem(at: audioOutputURL)
        
        guard let exportSession = AVAssetExportSession(asset: composition,
                                                       presetName: AVAssetExportPresetAppleM4A) else {
            print("Could not create export session.")
            return
        }
        exportSession.outputURL = audioOutputURL
        exportSession.outputFileType = .m4a
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("Audio extracted successfully to: \(audioOutputURL)")
                
                // 1. Check file existence and size
                if FileManager.default.fileExists(atPath: audioOutputURL.path) {
                    do {
                        let fileAttributes = try FileManager.default.attributesOfItem(atPath: audioOutputURL.path)
                        if let fileSize = fileAttributes[.size] as? UInt64, fileSize > 0 {
                            print("Audio file exists and size: \(fileSize) bytes")
                        } else {
                            print("File exists but has zero size.")
                        }
                    } catch {
                        print("Failed to get file attributes: \(error.localizedDescription)")
                    }
                } else {
                    print("Audio file does not exist at \(audioOutputURL.path)")
                }
                
                // 2. Validate the exported audio asset
                if validateAudioAsset(at: audioOutputURL) {
                    print("Audio asset validation passed.")
                } else {
                    print("Audio asset validation failed.")
                }
                
                // 3. Test decoding of the audio file
                testAudioDecoding(url: audioOutputURL)
                
                // 4. Proceed with transcription
                transcribeAudio(at: audioOutputURL, sceneRanges: finalSceneRanges, videoURL: videoURL, numberOfClips: numberOfClips) { timestamps in
                    delegate.updateLoadingMessage("Running LLm analysis")
                    getResults(timestamps: timestamps, sceneRanges: finalSceneRanges, videoURL: videoURL, numberOfClips: numberOfClips, projectName: projectName, delegate: delegate)
                }

                
            case .failed:
                print("Failed to export audio: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                delegate.updateLoadingMessage("creating clips")
                getResults(timestamps: [],
                           sceneRanges: finalSceneRanges,
                                videoURL: videoURL,
                           numberOfClips: numberOfClips, projectName: projectName, delegate: delegate)
            case .cancelled:
                print("Audio export cancelled")
            default:
                break
            }
        }
    } catch {
        print("Error extracting audio: \(error.localizedDescription)")
    }
}

func validateAudioAsset(at url: URL) -> Bool {
    let asset = AVAsset(url: url)
    let audioTracks = asset.tracks(withMediaType: .audio)
    
    guard !audioTracks.isEmpty else {
        print("No audio tracks found in the file.")
        return false
    }
    
    // Print out some details about the audio track
    if let track = audioTracks.first {
        for case let desc as CMAudioFormatDescription in track.formatDescriptions {
            if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee {
                print("Sample rate: \(asbd.mSampleRate)")
                print("Channels: \(asbd.mChannelsPerFrame)")
            }
        }
    }
    
    return true
}

func testAudioDecoding(url: URL) {
    let asset = AVAsset(url: url)
    guard let track = asset.tracks(withMediaType: .audio).first else {
        print("No audio track found for decoding.")
        return
    }
    
    do {
        let assetReader = try AVAssetReader(asset: asset)
        // Request uncompressed linear PCM output for testing
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        assetReader.add(trackOutput)
        
        assetReader.startReading()
        var sampleCount = 0
        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            sampleCount += 1
            CMSampleBufferInvalidate(sampleBuffer)
        }
        
        if sampleCount > 0 {
            print("Audio file decoded successfully with \(sampleCount) samples read.")
        } else {
            print("No audio samples could be read from the file.")
        }
    } catch {
        print("Failed to create AVAssetReader: \(error.localizedDescription)")
    }
}


func transcribeAudio(at audioURL: URL, sceneRanges: [[Double]], videoURL: URL, numberOfClips: Int, completion: @escaping ([String]) -> Void) {
    guard let recognizer = SFSpeechRecognizer() else {
        print("Speech recognizer not available")
        completion([])
        return
    }
    
    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    request.shouldReportPartialResults = false

    recognizer.recognitionTask(with: request) { result, error in
        if let error = error {
            print("Transcription error: \(error.localizedDescription)")
            completion([])
            return
        }

        if let result = result, result.isFinal {
            var transcriptionTimestamps: [Double: String] = [:]
            for segment in result.bestTranscription.segments {
                transcriptionTimestamps[segment.timestamp] = segment.substring
            }

            let sortedTimestamps = transcriptionTimestamps.sorted { $0.key < $1.key }
            var formattedTimestamps: [String] = []
            for (key, _) in sortedTimestamps {
                let timestampString = String(format: "%02d:%02d:%02d",
                                             Int(key) / 3600,
                                             (Int(key) % 3600) / 60,
                                             Int(key) % 60)
                formattedTimestamps.append(timestampString)
            }

            print("Transcribed timestamps: \(formattedTimestamps)")
            completion(formattedTimestamps)
        }
    }
}


func getResults(
    timestamps: [String],
    sceneRanges: [[Double]],
    videoURL: URL,
    numberOfClips: Int,
    projectName: String,
    delegate: TrimVideoPreviewViewController?
) {
    Task {
        do {
            if let extractedTimestamps = try await getClipTimestamps(
                timestamps: timestamps,
                sceneRanges: sceneRanges,
                videoURL: videoURL
            ) {
                let sortedTimestamps = extractedTimestamps.sorted()
                print("Extracted timestamps: \(sortedTimestamps)")
                if sortedTimestamps.count >= 2 {
                    DispatchQueue.main.async {
                           delegate?.updateLoadingMessage("creating Clips...")
                       }
                    exportClip(from: videoURL, timestamps: sortedTimestamps, projectName: projectName)
                } else {
                    print("Not enough timestamps extracted. Falling back.")
                    if let fallbackTimestamps = generateEvenClipTimestamps(for: videoURL, numberOfClips: numberOfClips) {
                        DispatchQueue.main.async {
                               delegate?.updateLoadingMessage("creating Clips...")
                           }
                        exportClip(from: videoURL, timestamps: fallbackTimestamps, projectName: projectName)
                    } else {
                        print("Failed to generate fallback clip timestamps.")
                    }
                }
            } else {
                // Fallback if extraction returned nil.
                if let fallbackTimestamps = generateEvenClipTimestamps(for: videoURL, numberOfClips: numberOfClips) {
                    DispatchQueue.main.async {
                           delegate?.updateLoadingMessage("creating Clips...")
                       }
                    exportClip(from: videoURL, timestamps: fallbackTimestamps, projectName: projectName)
                } else {
                    print("Failed to generate fallback clip timestamps.")
                }
            }
        } catch {
            print("Error running LLM: \(error)")
            if let fallbackTimestamps = generateEvenClipTimestamps(for: videoURL, numberOfClips: numberOfClips) {
                DispatchQueue.main.async {
                       delegate?.updateLoadingMessage("creating Clips...")
                   }
                exportClip(from: videoURL, timestamps: fallbackTimestamps, projectName: projectName)
            } else {
                print("Failed to generate fallback clip timestamps.")
            }
        }
    }
}


func generateEvenClipTimestamps(for videoURL: URL, numberOfClips: Int) -> [Double]? {
    let asset = AVAsset(url: videoURL)
    let durationSeconds = CMTimeGetSeconds(asset.duration)
    guard durationSeconds > 0, numberOfClips > 0 else { return nil }
    
    // Calculate the clip duration (each clip will be of equal duration).
    let clipDuration = durationSeconds / Double(numberOfClips)
    
    // Build timestamps array. We start at 0, then add clipDuration repeatedly.
    // Ensure we include the final timestamp.
    var timestamps: [Double] = []
    for i in 0...numberOfClips {
        timestamps.append(Double(i) * clipDuration)
    }
    return timestamps
}

func exportClip(from videoURL: URL, timestamps: [Double], projectName: String) {
    let asset = AVAsset(url: videoURL)
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("Failed to find the documents directory")
        return
    }
    
    let projectDirectory = documentsDirectory.appendingPathComponent(projectName)
    let clipsDirectory = projectDirectory.appendingPathComponent("Clips")
    
    if !FileManager.default.fileExists(atPath: clipsDirectory.path) {
        do {
            try FileManager.default.createDirectory(at: clipsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create 'Clips' folder: \(error.localizedDescription)")
            return
        }
    }
    
    let videoDuration = asset.duration.seconds
    
    for i in 0..<(timestamps.count - 1) {
        // Ensure the times are within the asset's duration.
        let startTimeValue = min(timestamps[i], videoDuration)
        let endTimeValue = min(timestamps[i + 1], videoDuration)
        
        let startTime = CMTime(seconds: startTimeValue, preferredTimescale: 600)
        let endTime = CMTime(seconds: endTimeValue, preferredTimescale: 600)
        
        // Verify that the time range is valid.
        if CMTimeCompare(startTime, endTime) >= 0 {
            print("Invalid time range for clip \(i): startTime (\(startTimeValue)) >= endTime (\(endTimeValue))")
            continue
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            print("Failed to create export session for clip \(i)")
            continue
        }
        exportSession.outputFileType = .mp4
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let currentTimeString = dateFormatter.string(from: Date())
        let outputURL = clipsDirectory.appendingPathComponent("clip_\(i)_\(currentTimeString).mp4")
        
        exportSession.outputURL = outputURL
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("Clip \(i) exported successfully to: \(outputURL)")
            case .failed:
                print("Failed to export clip \(i): \(String(describing: exportSession.error))")
            case .cancelled:
                print("Export cancelled for clip \(i)")
            default:
                break
            }
        }
    }
}




