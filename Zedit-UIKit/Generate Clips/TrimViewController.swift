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

class TrimViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var videoList: [URL] = []
    var projectNameTrim = String()
    private var scenes: [SceneRange] = []
    private var transcriptionTimestamps: [TimeInterval: String] = [:]
    private var clipTimestamps: [Double] = []
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var videoSelectorView: UIView!
    @IBOutlet weak var videoSelectorButton: UIButton!
    
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var numberOfClipsStepper: UIStepper!
    @IBOutlet weak var numberOfClipsStepperLabel: UILabel!
    @IBOutlet weak var clippingFocusSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var minutesPicker: UIPickerView!
    @IBOutlet weak var secondsPicker: UIPickerView!
    
    private let minutesRange = Array(0...59)
    private let secondsRange = Array(0...59)
    private var flatSceneRanges: [[Double]] = []
    private var finalSceneTimeStamps: Array<Double> = [];
    
    fileprivate var playerObserver: Any?
    
    private func setupPickers(  ) {
        minutesPicker.delegate = self
        minutesPicker.dataSource = self // Add dataSource
        secondsPicker.delegate = self 
        secondsPicker.dataSource = self // Add dataSource
    }
    
    // Add required UIPickerViewDataSource methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView == minutesPicker ? minutesRange.count : secondsRange.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let value = pickerView == minutesPicker ? minutesRange[row] : secondsRange[row]
        return String(format: "%02d", value)
    }
    let trimSeguePreviewIdentifier = "preview"
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = projectNameTrim
        setupSteppers()
        setupPickers()
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
            if player != nil{
                player?.replaceCurrentItem(with: nil)
                player = nil
            }
    }

    
    func extractAudioAndTranscribe(from videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let audioTrack = asset.tracks(withMediaType: .audio).first

    
        guard let track = audioTrack else {
            print("No audio track found in video.")
            return
        }

        let composition = AVMutableComposition()
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: track, at: .zero)
            
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
       guard let recognizer = SFSpeechRecognizer() else {
           print("Speech recognizer not available")
           return
       }
       let request = SFSpeechURLRecognitionRequest(url: audioURL)
       request.shouldReportPartialResults = false

       recognizer.recognitionTask(with: request) { [weak self] result, error in
           guard let self = self else { return }
           
           if let error = error {
               
               print("Transcription error: \(error.localizedDescription)")
               return
           }
           
           if let result = result, result.isFinal {
               DispatchQueue.main.async {
                   for segment in result.bestTranscription.segments {
                       let word = segment.substring
                       let timestamp = segment.timestamp
                       self.transcriptionTimestamps[timestamp] = word
                   }
                   let sortedTimestamps = self.transcriptionTimestamps.sorted { $0.key < $1.key }
                   var formattedTimestamps: [String: String] = [:]
                   for (key, value) in sortedTimestamps {
                       let timestampString = String(format: "%02d:%02d:%02d", Int(key) / 3600, (Int(key) % 3600) / 60, Int(key) % 60)
                       formattedTimestamps[timestampString] = value.replacingOccurrences(of: "\'", with: "")
                   }
                   print(formattedTimestamps)
                   let timestamps = formattedTimestamps.map { $0.key }
                   self.getResults(timestamps: timestamps, sceneRanges: self.flatSceneRanges)
               }
           }
       }
   }
    func setupSteppers() {
        numberOfClipsStepper.minimumValue = 1
        numberOfClipsStepper.maximumValue = 10
        numberOfClipsStepper.stepValue = 1
        numberOfClipsStepper.value = 1
        numberOfClipsStepperLabel.text = "\(Int(numberOfClipsStepper.value))"

        numberOfClipsStepper.addTarget(self, action: #selector(numberOfClipsStepperChanged(_:)), for: .valueChanged)
    }
    
    @objc func numberOfClipsStepperChanged(_ sender: UIStepper) {
        numberOfClipsStepperLabel.text = "\(Int(sender.value))"
    }
    
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
    

    private func playVideo(url: URL) {
        if player != nil{
            player?.replaceCurrentItem(with: nil)
            player = nil
        }
        player = AVPlayer(url: url)
        let resetPlayer                  = {
            self.player?.seek(to: CMTime.zero)
                    self.player?.play()
                }
        playerObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: nil) { notification in resetPlayer() }
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
        guard let videoURL = videoList.first else {
            print("No video selected")
            return
        }
        

        let minimumClipDuration = minutesPicker.selectedRow(inComponent: 0)*60 + secondsPicker.selectedRow(inComponent: 0)
        processVideoForScenes(videoPath: videoURL.path, minimumClipDuration: minimumClipDuration)
        
        let finalSceneRanges = scenes.map { $0.start...$0.end }
        flatSceneRanges = finalSceneRanges.map { range in
            [range.lowerBound, range.upperBound]
        }
        extractAudioAndTranscribe(from: videoURL)
    }
    
    func exportClip(from videoURL: URL, timestamps: [Double]) {
        let asset = AVAsset(url: videoURL)
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to find the documents directory")
            return
        }
        
        let projectDirectory = documentsDirectory.appendingPathComponent(projectNameTrim)
        let clipsDirectory = projectDirectory.appendingPathComponent("Clips")
        
        if !FileManager.default.fileExists(atPath: clipsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: clipsDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create 'Clips' folder: \(error.localizedDescription)")
                return
            }
        }
        
        for i in 0..<(timestamps.count - 1) {
            let startTime = CMTime(seconds: timestamps[i], preferredTimescale: 600)
            let endTime = CMTime(seconds: timestamps[i + 1], preferredTimescale: 600)
            
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
            exportSession?.outputFileType = .mp4
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmm"
            let currentTimeString = dateFormatter.string(from: Date())
            let outputURL = clipsDirectory.appendingPathComponent("clip_\(i)_\(currentTimeString).mp4")
            
            exportSession?.outputURL = outputURL
            exportSession?.timeRange = CMTimeRange(start: startTime, end: endTime)
            
            exportSession?.exportAsynchronously {
                switch exportSession?.status {
                case .completed:
                    print("Clip \(i) exported successfully to: \(outputURL)")
                case .failed:
                    print("Failed to export clip \(i): \(String(describing: exportSession?.error))")
                case .cancelled:
                    print("Export cancelled for clip \(i)")
                default:
                    break
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == trimSeguePreviewIdentifier {
            if let destinationVC = segue.destination as? TrimVideoPreviewViewController {
                //generateClips()
                guard let videoURL = videoList.first else {
                            print("No video available for clipping")
                            return
                        }
                        let numberOfClips = Int(numberOfClipsStepper.value)
                        if let timestamps = generateEvenClipTimestamps(for: videoURL, numberOfClips: numberOfClips) {
                            self.clipTimestamps = timestamps
                            exportClip(from: videoURL, timestamps: timestamps)
                        } else {
                            print("Failed to generate clip timestamps")
                        }
                destinationVC.trimPreviewProjectName = projectNameTrim
            }
        }
    }
    
    // New helper function to generate even clip timestamps.
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
    
    func processVideoForScenes(videoPath: String, minimumClipDuration:Int) {
    let scenesArray = NSMutableArray()
    
        if let error = CV.detectSceneChanges(videoPath, scenes: scenesArray, minDuration: Double(minimumClipDuration)) {
        if error.hasError {
            print("Error detecting scenes: \(error.message ?? "")")
            return
        }
        
        let scenes = scenesArray.compactMap { $0 as? SceneRange }
        self.scenes = scenes
    }
    }
    
    func getResults(timestamps: [String], sceneRanges: [[Double]]) {
        let apiURL = URL(string: "https://gvnn439j-8000.inc1.devtunnels.ms/getClipTimeStamps")!
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "transcript": timestamps,
            "sceneChanges": sceneRanges
        ] as [String : Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    print("API Error: \(error)")
                    return
                }
                
                if let data = data {
                    do {
                        if let timestamps = try JSONSerialization.jsonObject(with: data) as? [Double],
                           let videoURL = self?.videoList.first {
                            DispatchQueue.main.async {
                                self?.clipTimestamps = timestamps
                                self?.exportClip(from: videoURL, timestamps: timestamps)
                            }
                        }
                    } catch {
                        print("JSON parsing error: \(error)")
                    }
                }
            }
            task.resume()
        } catch {
            print("JSON serialization error: \(error)")
        }
    }
}



extension TrimViewController {
    @objc func keyboard(notification: Notification) {

//        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
//        
//        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
//            self.view.frame.origin.y = -keyboardRect.height
//        } else {
//            self.view.frame.origin.y = 0
//        }
    }
}
