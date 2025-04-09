//
//  collection.swift
//  Zedit-UIKit
//
//  Created by Avinash on 10/03/25.
//


import UIKit
import AVKit
import AVFoundation

extension ColorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as? ColorCollectionViewCell else {
            return UICollectionViewCell()
        }
        let videoURL = videoList[indexPath.item]
        cell.configure(with: videoURL)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedVideo = videoList[indexPath.item]
        print("Playing video from collection: \(selectedVideo)")
        DispatchQueue.global(qos: .userInitiated).async {
                    self.loadVideo(url: selectedVideo)
                    self.generateThumbnails(for: selectedVideo)
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
            controlsContainer.leftAnchor.constraint(equalTo: videoScrubberView.leftAnchor),
            controlsContainer.rightAnchor.constraint(equalTo: videoScrubberView.rightAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: videoScrubberView.topAnchor, constant: 0),
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
    
    func setupCollectionView() {
        collectionView.collectionViewLayout = generateLayout()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ColorCollectionViewCell.self, forCellWithReuseIdentifier: "ColorCell")
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
        videoScrubberView.gestureRecognizers?.forEach { videoScrubberView.removeGestureRecognizer($0) }
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipeLeft.direction = .left
        videoScrubberView.addGestureRecognizer(swipeLeft)
        }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            guard let player = player, let duration = player.currentItem?.duration.seconds else { return }
            let currentTime = player.currentTime().seconds
            let newTime = CMTime(seconds: min(currentTime + 5, duration), preferredTimescale: 600)
            player.seek(to: newTime)
        }
    

    
    func generateThumbnails(for videoURL:URL) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)

        let duration = Int(CMTimeGetSeconds(asset.duration))  // Total seconds of video
        let interval = 1  // Generate one thumbnail per second

        var times = [NSValue]()
        for i in 0..<duration {
            let cmTime = CMTime(seconds: Double(i) * Double(interval), preferredTimescale: 600)
            times.append(NSValue(time: cmTime))
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var xOffset: CGFloat = self.videoScrubberView.frame.midX - (self.playheadIndicator.frame.width/2)// Start at playhead position
            let thumbnailWidth: CGFloat = 60  // Thumbnail width
            let spacing: CGFloat = 1  // Space between thumbnails

            imageGenerator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, result, error in
                if let image = image, error == nil {
                    DispatchQueue.main.async {
                        let thumbnailImage = UIImage(cgImage: image)
                        let imageView = UIImageView(image: thumbnailImage)
                        imageView.layer.borderColor = UIColor.lightGray.cgColor
                        imageView.layer.borderWidth = 3
                        imageView.frame = CGRect(x: xOffset, y: 0, width: thumbnailWidth, height: self.videoScrubberView.bounds.height)
                        
                        self.videoScrubberView.addSubview(imageView)
                        xOffset += thumbnailWidth + spacing  // Move x position with spacing

                        self.videoScrubberView.contentSize = CGSize(width: xOffset, height: self.videoScrubberView.bounds.height)
                        
                        // Align scroll position so playhead points to the first frame
                        if xOffset == self.playheadIndicator.frame.origin.x {
                            self.videoScrubberView.contentOffset.x = xOffset - (self.videoScrubberView.frame.width / 2)
                        }
                    }
                }
            }
        }
    }

    
    func setupGestureRecognizer() {
        videoScrubberView.gestureRecognizers?.forEach { videoScrubberView.removeGestureRecognizer($0) }
            
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        videoScrubberView.addGestureRecognizer(panGesture)
        }
        
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: videoScrubberView)
        let newOffset = videoScrubberView.contentOffset.x - translation.x
        
        videoScrubberView.contentOffset.x = max(0, min(newOffset, videoScrubberView.contentSize.width - videoScrubberView.bounds.width))
        
        gesture.setTranslation(.zero, in: videoScrubberView)
        
        updatePlayheadPosition()
    }
    
    func setupPlayheadIndicator() {
        playheadIndicator = UIView()
        playheadIndicator.backgroundColor = .yellow
        playheadIndicator.frame = CGRect(x: videoScrubberView.frame.midX - 1, y: videoScrubberView.frame.origin.y, width: 2, height: videoScrubberView.bounds.height)
        
        self.view.addSubview(playheadIndicator)
        self.view.bringSubviewToFront(playheadIndicator)
    }
    
    
    func updatePlayheadPosition() {
        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
        
        let maxOffset = videoScrubberView.contentSize.width - videoScrubberView.bounds.width
        let progress = min(max(videoScrubberView.contentOffset.x / maxOffset, 0), 1) // Normalize
        let newTime = CMTime(seconds: duration * Double(progress), preferredTimescale: 600)
        
        player?.seek(to: newTime)
    }
    // MARK: - Sync Slider with Video
    @objc func playerSliderValueChanged(_ sender: UISlider) {
            guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
            let newTime = CMTime(seconds: duration * Double(sender.value), preferredTimescale: 600)
            player?.seek(to: newTime)
        }
    
    func observePlayerTime() {
            player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
                self?.updatePlayheadPosition()
            }
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
        videoPlayer.subviews.forEach { $0.removeFromSuperview() }
        
        // Add AVPlayerViewController view to the container
        if let playerVC = playerViewController {
            addChild(playerVC)
            playerVC.view.frame = videoPlayer.bounds
            videoPlayer.addSubview(playerVC.view)
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
                if self.videoScrubberView.contentSize.width > self.videoScrubberView.bounds.width {
                    let maxOffset = self.videoScrubberView.contentSize.width - self.videoScrubberView.bounds.width
                    let newOffset = CGFloat(progress) * maxOffset
                    
                    // Only update if significantly different to avoid jerky updates
                    if abs(self.videoScrubberView.contentOffset.x - newOffset) > 2.0 {
                        self.videoScrubberView.contentOffset.x = newOffset
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
    
    
}
