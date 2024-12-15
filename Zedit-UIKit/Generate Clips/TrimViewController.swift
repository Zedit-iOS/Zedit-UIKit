//
//  TrimViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 04/11/24.
//

import UIKit
import AVFoundation
import AVKit
import Speech

class TrimViewController: UIViewController {
    
    var videoList: [URL] = []
    var projectNameTrim = String()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var videoSelectorView: UIView!
    @IBOutlet weak var videoSelectorButton: UIButton!
    
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var numberOfClipsStepper: UIStepper!
    @IBOutlet weak var numberOfClipsStepperLabel: UILabel!
    @IBOutlet weak var maximumDurationOfClipsStepper: UIStepper!
    @IBOutlet weak var maximumDurationOfClipsStepperLabel: UILabel!
    @IBOutlet weak var clippingFocusSegmentedControl: UISegmentedControl!
    
    let trimSeguePreviewIdentifier = "preview"
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = projectNameTrim
        setupSteppers()
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition denied")
                case .restricted, .notDetermined:
                    print("Speech recognition not available")
                @unknown default:
                    fatalError("Unknown authorization status")
                }
            }
        
        if let project = getProject(projectName: projectNameTrim) {
            // Aggregate videos from all subfolders
            videoList = project.subfolders.flatMap { $0.videoURLS }
            setUpButton()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func extractAudioAndTranscribe(from videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let audioTrack = asset.tracks(withMediaType: .audio).first

        // Check if the audio track exists
        guard let track = audioTrack else {
            print("No audio track found in video.")
            return
        }

        // Create a composition
        let composition = AVMutableComposition()
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: track, at: .zero)
            
            // Export the audio
            let audioOutputURL = videoURL.deletingPathExtension().appendingPathExtension("m4a") // Change file extension to m4a
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            exportSession?.outputURL = audioOutputURL
            exportSession?.outputFileType = .m4a
            
            exportSession?.exportAsynchronously {
                switch exportSession?.status {
                case .completed:
                    print("Audio extracted successfully to: \(audioOutputURL)")
                    self.transcribeAudio(at: audioOutputURL)
                case .failed:
                    print("Failed to export audio: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
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
    
    func transcribeAudio(at audioURL: URL) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audioURL)

        recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                // Print the transcription result
                let transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")
            } else if let error = error {
                print("Transcription error: \(error.localizedDescription)")
            }
        }
    }

    
    func setupSteppers() {
        numberOfClipsStepper.minimumValue = 1
        numberOfClipsStepper.maximumValue = 10
        numberOfClipsStepper.stepValue = 1
        numberOfClipsStepper.value = 1
        numberOfClipsStepperLabel.text = "\(Int(numberOfClipsStepper.value))"
        
        maximumDurationOfClipsStepper.minimumValue = 30
        maximumDurationOfClipsStepper.maximumValue = 300
        maximumDurationOfClipsStepper.stepValue = 30
        maximumDurationOfClipsStepper.value = 30
        maximumDurationOfClipsStepperLabel.text = "\(Int(maximumDurationOfClipsStepper.value))s"
        
        numberOfClipsStepper.addTarget(self, action: #selector(numberOfClipsStepperChanged(_:)), for: .valueChanged)
        maximumDurationOfClipsStepper.addTarget(self, action: #selector(maximumDurationStepperChanged(_:)), for: .valueChanged)
    }
    
    @objc func numberOfClipsStepperChanged(_ sender: UIStepper) {
        numberOfClipsStepperLabel.text = "\(Int(sender.value))"
    }
    
    @objc func maximumDurationStepperChanged(_ sender: UIStepper) {
        maximumDurationOfClipsStepperLabel.text = "\(Int(sender.value))s"
    }
    
    /// Fetches the project and its subfolders based on the project name.
    func getProject(projectName: String) -> Project? {
        let fileManager = FileManager.default
        
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access documents directory.")
            return nil
        }
        
        let projectDirectory = documentsDirectory.appendingPathComponent(projectName)
        guard fileManager.fileExists(atPath: projectDirectory.path) else {
            print("Project folder does not exist.")
            return nil
        }
        
        do {
            var subfolders: [Subfolder] = []
            let predefinedSubfolderNames = ["Original Videos", "Clips", "Colour Graded Videos"]
            
            for subfolderName in predefinedSubfolderNames {
                let subfolderURL = projectDirectory.appendingPathComponent(subfolderName)
                var videoURLs: [URL] = []
                
                if fileManager.fileExists(atPath: subfolderURL.path) {
                    let videoFiles = try fileManager.contentsOfDirectory(at: subfolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    videoURLs = videoFiles.filter { ["mp4", "mov"].contains($0.pathExtension.lowercased()) }
                }
                
                subfolders.append(Subfolder(name: subfolderName, videos: videoURLs))
            }
            
            return Project(name: projectName, subfolders: subfolders)
        } catch {
            print("Error reading project folder: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Sets up the video selector button menu.
    func setUpButton() {
        guard !videoList.isEmpty else {
            videoSelectorButton.isEnabled = false
            return
        }
        
        videoSelectorButton.isEnabled = true
        let actionClosure = { (action: UIAction) in
            if let selectedVideo = self.videoList.first(where: { $0.lastPathComponent == action.title }) {
                self.playVideo(url: selectedVideo)
            }
        }
        
        var menuChildren: [UIMenuElement] = []
        for videoURL in videoList {
            menuChildren.append(UIAction(title: videoURL.lastPathComponent, handler: actionClosure))
        }
        
        videoSelectorButton.menu = UIMenu(options: .displayInline, children: menuChildren)
        videoSelectorButton.showsMenuAsPrimaryAction = true
    }
    
    /// Plays the selected video in the preview view.
    private func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true
        
        videoSelectorView.subviews.forEach { $0.removeFromSuperview() }
        
        if let playerVC = playerViewController {
            addChild(playerVC)
            playerVC.view.frame = videoSelectorView.bounds
            videoSelectorView.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)
        }
        
        player?.play()
    }
    
    func generateClips() {
        guard let selectedVideoURL = player?.currentItem?.asset as? AVURLAsset else {
                print("No video is currently selected for playback.")
                return
            }
            
            let videoURL = selectedVideoURL.url

        
        let numberOfClips = Int(numberOfClipsStepper.value)
        let maximumDuration = Int(maximumDurationOfClipsStepper.value)
        let asset = AVAsset(url: videoURL)
        let totalDuration = CMTimeGetSeconds(asset.duration)
        
        let clipDuration = min(totalDuration / Double(numberOfClips), Double(maximumDuration))
        
        for i in 0..<numberOfClips {
            let startTime = CMTime(seconds: clipDuration * Double(i), preferredTimescale: asset.duration.timescale)
            let endTime = CMTime(seconds: min(clipDuration * Double(i + 1), totalDuration), preferredTimescale: asset.duration.timescale)
            exportClip(from: videoURL, startTime: startTime, endTime: endTime, index: i)
            extractAudioAndTranscribe(from: videoURL)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == trimSeguePreviewIdentifier {
            if let destinationVC = segue.destination as? TrimVideoPreviewViewController {
                generateClips()
                destinationVC.trimPreviewProjectName = projectNameTrim
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirm Exit",
            message: "Are you sure you want to cancel and go back?",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            self.performSegue(withIdentifier: "cancel", sender: nil)
        })
        
        alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func exportClip(from videoURL: URL, startTime: CMTime, endTime: CMTime, index: Int) {
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mp4

        // Create the "Clips" subfolder path
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to find the documents directory")
            return
        }
        
        let projectDirectory = documentsDirectory.appendingPathComponent(projectNameTrim)
        let clipsDirectory = projectDirectory.appendingPathComponent("Clips")

        // Ensure the "Clips" subfolder exists
        if !fileManager.fileExists(atPath: clipsDirectory.path) {
            do {
                try fileManager.createDirectory(at: clipsDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create 'Clips' folder: \(error.localizedDescription)")
                return
            }
        }

        // Create the output file path for the clip
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmm"
        let currentTimeString = dateFormatter.string(from: Date())
        let outputURL = clipsDirectory.appendingPathComponent("clip_\(index)_\(currentTimeString).mp4")
        exportSession?.outputURL = outputURL
        exportSession?.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)

        // Export the clip
        exportSession?.exportAsynchronously {
            if exportSession?.status == .completed {
                DispatchQueue.main.async {
                    print("Clip exported successfully to: \(outputURL)")
                }
            } else {
                DispatchQueue.main.async {
                    print("Failed to export clip: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

}

extension TrimViewController {
    @objc func keyboard(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            self.view.frame.origin.y = -keyboardRect.height
        } else {
            self.view.frame.origin.y = 0
        }
    }
}
