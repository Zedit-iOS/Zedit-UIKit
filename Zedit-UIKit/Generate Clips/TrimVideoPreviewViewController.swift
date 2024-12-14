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
            print("Failure: Could not retrieve project")
            return nil
        }
        
        // Filter videos from the "Clips" folder only
        if let clipsFolder = project.subfolders.first(where: { $0.name.lowercased() == "clips" }) {
            print("Found \(clipsFolder.videoURLS.count) videos in the 'Clips' folder")
            return clipsFolder.videoURLS
        }
        
        print("No 'Clips' folder found")
        return []
    }

    
    func getProjects(ProjectName: String) -> Project? {
        let fileManager = FileManager.default
        
        // Access the documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access documents directory")
            return nil
        }
        
        // Navigate to the project directory using the project name
        let projectDirectory = documentsDirectory.appendingPathComponent(ProjectName)
        guard fileManager.fileExists(atPath: projectDirectory.path) else {
            print("Project folder does not exist")
            return nil
        }
        
        do {
            // Initialize subfolders based on the expected folder structure
            let predefinedSubfolderNames = ["Original Videos", "Clips", "Colour Graded Videos"]
            var subfolders: [Subfolder] = []
            
            // Populate each subfolder with video files (if present)
            for subfolderName in predefinedSubfolderNames {
                let subfolderPath = projectDirectory.appendingPathComponent(subfolderName)
                var videoURLs: [URL] = []
                
                if fileManager.fileExists(atPath: subfolderPath.path) {
                    let videoFiles = try fileManager.contentsOfDirectory(at: subfolderPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    videoURLs = videoFiles.filter { ["mp4", "mov"].contains($0.pathExtension.lowercased()) }
                }
                
                // Append the subfolder with videos to the list
                subfolders.append(Subfolder(name: subfolderName, videos: videoURLs))
            }
            
            return Project(name: ProjectName, subfolders: subfolders)
        } catch {
            print("Error reading project folder: \(error.localizedDescription)")
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
