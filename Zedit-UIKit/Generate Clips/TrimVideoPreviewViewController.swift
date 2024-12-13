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
        
        // Fetch videos from all subfolders of the project
        if let videos = fetchVideos() {
            videoList = videos
            vidoListCollectionView.videoList = videos
            print("Videos successfully loaded")
            vidoListCollectionView.reloadData()
        }
        
        print("Project name is \(trimPreviewProjectName)")
        vidoListCollectionView.setupCollectionView(in: view)
        
        // Set the delegate to handle video selection
        vidoListCollectionView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func fetchVideos() -> [URL]? {
        guard let project = getProjects(ProjectName: trimPreviewProjectName) else {
            print("Failure: Could not get project")
            return nil
        }

        // Fetch videos only from the "clips" folder
        if let clipsFolder = project.subfolders.first(where: { $0.name == "clips" }) {
            print("Found \(clipsFolder.videoURLS.count) videos in the clips folder")
            return clipsFolder.videoURLS
        }

        print("No clips folder found")
        return []
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
            // Initialize the project object
            var subfolders: [Subfolder] = []
            
            // Iterate through subfolders
            let subfolderURLs = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for subfolderURL in subfolderURLs where subfolderURL.hasDirectoryPath {
                let videoFiles = try fileManager.contentsOfDirectory(at: subfolderURL, includingPropertiesForKeys: nil, options: [])
                    .filter { $0.pathExtension == "mp4" || $0.pathExtension == "mov" }
                
                // Append to subfolders array
                subfolders.append(Subfolder(name: subfolderURL.lastPathComponent, videos: videoFiles))
            }
            
            return Project(name: ProjectName, subfolders: subfolders)
        } catch {
            print("Failed to fetch subfolders or files")
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
