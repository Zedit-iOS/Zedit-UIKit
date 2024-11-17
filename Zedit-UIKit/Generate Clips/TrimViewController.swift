//
//  TrimViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 04/11/24.
//

import UIKit
import AVFoundation
import AVKit

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
        
        if let videos = fetchVideos() {
            videoList = videos
            setUpButton()
        }
        
//        promptTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func setupSteppers() {
        
        numberOfClipsStepper.minimumValue = 1
        numberOfClipsStepper.maximumValue = 10
        numberOfClipsStepper.stepValue = 1
        numberOfClipsStepper.value = 1
        numberOfClipsStepperLabel.text = "\(Int(numberOfClipsStepper.value))"
        
        // Configure maximum duration stepper
        maximumDurationOfClipsStepper.minimumValue = 30
        maximumDurationOfClipsStepper.maximumValue = 300
        maximumDurationOfClipsStepper.stepValue = 30
        maximumDurationOfClipsStepper.value = 30
        maximumDurationOfClipsStepperLabel.text = "\(Int(maximumDurationOfClipsStepper.value))s"
        
        // Add target actions for steppers
        numberOfClipsStepper.addTarget(self, action: #selector(numberOfClipsStepperChanged(_:)), for: .valueChanged)
        maximumDurationOfClipsStepper.addTarget(self, action: #selector(maximumDurationStepperChanged(_:)), for: .valueChanged)
    }
    
    @objc func numberOfClipsStepperChanged(_ sender: UIStepper) {
        numberOfClipsStepperLabel.text = "\(Int(sender.value))"
    }
    
    @objc func maximumDurationStepperChanged(_ sender: UIStepper) {
        maximumDurationOfClipsStepperLabel.text = "\(Int(sender.value))s"
    }
    
    func fetchVideos() -> [URL]? {
        guard let project = getProjects(ProjectName: projectNameTrim) else { return nil }
        return project.videos
    }
    
    func getProjects(ProjectName: String) -> Project? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let projectsDirectory = documentsDirectory.appendingPathComponent(ProjectName)
        guard fileManager.fileExists(atPath: projectsDirectory.path) else { return nil }
        
        do {
            let videoFiles = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil, options: []).filter {
                $0.pathExtension == "mp4" || $0.pathExtension == "mov"
            }
            return Project(name: ProjectName, videos: videoFiles)
        } catch {
            print("Failed to fetch files")
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
            self.playVideo(url: self.videoList.first { $0.lastPathComponent == action.title }!)
        }
        
        var menuChildren: [UIMenuElement] = []
        for videoName in videoList {
            menuChildren.append(UIAction(title: videoName.lastPathComponent, handler: actionClosure))
        }
        
        videoSelectorButton.menu = UIMenu(options: .displayInline, children: menuChildren)
        videoSelectorButton.showsMenuAsPrimaryAction = true
    }
    
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
        guard let videoURL = videoList.first else {
            print("Invalid input for video")
            return
        }
        
        let numberOfClips = Int(numberOfClipsStepper.value)
        let maximumDuration = Int(maximumDurationOfClipsStepper.value)
        let asset = AVAsset(url: videoURL)
        let totalDuration = CMTimeGetSeconds(asset.duration)
        
        
        let clipDuration = min(totalDuration / Double(numberOfClips), Double(maximumDuration))
        
        for i in 0..<numberOfClips {
            let startTime = CMTime(seconds: clipDuration * Double(i), preferredTimescale: asset.duration.timescale)
            let endTime = CMTime(seconds: min(clipDuration * Double(i + 1), totalDuration), preferredTimescale: asset.duration.timescale)
            exportClip(from: videoURL, startTime: startTime, endTime: endTime, index: i)
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
    
    func exportClip(from videoURL: URL, startTime: CMTime, endTime: CMTime, index: Int) {
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        exportSession?.outputFileType = .mp4
        let outputURL = videoURL.deletingLastPathComponent().appendingPathComponent("clip_\(index).mp4")
        exportSession?.outputURL = outputURL
        exportSession?.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                print("Clip \(index) saved at \(outputURL)")
            case .failed:
                print("Failed to save clip \(index): \(String(describing: exportSession?.error))")
            case .cancelled:
                print("Export cancelled for clip \(index)")
            default:
                break
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
    
//    @objc func textFieldDidChange(_ textField: UITextField) {
//        let isProjectNameValid = !(promptTextField.text?.isEmpty ?? true)
//        
//        let existingProjects = UserDefaults.standard.array(forKey: "projects") as? [[String: String]] ?? []
//        let projectNameExists = existingProjects.contains { $0["name"] == promptTextField.text }
        
//        generateButton.isEnabled = isProjectNameValid && !projectNameExists
//        
//        if projectNameExists {
//            nameLabel.isHidden = false
//            nameLabel.text = "Name already exists."
//        } else {
//            nameLabel.isHidden = true
//        }
//    }
}
