//
//  TrimVideoPreviewViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 15/11/24.
//

import UIKit
import AVKit
import AVFoundation

class TrimVideoPreviewViewController: UIViewController {
    
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var vidoListCollectionView: TrimVideoPreviewCollectionView! // Use the custom collection view
    
    var trimPreviewProjectName = String()
    var videoList: [URL] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let videos = fetchVideos() {
            videoList = videos
            vidoListCollectionView.videoList = videos
            print("Videos successfully loaded")
            vidoListCollectionView.reloadData()
        }
        
        print("Project name is \(String(describing: trimPreviewProjectName))")
        vidoListCollectionView.setupCollectionView(in: view)
        
        // Set the delegate to handle video selection
        vidoListCollectionView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func fetchVideos() -> [URL]? {
        if let project = getProjects(ProjectName: trimPreviewProjectName) {
            let videos = project.videos
            print("Success: Found \(videos.count) videos")
            return videos
        } else {
            print("Failure: Could not get project")
            return nil
        }
    }
    
    func getProjects(ProjectName: String) -> Project? {
        let fileManager = FileManager.default
        
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access directory")
            return nil
        }
        
        let projectsDirectory = documentsDirectory.appendingPathComponent(ProjectName)
        
        guard fileManager.fileExists(atPath: projectsDirectory.path) else {
            print("Folder does not exist")
            return nil
        }
        
        do {
            let videoFiles = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil, options: [])
                .filter { $0.pathExtension == "mp4" || $0.pathExtension == "mov" }
            
            return Project(name: ProjectName, videos: videoFiles)
        } catch {
            print("Failed to fetch files")
            return nil
        }
    }
    
    private func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true
        
        // Clear previous player views
        videoPlayerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Embed the video player
        if let playerVC = playerViewController {
            addChild(playerVC)
            playerVC.view.frame = videoPlayerView.bounds
            videoPlayerView.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)
        }
        
        player?.play()
    }
}

// MARK: - UICollectionViewDelegate
extension TrimVideoPreviewViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedVideoURL = vidoListCollectionView.videoList[safe: indexPath.item] else { return }
        playVideo(url: selectedVideoURL)
    }
}
