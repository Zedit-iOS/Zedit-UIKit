
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
    
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate var playerObserver: Any?
    
//    private var playPauseButton: UIButton!
//    private var timeLabel: UILabel!

    
    
    var projectname = String()
    public var videoListHome: [URL] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    let trimSegueIdentifier = "Trim"
    var playheadIndicator: UIView!
    var sliderIndicator: UIView!
    private var playPauseButton = UIButton(type: .system)
    private var timeLabel: UILabel!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupCollectionView()
        if let project = getProject(projectName: projectname) {
                videoListHome = project.subfolders.flatMap { $0.videoURLS }
                collectionView.reloadData()
                print("Videos successfully loaded: \(videoListHome.count) videos found.")
                
                // Select first video from collection view by default
                if !videoListHome.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 0)
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                    playVideo(url: videoListHome[0])
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
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        
        setupPlayheadIndicator()
                setupGestureRecognizer()
                generateThumbnails()
        setupTimelineControls()
        styleViews()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
            // Add playheadIndicator to the appropriate superview if not already added
        playheadIndicator.translatesAutoresizingMaskIntoConstraints = false
           videoPreviewView.translatesAutoresizingMaskIntoConstraints = false
           videoScrubber.translatesAutoresizingMaskIntoConstraints = false
                   
           // Ensure playheadIndicator is added to the view hierarchy and brought to front
           if playheadIndicator.superview == nil {
               self.view.addSubview(playheadIndicator)
           }
           self.view.bringSubviewToFront(playheadIndicator)
                   
           // Set up constraints for playheadIndicator, including a width constraint
           NSLayoutConstraint.activate([
               // Anchor the top of playheadIndicator to the bottom of videoPreviewView with a 20-point offset
               playheadIndicator.topAnchor.constraint(equalTo: videoPreviewView.bottomAnchor, constant: 20),
               
               // Center playheadIndicator horizontally with videoScrubber
               playheadIndicator.centerXAnchor.constraint(equalTo: videoScrubber.centerXAnchor),
               
               // Match the height of playheadIndicator to the height of videoScrubber
               playheadIndicator.heightAnchor.constraint(equalTo: videoScrubber.heightAnchor),
               
               // Set a fixed width for playheadIndicator
               playheadIndicator.widthAnchor.constraint(equalToConstant: 2)
           ])
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateVideoList()
        collectionView.reloadData()
    }

    func updateVideoList() {
        if let project = getProject(projectName: projectname) {
            videoListHome = project.subfolders.flatMap { $0.videoURLS }
            print("Updated video count: \(videoListHome.count)")
        } else {
            print("Failed to update project")
        }
    }
    
    private func styleViews() {
        // Set the main background color
        view.backgroundColor = .black
        
        // Style video player views and slider view
        let viewsToStyle = [videoPreviewView]
        let cornerRadius: CGFloat = 12
        let borderWidth: CGFloat = 1
        let borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        let backgroundColor = UIColor(white: 0.15, alpha: 1.0) // Slightly lighter than black
        
        for view in viewsToStyle {
            guard let view = view else { continue }
            
            // Set corner radius
            view.layer.cornerRadius = cornerRadius
            view.layer.masksToBounds = true
            
            // Set border
            view.layer.borderWidth = borderWidth
            view.layer.borderColor = borderColor
            
            // Set background color
            view.backgroundColor = backgroundColor
            
            // Add padding for content inside
            view.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        // Special handling for playerView: No left & right insets
        
        
        // Ensure proper padding for video players
        adjustVideoPlayerLayouts()
    }
    
    private func adjustVideoPlayerLayouts() {
        // Adjust the player view controllers to respect margins
        if let playerView = playerViewController?.view {
            playerView.frame = videoPreviewView.bounds.insetBy(dx: 8, dy: 8)
        }
        
    }

    
    func setupTimelineControls() {
        // Create a container view above the scrubber
        let controlsContainer = UIView()
        controlsContainer.backgroundColor = UIColor(white: 0.1, alpha: 0)
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsContainer)
        
        // Position the container above the scrubber
        NSLayoutConstraint.activate([
            controlsContainer.leftAnchor.constraint(equalTo: videoScrubber.leftAnchor),
            controlsContainer.rightAnchor.constraint(equalTo: videoScrubber.rightAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: videoScrubber.topAnchor, constant: -25),
            controlsContainer.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Create play/pause button
        let playPauseButton = UIButton(type: .system)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        controlsContainer.addSubview(playPauseButton)
        // Create time label
        let timeLabel = UILabel()
        timeLabel.text = "00:00 / 00:00"
        timeLabel.textColor = .white
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.addSubview(timeLabel)
        
        // Position controls
        NSLayoutConstraint.activate([
            playPauseButton.leftAnchor.constraint(equalTo: controlsContainer.leftAnchor, constant: 15),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 40),
            playPauseButton.heightAnchor.constraint(equalToConstant: 40),
            
            timeLabel.leftAnchor.constraint(equalTo: playPauseButton.rightAnchor, constant: 15),
            timeLabel.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor)
        ])
        
        // Store references
        self.playPauseButton = playPauseButton
        self.timeLabel = timeLabel
    }

    @objc func togglePlayPause() {
        guard let player = player else { return }
        
        if player.rate == 0 {
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }

    func updateTimeDisplay() {
        guard let player = player,
              let currentItem = player.currentItem,
              let timeLabel = timeLabel else { return }
        
        let currentTime = player.currentTime().seconds
        let duration = currentItem.duration.seconds
        
        if !currentTime.isNaN && !duration.isNaN {
            let currentTimeString = formatTime(seconds: currentTime)
            let durationString = formatTime(seconds: duration)
            timeLabel.text = "\(currentTimeString) / \(durationString)"
        }
    }

    func formatTime(seconds: Double) -> String {
        let totalSeconds = Int(seconds.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    

//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//
//        // Position the playhead over the scrollView
//        playheadIndicator.frame.origin.x = videoScrubber.frame.midX - (playheadIndicator.frame.width / 2)
//        playheadIndicator.frame.size.height = videoScrubber.bounds.height
//    }
    
    func setupCollectionView() {
        collectionView.collectionViewLayout = generateLayout()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MainPageCollectionViewCell.self, forCellWithReuseIdentifier: "HomeCell")
        collectionView.backgroundColor = .black
    }

    
    func generateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(60),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(60),
                                               heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(8)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        section.orthogonalScrollingBehavior = .continuous
        
        return UICollectionViewCompositionalLayout(section: section)
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
    

    
    func generateThumbnails() {
        guard let firstVideo = videoListHome.first else { return }
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
            var xOffset: CGFloat = self.videoScrubber.frame.midX - (self.playheadIndicator.frame.width/2)// Start at playhead position
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
                        
                        // Align scroll position so playhead points to the first frame
                        if xOffset == self.playheadIndicator.frame.origin.x {
                            self.videoScrubber.contentOffset.x = xOffset - (self.videoScrubber.frame.width / 2)
                        }
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
        let newOffset = videoScrubber.contentOffset.x - translation.x
        
        videoScrubber.contentOffset.x = max(0, min(newOffset, videoScrubber.contentSize.width - videoScrubber.bounds.width))
        
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
        playheadIndicator.backgroundColor = .yellow
        playheadIndicator.frame = CGRect(x: videoScrubber.frame.midX - 1, y: videoScrubber.frame.origin.y, width: 2, height: videoScrubber.bounds.height)
        
        self.view.addSubview(playheadIndicator)
        self.view.bringSubviewToFront(playheadIndicator)
    }
    
    
    func updatePlayheadPosition() {
        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
        
        let maxOffset = videoScrubber.contentSize.width - videoScrubber.bounds.width
        let progress = min(max(videoScrubber.contentOffset.x / maxOffset, 0), 1) // Normalize
        let newTime = CMTime(seconds: duration * Double(progress), preferredTimescale: 600)
        
        player?.seek(to: newTime)
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
        guard !videoListHome.isEmpty else {
            videoSelector.isEnabled = false
            return
        }
        
        videoSelector.isEnabled = true
        let actionClosure = { (action: UIAction) in
            if let selectedVideo = self.videoListHome.first(where: { $0.lastPathComponent == action.title }) {
                self.playVideo(url: selectedVideo)
            }
        }
        
        var menuChildren: [UIMenuElement] = []
        for videoURL in videoListHome {
            menuChildren.append(UIAction(title: videoURL.lastPathComponent, handler: actionClosure))
        }
        
        videoSelector.menu = UIMenu(options: .displayInline, children: menuChildren)
        videoSelector.showsMenuAsPrimaryAction = true
    }
    
    func playVideo(url: URL) {
        // Remove any existing time observers
        if let observer = playerObserver {
            player?.removeTimeObserver(observer)
            playerObserver = nil
        }
        
        // Reset or create a new player
        if player == nil {
            player = AVPlayer(url: url)
        } else {
            let playerItem = AVPlayerItem(url: url)
            player?.replaceCurrentItem(with: playerItem)
        }
        
        print("Attempting to play: \(url)")
        
        // Reset the player view controller
        if playerViewController == nil {
            playerViewController = AVPlayerViewController()
            playerViewController?.showsPlaybackControls = false // Hide default controls
        }
        // Assign the player to the view controller
        playerViewController?.player = player
        
        // Remove any existing subviews in videoPreviewView
        videoPreviewView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add AVPlayerViewController view to the container
        if let playerVC = playerViewController {
            addChild(playerVC)
            playerVC.view.frame = videoPreviewView.bounds
            videoPreviewView.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)
        }
        
        // Add a new time observer
        playerObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main, using: { [weak self] time in
            guard let self = self else { return }
            
            // Update time label
            self.updateTimeDisplay()
            
            // Update playhead position based on current time
            if let duration = self.player?.currentItem?.duration.seconds, duration > 0 {
                let progress = time.seconds / duration
                
                // Calculate scrubber content offset based on video progress
                if self.videoScrubber.contentSize.width > self.videoScrubber.bounds.width {
                    let maxOffset = self.videoScrubber.contentSize.width - self.videoScrubber.bounds.width
                    let newOffset = CGFloat(progress) * maxOffset
                    
                    // Only update if significantly different to avoid jerky updates
                    if abs(self.videoScrubber.contentOffset.x - newOffset) > 2.0 {
                        self.videoScrubber.contentOffset.x = newOffset
                    }
                }
            }
        })
        
        // Update play/pause button state
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        
        // Play after a slight delay to ensure UI updates first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.player?.play()
        }
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
                
            } else if unwindSegue.identifier == "ExportCancel",
                      let sourceVC = unwindSegue.source as? ExportViewController {
                projectname = sourceVC.projectname
                print("Returned from ExportViewController without making changes.")
                
            } else if unwindSegue.identifier == "unwindPreview",
                      let sourceVC = unwindSegue.source as? TrimVideoPreviewViewController {
                projectname = sourceVC.trimPreviewProjectName
            }
            
            videoListHome.removeAll()
            
            if let project = getProject(projectName: projectname) {
                videoListHome = project.subfolders.flatMap { $0.videoURLS }
            
                
                // 5. Reload collection view with fresh data
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.reloadData()
                print("Videos successfully loaded: \(videoListHome.count) videos found.")
                
                // 6. (Optional) Select & play the first video
                if let firstVideo = videoListHome.first {
                    let indexPath = IndexPath(item: 0, section: 0)
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                    playVideo(url: firstVideo)
                }
                
            } else {
                print("Failed to load project.")
            }
        
        print("Unwind action complete.")
    }

}


extension MainPageViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoListHome.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeCell", for: indexPath) as? MainPageCollectionViewCell else {
            return UICollectionViewCell()
        }
        let videoURL = videoListHome[indexPath.item]
        cell.configure(with: videoURL)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedVideo = videoListHome[indexPath.item]
        print("Playing video from collection: \(selectedVideo)")
        playVideo(url: selectedVideo)
    }
}
