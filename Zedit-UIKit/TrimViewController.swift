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
    @IBOutlet weak var promptTextField: UITextField!
    @IBOutlet weak var numberOfClipsTextField: UITextField!
    
    @IBOutlet weak var generateButton: UIButton!
    
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = projectNameTrim
        if let videos = fetchVideos() {
            videoList = videos
            setUpButton()
        }
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
        guard let videoURL = videoList.first,
              let numberOfClips = Int(numberOfClipsTextField.text ?? "0"), numberOfClips > 0 else {
            print("Invalid input for video or number of clips")
            return
        }
        
        let asset = AVAsset(url: videoURL)
        let totalDuration = CMTimeGetSeconds(asset.duration)
        let clipDuration = totalDuration / Double(numberOfClips)
        
        for i in 0..<numberOfClips {
            let startTime = CMTime(seconds: clipDuration * Double(i), preferredTimescale: asset.duration.timescale)
            let endTime = CMTime(seconds: clipDuration * Double(i + 1), preferredTimescale: asset.duration.timescale)
            exportClip(from: videoURL, startTime: startTime, endTime: endTime, index: i)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "update" {
            // Call generateClips before performing the segue
            generateClips()
            
            // Pass the projectNameTrim back to MainPageViewController if needed
            if let destinationVC = segue.destination as? MainPageViewController {
                destinationVC.projectname = projectNameTrim
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
