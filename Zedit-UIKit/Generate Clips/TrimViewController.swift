//
//  TrimViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 04/11/24.
//

import UIKit
import AVFoundation
import AVKit
import Speech

class TrimViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var videoList: [URL] = []
    var projectNameTrim = String()
    var videoURL: URL?
    private var scenes: [SceneRange] = []
    private var transcriptionTimestamps: [TimeInterval: String] = [:]
    private var clipTimestamps: [Double] = []
    private var isClipsPickerActive = false
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var videoSelectorView: UIView!
    @IBOutlet weak var videoSelectorButton: UIButton!
    
    @IBOutlet weak var generateButton: UIButton!

    @IBOutlet weak var numberOfClipsDisplayLabel: UILabel!
    
    @IBOutlet weak var clippingFocusSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var minuitesLabel: UILabel!
    
    
    @IBOutlet weak var secondsLabel: UILabel!
    
    private var playPauseButton = UIButton(type: .system)
    private var timeLabel: UILabel!
    
    
    @IBOutlet weak var videoScrubberView: UIScrollView!
    
    var playheadIndicator: UIView!
    var sliderIndicator: UIView!
    var separatorView: UIView!
    
    private var selectedMinutes: Int = 0
        private var selectedSeconds: Int = 0
    private var selectedClips: Int = 0
    
    private let minutesRange = Array(0...59)
    private let secondsRange = Array(0...59)
    private var flatSceneRanges: [[Double]] = []
    private var finalSceneTimeStamps: Array<Double> = [];
    
    fileprivate var playerObserver: Any?
    
//    private func setupPickers(  ) {
//        minutesPicker.delegate = self
//        minutesPicker.dataSource = self // Add dataSource
//        secondsPicker.delegate = self 
//        secondsPicker.dataSource = self // Add dataSource
//    }
//    
//    // Add required UIPickerViewDataSource methods
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//    
//    
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return pickerView == minutesPicker ? minutesRange.count : secondsRange.count
//    }
//    
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        let value = pickerView == minutesPicker ? minutesRange[row] : secondsRange[row]
//        return String(format: "%02d", value)
//    }
    let trimSeguePreviewIdentifier = "preview"
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = projectNameTrim
//        setupSteppers()
        //setupPickers()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition denied")
                case .restricted, .notDetermined:
                    print("Speech recognition not available")
                @unknown default:
                    fatalError("Unknown authorization status")
                }
            }
        setupCollectionView()
        if let project = getProject(projectName: projectNameTrim) {
                videoList = project.subfolders.flatMap { $0.videoURLS }
                collectionView.reloadData()
                print("Videos successfully loaded: \(videoList.count) videos found.")
                
                // Select first video from collection view by default
                if !videoList.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 0)
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                    playVideo(url: videoList[0])
                }
            } else {
                print("Failed to load project.")
            }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        setupPlayheadIndicator()
        setupGestureRecognizer()
        generateThumbnails(for: videoList.first!)
        setupTimelineControls()
        updateTimeLabels()
                
                // Add tap gesture to open picker popup
                let minutesTap = UITapGestureRecognizer(target: self, action: #selector(showTimePicker))
                let secondsTap = UITapGestureRecognizer(target: self, action: #selector(showTimePicker))
        let clipsTap = UITapGestureRecognizer(target: self, action: #selector(showClipsPicker))
        setupLabels()
                
                minuitesLabel.isUserInteractionEnabled = true
                secondsLabel.isUserInteractionEnabled = true
                minuitesLabel.addGestureRecognizer(minutesTap)
                secondsLabel.addGestureRecognizer(secondsTap)
        numberOfClipsDisplayLabel.isUserInteractionEnabled = true
        numberOfClipsDisplayLabel.addGestureRecognizer(clipsTap)
        styleViews()
        playheadIndicator.translatesAutoresizingMaskIntoConstraints = false
           videoSelectorView.translatesAutoresizingMaskIntoConstraints = false
        videoScrubberView.translatesAutoresizingMaskIntoConstraints = false
                   
           // Ensure playheadIndicator is added to the view hierarchy and brought to front
           if playheadIndicator.superview == nil {
               self.view.addSubview(playheadIndicator)
           }
           self.view.bringSubviewToFront(playheadIndicator)
                   
           // Set up constraints for playheadIndicator, including a width constraint
           NSLayoutConstraint.activate([
               // Anchor the top of playheadIndicator to the bottom of videoPreviewView with a 20-point offset
               playheadIndicator.topAnchor.constraint(equalTo: videoSelectorView.bottomAnchor, constant: 10),
               
               // Center playheadIndicator horizontally with videoScrubber
               playheadIndicator.centerXAnchor.constraint(equalTo: videoScrubberView.centerXAnchor),
               
               // Match the height of playheadIndicator to the height of videoScrubber
               playheadIndicator.heightAnchor.constraint(equalTo: videoScrubberView.heightAnchor),
               
               // Set a fixed width for playheadIndicator
               playheadIndicator.widthAnchor.constraint(equalToConstant: 2)
           ])
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
         
    }
    
    
        
        // Keep the separator updated when scrolling occurs.
    
    private func styleViews() {
        // Set the main background color
        view.backgroundColor = .black
        
        // Style video player views and slider view
        let viewsToStyle = [videoSelectorView]
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
            view.isUserInteractionEnabled = false
        }
        
        // Special handling for playerView: No left & right insets
        
        
        // Ensure proper padding for video players
        adjustVideoPlayerLayouts()
    }
    
    private func adjustVideoPlayerLayouts() {
        // Adjust the player view controllers to respect margins
        if let playerView = playerViewController?.view {
            playerView.frame = videoSelectorView.bounds.insetBy(dx: 8, dy: 8)
        }
        
    }
    
    private func setupLabels() {
        let labels = [minuitesLabel, secondsLabel, numberOfClipsDisplayLabel]
        for label in labels {
            label?.textAlignment = .center
            label?.clipsToBounds = true
            label?.font = UIFont.boldSystemFont(ofSize: 16)
            label?.textColor = .white
//            label?.backgroundColor = UIColor.darkGray // Set background color
//            label?.layer.borderColor = UIColor.lightGray.cgColor // Set border color
//            label?.layer.borderWidth = 2 // Border thickness
//            label?.layer.cornerRadius = 5 // Rounded corners
            label?.layer.masksToBounds = true
            
            // Set fixed width constraint to fit "59 min" or "59 sec"
            label?.translatesAutoresizingMaskIntoConstraints = false
            label?.widthAnchor.constraint(equalToConstant: 60).isActive = true
            label?.heightAnchor.constraint(equalToConstant: 30).isActive = true
        }
    }
    
    @objc private func showClipsPicker() {
        isClipsPickerActive = true
            let alert = UIAlertController(title: "Select number of clips", message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)
            
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            pickerView.frame = CGRect(x: 0, y: 50, width: 270, height: 150)
            
            // Pre-select current values
            pickerView.selectRow(selectedClips, inComponent: 0, animated: false)
            
            alert.view.addSubview(pickerView)
            
            let selectAction = UIAlertAction(title: "Select", style: .default) { _ in
                self.selectedClips = pickerView.selectedRow(inComponent: 0)
                self.updateClipLabels()
            }
            
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.isClipsPickerActive = false  // Reset flag on cancel
            }
            
            alert.addAction(selectAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        }
    
    @objc private func showTimePicker() {
        isClipsPickerActive = false
            let alert = UIAlertController(title: "Select Time", message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)
            
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            pickerView.frame = CGRect(x: 0, y: 50, width: 270, height: 150)
            
            // Pre-select current values
            pickerView.selectRow(selectedMinutes, inComponent: 0, animated: false)
            pickerView.selectRow(selectedSeconds, inComponent: 1, animated: false)
            
            alert.view.addSubview(pickerView)
            
            let selectAction = UIAlertAction(title: "Select", style: .default) { _ in
                self.selectedMinutes = pickerView.selectedRow(inComponent: 0)
                self.selectedSeconds = pickerView.selectedRow(inComponent: 1)
                self.updateTimeLabels()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(selectAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        }
    
    private func updateClipLabels(){
        numberOfClipsDisplayLabel.text = String(selectedClips)
    }
        
        private func updateTimeLabels() {
            minuitesLabel.text = String(format: "%02d min", selectedMinutes)
            secondsLabel.text = String(format: "%02d sec", selectedSeconds)
        }
        
        // MARK: - UIPickerView DataSource & Delegate
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return isClipsPickerActive ? 1 : 2// One for minutes, one for seconds
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            if isClipsPickerActive {
                    return 100 // Adjust the maximum number of clips as needed
                }
                return component == 0 ? minutesRange.count : secondsRange.count
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return String(format: "%02d", row)
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
            controlsContainer.bottomAnchor.constraint(equalTo: videoScrubberView.topAnchor, constant: -12),
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
        collectionView.register(TrimCollectionViewCell.self, forCellWithReuseIdentifier: "TrimCell")
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
        videoScrubberView.addGestureRecognizer(swipeLeft)
        }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            guard let player = player, let duration = player.currentItem?.duration.seconds else { return }
            let currentTime = player.currentTime().seconds
            let newTime = CMTime(seconds: min(currentTime + 5, duration), preferredTimescale: 600)
            player.seek(to: newTime)
        }
    

    
    func generateThumbnails(for videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let duration = Int(CMTimeGetSeconds(asset.duration))  // Total seconds of video
        let interval = 1  // Generate one thumbnail per second

        var times = [NSValue]()
        for i in 0..<duration {
            let cmTime = CMTime(seconds: Double(i) * Double(interval), preferredTimescale: 600)
            times.append(NSValue(time: cmTime))
        }

        // Optionally, clear previous thumbnails if needed:
        // self.videoScrubberView.subviews.forEach { $0.removeFromSuperview() }
        
        var xOffset: CGFloat = self.videoScrubberView.frame.midX - (self.playheadIndicator.frame.width / 2)

        DispatchQueue.global(qos: .userInitiated).async {
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


    @objc func backButtonTapped(){
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    func setupGestureRecognizer() {
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

    

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
            if player != nil{
                player?.replaceCurrentItem(with: nil)
                player = nil
            }
    }
    
    func setupPlayheadIndicator() {
        playheadIndicator = UIView()
        playheadIndicator.backgroundColor = .yellow
        playheadIndicator.frame = CGRect(x: videoScrubberView.frame.midX - 1, y: videoScrubberView.frame.origin.y, width: 2, height: videoScrubberView.bounds.height)
        
        self.view.addSubview(playheadIndicator)
        self.view.bringSubviewToFront(playheadIndicator)
    }
        
//        private func updateTimeLabels() {
//            minuitesLabel.text = String(format: "%02d min", selectedMinutes)
//            secondsLabel.text = String(format: "%02d sec", selectedSeconds)
//        }
        
        // MARK: - UIPickerView DataSource & Delegate
//        func numberOfComponents(in pickerView: UIPickerView) -> Int {
//            return isClipsPickerActive ? 1 : 2// One for minutes, one for seconds
//        }
        
//        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//            if isClipsPickerActive {
//                    return 100 // Adjust the maximum number of clips as needed
//                }
//                return component == 0 ? minutesRange.count : secondsRange.count
//        }
        
//        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//            return String(format: "%02d", row)
//        }
    
    
    func updatePlayheadPosition() {
        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
        
        let maxOffset = videoScrubberView.contentSize.width - videoScrubberView.bounds.width
        let progress = min(max(videoScrubberView.contentOffset.x / maxOffset, 0), 1) // Normalize
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

    
    func extractAudioAndTranscribe(from videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        guard let track = asset.tracks(withMediaType: .audio).first else {
            print("No audio track found in video.")
            return
        }
        
        let composition = AVMutableComposition()
        guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio,
                                                                       preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("Could not create audio composition track.")
            return
        }
        
        do {
            try audioCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration),
                                                      of: track,
                                                      at: .zero)
            
            let audioOutputURL = videoURL.deletingPathExtension().appendingPathExtension("m4a")
            // Remove any existing file
            try? FileManager.default.removeItem(at: audioOutputURL)
            
            guard let exportSession = AVAssetExportSession(asset: composition,
                                                           presetName: AVAssetExportPresetAppleM4A) else {
                print("Could not create export session.")
                return
            }
            exportSession.outputURL = audioOutputURL
            exportSession.outputFileType = .m4a
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("Audio extracted successfully to: \(audioOutputURL)")
                    
                    // 1. Check file existence and size
                    if FileManager.default.fileExists(atPath: audioOutputURL.path) {
                        do {
                            let fileAttributes = try FileManager.default.attributesOfItem(atPath: audioOutputURL.path)
                            if let fileSize = fileAttributes[.size] as? UInt64, fileSize > 0 {
                                print("Audio file exists and size: \(fileSize) bytes")
                            } else {
                                print("File exists but has zero size.")
                            }
                        } catch {
                            print("Failed to get file attributes: \(error.localizedDescription)")
                        }
                    } else {
                        print("Audio file does not exist at \(audioOutputURL.path)")
                    }
                    
                    // 2. Validate the exported audio asset
                    if self.validateAudioAsset(at: audioOutputURL) {
                        print("Audio asset validation passed.")
                    } else {
                        print("Audio asset validation failed.")
                    }
                    
                    // 3. Test decoding of the audio file
                    self.testAudioDecoding(url: audioOutputURL)
                    
                    // 4. Proceed with transcription
                    self.transcribeAudio(at: audioOutputURL)
                    
                case .failed:
                    print("Failed to export audio: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                    self.getResults(timestamps: [],
                                    sceneRanges: self.flatSceneRanges,
                                    videoURL: videoURL,
                                    numberOfClipsDisplayText: self.numberOfClipsDisplayLabel.text ?? "1")
                case .cancelled:
                    print("Audio export cancelled")
                default:
                    break
                }
            }
        } catch {
            print("Error extracting audio: \(error.localizedDescription)")
        }
    }

    func validateAudioAsset(at url: URL) -> Bool {
        let asset = AVAsset(url: url)
        let audioTracks = asset.tracks(withMediaType: .audio)
        
        guard !audioTracks.isEmpty else {
            print("No audio tracks found in the file.")
            return false
        }
        
        // Print out some details about the audio track
        if let track = audioTracks.first {
            for case let desc as CMAudioFormatDescription in track.formatDescriptions {
                if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee {
                    print("Sample rate: \(asbd.mSampleRate)")
                    print("Channels: \(asbd.mChannelsPerFrame)")
                }
            }
        }
        
        return true
    }

    func testAudioDecoding(url: URL) {
        let asset = AVAsset(url: url)
        guard let track = asset.tracks(withMediaType: .audio).first else {
            print("No audio track found for decoding.")
            return
        }
        
        do {
            let assetReader = try AVAssetReader(asset: asset)
            // Request uncompressed linear PCM output for testing
            let outputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1
            ]
            let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
            assetReader.add(trackOutput)
            
            assetReader.startReading()
            var sampleCount = 0
            while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                sampleCount += 1
                CMSampleBufferInvalidate(sampleBuffer)
            }
            
            if sampleCount > 0 {
                print("Audio file decoded successfully with \(sampleCount) samples read.")
            } else {
                print("No audio samples could be read from the file.")
            }
        } catch {
            print("Failed to create AVAssetReader: \(error.localizedDescription)")
        }
    }


    func transcribeAudio(at audioURL: URL) {
        // Ensure that the speech recognizer is available and authorized
        guard let recognizer = SFSpeechRecognizer() else {
            print("Speech recognizer not available")
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Transcription error: \(error.localizedDescription)")
                // Fallback using the original video URL
                self.getResults(timestamps: [],
                                sceneRanges: self.flatSceneRanges,
                                videoURL: self.videoURL!,
                                numberOfClipsDisplayText: self.numberOfClipsDisplayLabel.text ?? "1")
                return
            }
            
            if let result = result, result.isFinal {
                DispatchQueue.main.async {
                    for segment in result.bestTranscription.segments {
                        let word = segment.substring
                        let timestamp = segment.timestamp
                        self.transcriptionTimestamps[timestamp] = word
                    }
                    let sortedTimestamps = self.transcriptionTimestamps.sorted { $0.key < $1.key }
                    var formattedTimestamps: [String: String] = [:]
                    for (key, value) in sortedTimestamps {
                        let timestampString = String(format: "%02d:%02d:%02d",
                                                     Int(key) / 3600,
                                                     (Int(key) % 3600) / 60,
                                                     Int(key) % 60)
                        formattedTimestamps[timestampString] = value.replacingOccurrences(of: "\'", with: "")
                    }
                    print(formattedTimestamps)
                    let timestamps = formattedTimestamps.map { $0.key }
                    self.getResults(timestamps: timestamps,
                                    sceneRanges: self.flatSceneRanges,
                                    videoURL: self.videoURL!,
                                    numberOfClipsDisplayText: self.numberOfClipsDisplayLabel.text ?? "1")
                }
            }
        }
    }

//    func setupSteppers() {
//        numberOfClipsStepper.minimumValue = 1
//        numberOfClipsStepper.maximumValue = 10
//        numberOfClipsStepper.stepValue = 1
//        numberOfClipsStepper.value = 1
//        numberOfClipsStepperLabel.text = "\(Int(numberOfClipsStepper.value))"
//
//        numberOfClipsStepper.addTarget(self, action: #selector(numberOfClipsStepperChanged(_:)), for: .valueChanged)
//    }
//    
//    @objc func numberOfClipsStepperChanged(_ sender: UIStepper) {
//        numberOfClipsStepperLabel.text = "\(Int(sender.value))"
//    }
    
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
        videoSelectorView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add AVPlayerViewController view to the container
        if let playerVC = playerViewController {
            addChild(playerVC)
            playerVC.view.frame = videoSelectorView.bounds
            videoSelectorView.addSubview(playerVC.view)
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
    
    func generateClips() {
        guard let videoURL = videoList.first else {
            print("No video selected")
            return
        }
        
        self.videoURL = videoURL  // Save it as a property.
        
        let minutes = Int(minuitesLabel.text ?? "") ?? 1
        let seconds = Int(secondsLabel.text ?? "") ?? 15
        let minimumClipDuration = (minutes * 60) + seconds
        processVideoForScenes(videoPath: videoURL.path, minimumClipDuration: minimumClipDuration)
        
        let finalSceneRanges = scenes.map { $0.start...$0.end }
        flatSceneRanges = finalSceneRanges.map { range in
            [range.lowerBound, range.upperBound]
        }
        print("Scenes are : \(flatSceneRanges)")
        extractAudioAndTranscribe(from: videoURL)
    }

    
    func exportClip(from videoURL: URL, timestamps: [Double]) {
        let asset = AVAsset(url: videoURL)
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to find the documents directory")
            return
        }
        
        let projectDirectory = documentsDirectory.appendingPathComponent(projectNameTrim)
        let clipsDirectory = projectDirectory.appendingPathComponent("Clips")
        
        if !FileManager.default.fileExists(atPath: clipsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: clipsDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create 'Clips' folder: \(error.localizedDescription)")
                return
            }
        }
        
        let videoDuration = asset.duration.seconds
        
        for i in 0..<(timestamps.count - 1) {
            // Ensure the times are within the asset's duration.
            let startTimeValue = min(timestamps[i], videoDuration)
            let endTimeValue = min(timestamps[i + 1], videoDuration)
            
            let startTime = CMTime(seconds: startTimeValue, preferredTimescale: 600)
            let endTime = CMTime(seconds: endTimeValue, preferredTimescale: 600)
            
            // Verify that the time range is valid.
            if CMTimeCompare(startTime, endTime) >= 0 {
                print("Invalid time range for clip \(i): startTime (\(startTimeValue)) >= endTime (\(endTimeValue))")
                continue
            }
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                print("Failed to create export session for clip \(i)")
                continue
            }
            exportSession.outputFileType = .mp4
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let currentTimeString = dateFormatter.string(from: Date())
            let outputURL = clipsDirectory.appendingPathComponent("clip_\(i)_\(currentTimeString).mp4")
            
            exportSession.outputURL = outputURL
            exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("Clip \(i) exported successfully to: \(outputURL)")
                case .failed:
                    print("Failed to export clip \(i): \(String(describing: exportSession.error))")
                case .cancelled:
                    print("Export cancelled for clip \(i)")
                default:
                    break
                }
            }
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == trimSeguePreviewIdentifier {
            if let destinationVC = segue.destination as? TrimVideoPreviewViewController {

                

                guard let videoURL = videoList.first else {
                            print("No video available for clipping")
                            return
                        }
//                var timestamps = generateEvenClipTimestamps(for: videoURL, numberOfClips: Int(numberOfClipsDisplayLabel.text ?? " ") ?? 1)!
//                exportClip(from: videoURL, timestamps: timestamps)
                destinationVC.trimPreviewProjectName = projectNameTrim
                destinationVC.minuites = Int(minuitesLabel.text ?? "1") ?? 1
                destinationVC.seconds = Int(secondsLabel.text ?? "1") ?? 1
                destinationVC.numberOfClips = Int(numberOfClipsDisplayLabel.text ?? "1") ?? 1
                destinationVC.videoToClip = videoList.first
                
            }
        }
    }
    
    // New helper function to generate even clip timestamps.
    func generateEvenClipTimestamps(for videoURL: URL, numberOfClips: Int) -> [Double]? {
        let asset = AVAsset(url: videoURL)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        guard durationSeconds > 0, numberOfClips > 0 else { return nil }
        
        // Calculate the clip duration (each clip will be of equal duration).
        let clipDuration = durationSeconds / Double(numberOfClips)
        
        // Build timestamps array. We start at 0, then add clipDuration repeatedly.
        // Ensure we include the final timestamp.
        var timestamps: [Double] = []
        for i in 0...numberOfClips {
            timestamps.append(Double(i) * clipDuration)
        }
        return timestamps
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
    
    func processVideoForScenes(videoPath: String, minimumClipDuration: Int) {
        let scenesArray = NSMutableArray()
        let error = CV.detectSceneChanges(videoPath, scenes: scenesArray, minDuration: Double(minimumClipDuration))
        
        if let error = error, error.hasError {
            print("Error detecting scenes: \(error.message ?? "")")
            return
        }
        
        let scenes = scenesArray.compactMap { $0 as? SceneRange }
        self.scenes = scenes
        print("Detected scenes: \(scenes)") // Debug output to verify scenes are detected.
    }


    func getResults(
        timestamps: [String],
        sceneRanges: [[Double]],
        videoURL: URL,
        numberOfClipsDisplayText: String
    ) {
        Task {
            do {
                if let extractedTimestamps = try await getClipTimestamps(
                    timestamps: timestamps,
                    sceneRanges: sceneRanges,
                    videoURL: videoURL
                ) {
                    let sortedTimestamps = extractedTimestamps.sorted()
                    print("Extracted timestamps: \(sortedTimestamps)")
                    if sortedTimestamps.count >= 2 {
                        exportClip(from: videoURL, timestamps: sortedTimestamps)
                    } else {
                        print("Not enough timestamps extracted. Falling back.")
                        let numberOfClips = Int(numberOfClipsDisplayText) ?? 1
                        if let fallbackTimestamps = generateEvenClipTimestamps(for: videoURL, numberOfClips: numberOfClips) {
                            exportClip(from: videoURL, timestamps: fallbackTimestamps)
                        } else {
                            print("Failed to generate fallback clip timestamps.")
                        }
                    }
                } else {
                    // Fallback if extraction returned nil.
                    let numberOfClips = Int(numberOfClipsDisplayText) ?? 1
                    if let fallbackTimestamps = generateEvenClipTimestamps(for: videoURL, numberOfClips: numberOfClips) {
                        exportClip(from: videoURL, timestamps: fallbackTimestamps)
                    } else {
                        print("Failed to generate fallback clip timestamps.")
                    }
                }
            } catch {
                print("Error running LLM: \(error)")
                let numberOfClips = Int(numberOfClipsDisplayLabel.text ?? "1") ?? 1
                if let fallbackTimestamps = generateEvenClipTimestamps(for: videoURL, numberOfClips: numberOfClips) {
                    exportClip(from: videoURL, timestamps: fallbackTimestamps)
                } else {
                    print("Failed to generate fallback clip timestamps.")
                }
            }
        }
    }

}



extension TrimViewController {
    @objc func keyboard(notification: Notification) {

//        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
//        
//        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
//            self.view.frame.origin.y = -keyboardRect.height
//        } else {
//            self.view.frame.origin.y = 0
//        }
    }
}

extension TrimViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrimCell", for: indexPath) as? TrimCollectionViewCell else {
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
            self.playVideo(url: selectedVideo)
            self.generateThumbnails(for: selectedVideo)
        }
        
    }
}
