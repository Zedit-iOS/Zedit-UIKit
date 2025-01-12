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
    var loadingIndicator: UIAlertController?
    var checkClipsTimer: Timer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show the loading pop-up
        showLoadingIndicator()
        
        // Start checking for videos every 10 seconds
        checkClipsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(checkForVideos), userInfo: nil, repeats: true)
        
        // Set up the collection view
        vidoListCollectionView.setupCollectionView(in: view)
        vidoListCollectionView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        // Invalidate the timer when the view controller is deallocated
        checkClipsTimer?.invalidate()
    }
    
    @objc func checkForVideos() {
        if let videos = fetchVideos(), !videos.isEmpty {
            videoList = videos
            vidoListCollectionView.videoList = videos
            vidoListCollectionView.reloadData()
            
            print("Videos successfully loaded")
            
            // Stop the timer and hide the loading indicator
            checkClipsTimer?.invalidate()
            checkClipsTimer = nil
            hideLoadingIndicator()
        } else {
            print("No videos found in the 'Clips' folder yet")
        }
    }
    
    func fetchVideos() -> [URL]? {
        guard let project = getProjects(ProjectName: trimPreviewProjectName) else {
            print("Failure: Could not retrieve project")
            return nil
        }
        
        if let clipsFolder = project.subfolders.first(where: { $0.name.lowercased() == "clips" }) {
            return clipsFolder.videoURLS
        }
        
        return []
    }

    func getProjects(ProjectName: String) -> Project? {
        let fileManager = FileManager.default
        
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let projectDirectory = documentsDirectory.appendingPathComponent(ProjectName)
        guard fileManager.fileExists(atPath: projectDirectory.path) else {
            return nil
        }
        
        do {
            let predefinedSubfolderNames = ["Original Videos", "Clips", "Colour Graded Videos"]
            var subfolders: [Subfolder] = []
            
            for subfolderName in predefinedSubfolderNames {
                let subfolderPath = projectDirectory.appendingPathComponent(subfolderName)
                var videoURLs: [URL] = []
                
                if fileManager.fileExists(atPath: subfolderPath.path) {
                    let videoFiles = try fileManager.contentsOfDirectory(at: subfolderPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    videoURLs = videoFiles.filter { ["mp4", "mov"].contains($0.pathExtension.lowercased()) }
                }
                
                subfolders.append(Subfolder(name: subfolderName, videos: videoURLs))
            }
            
            return Project(name: ProjectName, subfolders: subfolders)
        } catch {
            print("Error reading project folder: \(error.localizedDescription)")
            return nil
        }
    }

    private func showLoadingIndicator() {
        loadingIndicator = UIAlertController(title: "Loading", message: "Checking for videos...", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        loadingIndicator?.view.addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: loadingIndicator!.view.centerXAnchor).isActive = true
        spinner.bottomAnchor.constraint(equalTo: loadingIndicator!.view.bottomAnchor, constant: -20).isActive = true
        
        if let loadingIndicator = loadingIndicator {
            present(loadingIndicator, animated: true, completion: nil)
        }
    }

    private func hideLoadingIndicator() {
        loadingIndicator?.dismiss(animated: true, completion: nil)
        loadingIndicator = nil
    }
    
    private func playVideo(url: URL) {
        if player != nil {
            player?.replaceCurrentItem(with: nil)
            player = nil
        }
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true
        
        videoPlayerView.subviews.forEach { $0.removeFromSuperview() }
        
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
