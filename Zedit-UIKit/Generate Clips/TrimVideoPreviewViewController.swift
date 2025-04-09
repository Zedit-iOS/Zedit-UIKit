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
    var videoToClip: URL?
    var numberOfClips: Int = 1
    var minuites: Int = 3
    var seconds: Int = 5
    var isCreatingScenes = false
    var isCreatingTimestamps = false
    var isLLmProcessing = false
    var isCreatingClips = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showLoadingIndicator()
        checkClipsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(checkForVideos), userInfo: nil, repeats: true)
        
        
        
    }
    
    
    func updateLoadingMessage(_ message: String) {
        DispatchQueue.main.async {
            guard let loadingAlert = self.loadingIndicator else { return }
            // Create a new attributed string for the message with the original (non-bold) font size.
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15)
            ]
            let attributedMsg = NSAttributedString(string: message, attributes: messageAttributes)
            loadingAlert.setValue(attributedMsg, forKey: "attributedMessage")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global(qos: .userInitiated).async {
            generateClips(VideoURL: self.videoToClip!, minuites: self.minuites, seconds: self.seconds, numberOfClips: self.numberOfClips, projectName: self.trimPreviewProjectName, isCreatingScenes: self.isCreatingScenes, isLLmProcessing: self.isLLmProcessing, isCreatingTimestamps: self.isCreatingTimestamps, isCreatingClips: self.isCreatingClips, delegate: self)
        }
        
        vidoListCollectionView.setupCollectionView(in: view)
        vidoListCollectionView.delegate = self
        vidoListCollectionView.backgroundColor = .black
        
        // Start checking for videos every 10 seconds

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
            if player != nil{
                player?.replaceCurrentItem(with: nil)
                player = nil
            }
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
        // Create the alert without any title or message initially.
        loadingIndicator = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        // Set attributed title with a larger bold font.
        let titleText = "Loading"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        let attributedTitle = NSAttributedString(string: titleText, attributes: titleAttributes)
        loadingIndicator?.setValue(attributedTitle, forKey: "attributedTitle")
        
        // Set attributed message with a smaller, non-bold font (using system font).
        let messageText = "Checking for videos..."
        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15)
        ]
        let attributedMessage = NSAttributedString(string: messageText, attributes: messageAttributes)
        loadingIndicator?.setValue(attributedMessage, forKey: "attributedMessage")
        
        // Increase the alert controller's height by adding an extra height constraint.
        // Adjust the constant as necessary for the desired height.
        loadingIndicator?.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        
        // Setup the spinner
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        // Add spinner as a subview to the alert's view.
        loadingIndicator?.view.addSubview(spinner)
        
        // Position the spinner below the title/message using Auto Layout.
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loadingIndicator!.view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: loadingIndicator!.view.topAnchor, constant: 70)
        ])
        
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
