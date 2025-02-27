
//
//  MainPageViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 31/10/24.
//

import UIKit
import AVKit

class MainPageViewController: UIViewController {
    
    @IBOutlet weak var videoSelector: UIButton!
    @IBOutlet weak var videoPreviewView: UIView!
    
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var videoScrubber: UIScrollView!
    
    fileprivate var playerObserver: Any?
    
    var projectname = String()
    var videoList: [URL] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    let trimSegueIdentifier = "Trim"
    var playheadIndicator: UIView!
    var sliderIndicator: UIView!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let project = getProject(projectName: projectname) {
            videoList = project.subfolders.flatMap { $0.videoURLS }
            print("Videos successfully loaded: \(videoList.count) videos found.")
            setUpButton()
            if let firstVideo = videoList.first {
                playVideo(url: firstVideo)
            }
        } else {
            print("Failed to load project.")
        }
        do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Error setting up AVAudioSession: \(error.localizedDescription)")
            }
        
        navigationItem.title = projectname
        self.navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(title: " Back", style: .plain, target: self, action: #selector(backButtonTapped))
        self.navigationItem.leftBarButtonItem = backButton
        
        setupPlayheadIndicator()
                setupGestureRecognizer()
                generateThumbnails()
        
    }
    
    func setupSwipeGesture() {
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipeLeft.direction = .left
            videoScrubber.addGestureRecognizer(swipeLeft)
        }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            guard let player = player, let duration = player.currentItem?.duration.seconds else { return }
            let currentTime = player.currentTime().seconds
            let newTime = CMTime(seconds: min(currentTime + 5, duration), preferredTimescale: 600)
            player.seek(to: newTime)
        }
    
//    func setupSliderIndicator() {
//        sliderIndicator = UIView()
//        sliderIndicator.backgroundColor = .white
//        sliderIndicator.frame = CGRect(x: 0, y: 0, width: 2, height: videoScrubber.bounds.height)
//        videoScrubber.addSubview(sliderIndicator)
//        
//        // Bring indicator to the front
//        videoScrubber.bringSubviewToFront(sliderIndicator)
//    }
    
    func generateThumbnails() {
        guard let firstVideo = videoList.first else { return }
        let asset = AVAsset(url: firstVideo)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let duration = Int(CMTimeGetSeconds(asset.duration))  // Total seconds of video
        let interval = 1  // Generate one thumbnail per second

        var times = [NSValue]()
        for i in 0..<duration {
            let cmTime = CMTime(seconds: Double(i) * Double(interval), preferredTimescale: 600)
            times.append(NSValue(time: cmTime))
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var xOffset: CGFloat = 0
            let thumbnailWidth: CGFloat = 60  // Thumbnail width
            let spacing: CGFloat = 1  // Space between thumbnails

            imageGenerator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, result, error in
                if let image = image, error == nil {
                    DispatchQueue.main.async {
                        let thumbnailImage = UIImage(cgImage: image)
                        let imageView = UIImageView(image: thumbnailImage)
                        imageView.frame = CGRect(x: xOffset, y: 0, width: thumbnailWidth, height: self.videoScrubber.bounds.height)
                        
                        self.videoScrubber.addSubview(imageView)
                        xOffset += thumbnailWidth + spacing  // Move x position with spacing

                        self.videoScrubber.contentSize = CGSize(width: xOffset, height: self.videoScrubber.bounds.height)
                    }
                }
            }
        }
    }

    @objc func backButtonTapped(){
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    func setupGestureRecognizer() {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            videoScrubber.addGestureRecognizer(panGesture)
        }
        
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: videoScrubber)
        
        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
        
        let maxOffset = videoScrubber.contentSize.width - videoScrubber.bounds.width
        let progress = min(max(0, videoScrubber.contentOffset.x - translation.x), maxOffset) / maxOffset  // 🔄 Inverted Direction
        let newTime = CMTime(seconds: duration * Double(progress), preferredTimescale: 600)
        
        player?.seek(to: newTime)
        
        // Move scrubber & reset gesture translation
        videoScrubber.contentOffset.x -= translation.x  // 🔄 Inverted Direction
        gesture.setTranslation(.zero, in: videoScrubber)
        
        updatePlayheadPosition()
    }
//    func setUpSliderConstraints() {
//            videoSlider.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                videoSlider.centerXAnchor.constraint(equalTo: videoScrubber.centerXAnchor),
//                videoSlider.widthAnchor.constraint(equalTo: videoScrubber.widthAnchor, multiplier: 0.9),
//                videoSlider.centerYAnchor.constraint(equalTo: videoScrubber.centerYAnchor),
//                videoSlider.heightAnchor.constraint(equalToConstant: 30)
//            ])
//        }
        
        // MARK: - Playhead Indicator
    func setupPlayheadIndicator() {
        playheadIndicator = UIView()
        playheadIndicator.backgroundColor = .red
        playheadIndicator.frame = CGRect(x: 0, y: 0, width: 20, height: 40)
        videoScrubber.addSubview(playheadIndicator)
        
        // Ensure it's in front of thumbnails
        videoScrubber.bringSubviewToFront(playheadIndicator)
    }
    func updatePlayheadPosition() {
            guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
            let currentTime = player?.currentTime().seconds ?? 0
            
            let progress = CGFloat(currentTime / duration)
            let maxX = videoScrubber.contentSize.width - playheadIndicator.frame.width
            playheadIndicator.frame.origin.x = progress * maxX
        }
        // MARK: - Sync Slider with Video
    @objc func sliderValueChanged(_ sender: UISlider) {
            guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
            let newTime = CMTime(seconds: duration * Double(sender.value), preferredTimescale: 600)
            player?.seek(to: newTime)
        }
    
    func observePlayerTime() {
            player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
                self?.updatePlayheadPosition()
            }
        }
    
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        if let project = getProject(projectName: projectname) {
//            videoList = project.subfolders.flatMap { $0.videoURLS }
//            print("Videos successfully loaded: \(videoList.count) videos found.")
//            setUpButton()
//            if let firstVideo = videoList.first {
//                playVideo(url: firstVideo)
//            }
//        } else {
//            print("Failed to load project.")
//        }
//        do {
//                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
//                try AVAudioSession.sharedInstance().setActive(true)
//            } catch {
//                print("Error setting up AVAudioSession: \(error.localizedDescription)")
//            }
//        
//        navigationItem.title = projectname
//    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
            if player != nil{
                player?.pause()
                player?.replaceCurrentItem(with: nil)
                player = nil
            }
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
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
    
    func setUpButton() {
        guard !videoList.isEmpty else {
            videoSelector.isEnabled = false
            return
        }
        
        videoSelector.isEnabled = true
        let actionClosure = { (action: UIAction) in
            if let selectedVideo = self.videoList.first(where: { $0.lastPathComponent == action.title }) {
                self.playVideo(url: selectedVideo)
            }
        }
        
        var menuChildren: [UIMenuElement] = []
        for videoURL in videoList {
            menuChildren.append(UIAction(title: videoURL.lastPathComponent, handler: actionClosure))
        }
        
        videoSelector.menu = UIMenu(options: .displayInline, children: menuChildren)
        videoSelector.showsMenuAsPrimaryAction = true
    }
    
    func playVideo(url: URL) {
            if player != nil {
                player?.replaceCurrentItem(with: nil)
                player = nil
            }
            player = AVPlayer(url: url)
            observePlayerTime()

            playerViewController = AVPlayerViewController()
            playerViewController?.player = player
            playerViewController?.showsPlaybackControls = true

            videoPreviewView.subviews.forEach { $0.removeFromSuperview() }

            if let playerVC = playerViewController {
                addChild(playerVC)
                playerVC.view.frame = videoPreviewView.bounds
                videoPreviewView.addSubview(playerVC.view)
                playerVC.didMove(toParent: self)
            }

            player?.play()
        }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == trimSegueIdentifier,
           let destination = segue.destination as? TrimViewController {
            player?.pause()
            destination.projectNameTrim = projectname
        } else if segue.identifier == "Export",
                  let destination = segue.destination as? ExportViewController {
            player?.pause()
            destination.projectname = projectname
        } else if segue.identifier == "colorGrade",
                  let destination = segue.destination as? ColorViewController {
            player?.pause()
            destination.projectNameColorGrade = projectname
        }
    }
    
    @IBAction func myUnwindAction(unwindSegue: UIStoryboardSegue) {
        if unwindSegue.identifier == "generateUnwind",
           let sourceVC = unwindSegue.source as? TrimViewController {
            projectname = sourceVC.projectNameTrim
            if let project = getProject(projectName: projectname) {
                videoList = project.subfolders.flatMap { $0.videoURLS }
                setUpButton()
                print("Data updated:", videoList)
            }
        } else if unwindSegue.identifier == "ExportCancel",
                  let sourceVC = unwindSegue.source as? ExportViewController {
            print("Returned from ExportViewController without making changes.")
        } else {
            print("Cancelled without changes.")
        }
    }
}
