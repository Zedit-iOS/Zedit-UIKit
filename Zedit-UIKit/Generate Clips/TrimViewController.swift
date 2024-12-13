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
        
        if let project = getProject(projectName: projectNameTrim) {
            // Aggregate videos from all subfolders
            videoList = project.subfolders.flatMap { $0.videoURLS }
            setUpButton()
        }
        
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
        let fileManager = FileManager.default
        
        // Locate the "Clips" subfolder in the project directory
        let clipsFolder = videoURL.deletingLastPathComponent().appendingPathComponent("Clips")
        
        // Create the "Clips" folder if it doesn't exist
        if !fileManager.fileExists(atPath: clipsFolder.path) {
            do {
                try fileManager.createDirectory(at: clipsFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create 'Clips' folder: \(error.localizedDescription)")
                return
            }
        }
        
        let outputURL = clipsFolder.appendingPathComponent("clip_\(index).mp4")
        
        // Prepare for export
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mp4
        exportSession?.outputURL = outputURL
        exportSession?.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        
        // Perform the export
        exportSession?.exportAsynchronously {
            if exportSession?.status == .completed {
                print("Clip exported successfully: \(outputURL)")
            } else {
                print("Failed to export clip: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
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
