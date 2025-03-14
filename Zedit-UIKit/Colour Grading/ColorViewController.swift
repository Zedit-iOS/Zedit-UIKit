
//
//  ColorViewController.swift
//  Zedit-UIKit
//
//  Created by Vinay Rajan on 10/11/24.
//

import UIKit
import AVFoundation
import AVKit
import CoreImage

class ColorViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var videoPlayer: UIView!
    @IBOutlet weak var colorVideoPlayer: UIView!
    
    @IBOutlet weak var videoSelectorButton: UIButton!
    
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    @IBOutlet weak var contrastSlider: UISlider!
    
    
    @IBOutlet weak var redValueLabel: UILabel!
    
    @IBOutlet weak var greenValueLabel: UILabel!
    
    @IBOutlet weak var blueValueLabel: UILabel!
    
    
    @IBOutlet weak var contrastValueLabel: UILabel!
    
    @IBOutlet weak var sliderView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var playerView: UIView!
    
    @IBOutlet weak var videoScrubberView: UIScrollView!
    
    var projectNameColorGrade = String()
    private var project: Project?
    var videoList: [URL] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    private var colorPlayerLayer: AVPlayerLayer?
    private var asset: AVAsset?
    private var context: CIContext?
    private var timeObserverToken: (observer: Any, player: AVPlayer)?
    private var isNavigatingBack = false
    var playerObserver: Any?
    var playPauseButton = UIButton(type: .system)
    var timeLabel: UILabel!
    var playheadIndicator: UIView!
    var sliderIndicator: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPlayers()
        setupCollectionView()
        context = CIContext(options: nil)
        setupSliders()
        styleViews()
        configureSliderViewLayout()
        
        navigationController?.delegate = self
        
        self.navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(title: " Back", style: .plain, target: self, action: #selector(backButtonTapped))
        self.navigationItem.leftBarButtonItem = backButton
        
        if let videos = fetchVideos() {
            videoList = videos
            collectionView.reloadData()
            print("Videos successfully loaded: \(videoList.count) videos found.")
            
            // Select first video from collection view by default
            if !videoList.isEmpty {
                let indexPath = IndexPath(item: 0, section: 0)
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                loadVideo(url: videoList[0])
            }
        }
        navigationItem.title = projectNameColorGrade
        setupPlayheadIndicator()
        setupGestureRecognizer()
        generateThumbnails()
        setupTimelineControls()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
            if player != nil{
                player?.replaceCurrentItem(with: nil)
                player = nil
            }
    }
    
    private func findAllStackViews(in view: UIView) -> [UIStackView] {
        return view.subviews.compactMap { $0 as? UIStackView }
    }

    
    private func configureSliderViewLayout() {
        guard let sliderView = sliderView else { return }

        if let sliderStackView = sliderView as? UIStackView {
            sliderStackView.axis = .vertical
            sliderStackView.distribution = .fillEqually
            sliderStackView.alignment = .fill
            sliderStackView.spacing = 12
        } else {
            let immediateStackViews = findAllStackViews(in: sliderView)
            
            let existingVerticalStackView = immediateStackViews.first(where: { $0.axis == .vertical })
            
            if let verticalStackView = existingVerticalStackView {
                verticalStackView.axis = .vertical
                verticalStackView.distribution = .fillEqually
                verticalStackView.alignment = .fill
                verticalStackView.spacing = 12
                verticalStackView.translatesAutoresizingMaskIntoConstraints = false

                NSLayoutConstraint.activate([
                    verticalStackView.topAnchor.constraint(equalTo: sliderView.topAnchor, constant: 12),
                    verticalStackView.leadingAnchor.constraint(equalTo: sliderView.leadingAnchor, constant: 12),
                    verticalStackView.trailingAnchor.constraint(equalTo: sliderView.trailingAnchor, constant: -12),
                    verticalStackView.bottomAnchor.constraint(equalTo: sliderView.bottomAnchor, constant: -12)
                ])
            } else {
                let horizontalStackViews = immediateStackViews.filter { $0.axis == .horizontal }

                for horizontalStack in horizontalStackViews {
                    horizontalStack.removeFromSuperview()
                }

                let newVerticalStackView = UIStackView(arrangedSubviews: horizontalStackViews)
                newVerticalStackView.axis = .vertical
                newVerticalStackView.distribution = .fillEqually
                newVerticalStackView.alignment = .fill
                newVerticalStackView.spacing = 12
                newVerticalStackView.translatesAutoresizingMaskIntoConstraints = false

                sliderView.addSubview(newVerticalStackView)

                NSLayoutConstraint.activate([
                    newVerticalStackView.topAnchor.constraint(equalTo: sliderView.topAnchor, constant: 12),
                    newVerticalStackView.leadingAnchor.constraint(equalTo: sliderView.leadingAnchor, constant: 12),
                    newVerticalStackView.trailingAnchor.constraint(equalTo: sliderView.trailingAnchor, constant: -12),
                    newVerticalStackView.bottomAnchor.constraint(equalTo: sliderView.bottomAnchor, constant: -12)
                ])
            }
        }

        let horizontalStacks = findAllStackViews(in: sliderView).filter { $0.axis == .horizontal }

        for horizontalStack in horizontalStacks {
            horizontalStack.distribution = .fill
            horizontalStack.alignment = .center
            horizontalStack.spacing = 8

            for view in horizontalStack.arrangedSubviews {
                if let slider = view as? UISlider {
                    slider.setContentHuggingPriority(.defaultLow, for: .horizontal)
                    slider.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                } else if let label = view as? UILabel {
                    label.setContentHuggingPriority(.required, for: .horizontal)
                    label.setContentCompressionResistancePriority(.required, for: .horizontal)
                    label.setContentCompressionResistancePriority(.required, for: .vertical)
                    label.widthAnchor.constraint(equalToConstant: 60).isActive = true
                    label.textAlignment = .right
                }
            }
        }

        let minimumHeight = CGFloat(horizontalStacks.count) * 40 + CGFloat(horizontalStacks.count - 1) * 12 + 24
        sliderView.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight).isActive = true
    }

    
    private func styleViews() {
        // Set the main background color
        view.backgroundColor = .black
        
        // Style video player views and slider view
        let viewsToStyle = [videoPlayer, colorVideoPlayer, sliderView]
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
        if let playerView = playerView {
            playerView.layer.cornerRadius = cornerRadius
            playerView.layer.masksToBounds = true
            playerView.layer.borderWidth = borderWidth
            playerView.layer.borderColor = borderColor
            playerView.backgroundColor = backgroundColor

            // Set only top and bottom insets, no left and right
            playerView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        // Ensure proper padding for video players
        adjustVideoPlayerLayouts()
    }
    
    
    // Add this method to ensure proper padding inside the player views
    private func adjustVideoPlayerLayouts() {
        // Adjust the player view controllers to respect margins
        if let playerView = playerViewController?.view {
            playerView.frame = videoPlayer.bounds.insetBy(dx: 8, dy: 8)
        }
        
        if let colorLayer = colorPlayerLayer {
            colorLayer.frame = colorVideoPlayer.bounds.insetBy(dx: 8, dy: 8)
        }
    }
    
    @objc func backButtonTapped() {
        let alert = UIAlertController(
            title: "Confirm Navigation",
            message: "Are you sure you want to go back? Unsaved changes may be lost.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            self.isNavigatingBack = true
            self.navigationController?.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(alert, animated: true)
    }
    
    private func setupSliders() {
        setupSlider(slider: redSlider, min: 0, max: 200, value: 100, color: .red, label: redValueLabel)
        setupSlider(slider: greenSlider, min: 0, max: 200, value: 100, color: .green, label: greenValueLabel)
        setupSlider(slider: blueSlider, min: 0, max: 200, value: 100, color: .blue, label: blueValueLabel)
        setupSlider(slider: contrastSlider, min: 0, max: 150, value: 50, color: .yellow, label: contrastValueLabel)
        
        redSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        greenSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        blueSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        contrastSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
//        updateColorLabels()
    }

    // Helper function to configure each slider and label
    private func setupSlider(slider: UISlider, min: Float, max: Float, value: Float, color: UIColor, label: UILabel) {
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        
        // Set slider track and thumb colors
        slider.minimumTrackTintColor = color
        slider.maximumTrackTintColor = color.withAlphaComponent(0.3) // Dimmed for contrast
        slider.thumbTintColor = color
        
        // Set initial label value
        let percentage = Int((value / max) * 100)
        label.text = "\(percentage)%"
    }

    // Update label beside slider when value changes
    @objc private func sliderValueChanged(_ sender: UISlider) {
        let percentage = Int((sender.value / sender.maximumValue) * 100)
        
        switch sender {
        case redSlider:
            redValueLabel.text = "\(percentage)%"
            if let url = playerViewController?.player?.currentItem?.asset as? AVURLAsset {
                setupColorAdjustedVideo(with: url.url)
            }
        case greenSlider:
            greenValueLabel.text = "\(percentage)%"
            if let url = playerViewController?.player?.currentItem?.asset as? AVURLAsset {
                setupColorAdjustedVideo(with: url.url)
            }
        case blueSlider:
            blueValueLabel.text = "\(percentage)%"
            if let url = playerViewController?.player?.currentItem?.asset as? AVURLAsset {
                setupColorAdjustedVideo(with: url.url)
            }
        case contrastSlider:
            contrastValueLabel.text = "\(percentage)%"
            if let url = playerViewController?.player?.currentItem?.asset as? AVURLAsset {
                setupColorAdjustedVideo(with: url.url)
            }
        default:
            break
        }
    }

    private func setupVideoPlayers() {
        let originalPlayer = AVPlayerViewController()
        originalPlayer.view.frame = videoPlayer.bounds
        videoPlayer.addSubview(originalPlayer.view)
        addChild(originalPlayer)
        originalPlayer.didMove(toParent: self)
        playerViewController = originalPlayer
        
        colorPlayerLayer = AVPlayerLayer()
        colorPlayerLayer?.videoGravity = .resizeAspect
        colorPlayerLayer?.frame = colorVideoPlayer.bounds
        if let colorLayer = colorPlayerLayer {
            colorVideoPlayer.layer.addSublayer(colorLayer)
        }
    }
    
    func loadVideo(url: URL) {
        
        asset = AVAsset(url: url)
        playVideo(url: url)
        
        setupColorAdjustedVideo(with: url)
        
        addPeriodicTimeObserver()
    }
    
    private func setupColorAdjustedVideo(with url: URL) {
        guard let asset = AVAsset(url: url) as? AVURLAsset else { return }
        let composition = AVMutableComposition()
        
        // Insert video tracks
        let videoTracks = asset.tracks(withMediaType: .video)
        for assetTrack in videoTracks {
            guard let compositionTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: assetTrack.trackID) else { continue }
            do {
                try compositionTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: assetTrack,
                    at: .zero)
            } catch {
                print("Error inserting track: \(error)")
            }
        }
        
        let videoComposition = AVMutableVideoComposition(asset: asset) { [weak self] request in
            guard let self = self else { return }
            let image = request.sourceImage
            
            let colorKernel = """
                kernel vec4 colorAdjust(__sample s, float redScale, float greenScale, float blueScale, float contrast) {
                    vec4 color = s.rgba;
                    color.r *= redScale;
                    color.g *= greenScale;
                    color.b *= blueScale;
                    
                    float factor = (contrast * 2.0) - 1.0;
                    vec4 mean = vec4(0.5, 0.5, 0.5, 0.5);
                    color = mix(mean, color, 1.0 + factor);
                    
                    return clamp(color, vec4(0.0), vec4(1.0));
                }
            """
            
            guard let kernel = CIColorKernel(source: colorKernel) else { return }
            
            let redScale = self.redSlider.value / 100.0
            let greenScale = self.greenSlider.value / 100.0
            let blueScale = self.blueSlider.value / 100.0
            let contrastScale = self.contrastSlider.value / 100.0
            
            if let outputImage = kernel.apply(extent: image.extent, arguments: [image, redScale, greenScale, blueScale, contrastScale]) {
                request.finish(with: outputImage, context: self.context)
            } else {
                request.finish(with: image, context: self.context)
            }
        }
        
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = videoComposition
        
        let colorPlayer = AVPlayer(playerItem: playerItem)
        colorPlayerLayer?.player = colorPlayer
        colorPlayer.rate = playerViewController?.player?.rate ?? 1.0
    }
    
    private func addPeriodicTimeObserver() {
        if let token = timeObserverToken {
            token.player.removeTimeObserver(token.observer)
            timeObserverToken = nil
        }
        
        let interval = CMTime(seconds: 0.03, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        if let player = playerViewController?.player {
            let observer = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                self?.colorPlayerLayer?.player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
            }
            timeObserverToken = (observer: observer, player: player)
        }
    }
    
//    @objc private func sliderValueChanged() {
//        updateColorLabels()
//        if let url = playerViewController?.player?.currentItem?.asset as? AVURLAsset {
//            setupColorAdjustedVideo(with: url.url)
//        }
//    }
    
//    private func updateColorLabels() {
//        redLabel.text = String(format: "Red: %.1f%%", redSlider.value)
//        greenLabel.text = String(format: "Green: %.1f%%", greenSlider.value)
//        blueLabel.text = String(format: "Blue: %.1f%%", blueSlider.value)
//        contrastLabel.text = String(format: "Contrast: %.1f%%", contrastSlider.value)
//    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerViewController?.view.frame = videoPlayer.bounds
        colorPlayerLayer?.frame = colorVideoPlayer.bounds
        playheadIndicator.frame.origin.x = videoScrubberView.frame.midX - (playheadIndicator.frame.width / 2)
            
            // Align the playhead's bottom with the scrubber view's bottom
        playheadIndicator.frame.origin.y = videoScrubberView.frame.maxY - playheadIndicator.frame.height

            // Set the height of the playhead indicator to match the scrubber view
        playheadIndicator.frame.size.height = videoScrubberView.bounds.height
        adjustVideoPlayerLayouts()
    }
    
    deinit {
        if let token = timeObserverToken {
            token.player.removeTimeObserver(token.observer)
        }
    }
    
    func fetchVideos() -> [URL]? {
        guard let project = getProject(projectName: projectNameColorGrade) else {
            print("Failure: Could not get project")
            return []
        }
        
        var allVideos: [URL] = []
        
        // Fetch videos from "clips" folder
        if let clipsFolder = project.subfolders.first(where: { $0.name == "Clips" }) {
            print("Found \(clipsFolder.videoURLS.count) videos in the clips folder")
            allVideos.append(contentsOf: clipsFolder.videoURLS)
        }
        
        // Fetch videos from "original videos" folder
        if let originalFolder = project.subfolders.first(where: { $0.name == "Original Videos" }) {
            print("Found \(originalFolder.videoURLS.count) videos in the original videos folder")
            allVideos.append(contentsOf: originalFolder.videoURLS)
        }
        
        if allVideos.isEmpty {
            print("No videos found in 'clips' or 'original videos' folders.")
        } else {
            print("Total videos found: \(allVideos.count)")
        }
        
        return allVideos
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
    
    private func setUpVideoSelector() {
        guard !videoList.isEmpty else {
            videoSelectorButton.isEnabled = false
            return
        }
        
        videoSelectorButton.isEnabled = true
        let actionClosure = { (action: UIAction) in
            if let selectedVideo = self.videoList.first(where: { $0.lastPathComponent == action.title }) {
                self.loadVideo(url: selectedVideo)
            }
        }
        
        let menuChildren = videoList.map { video in
            UIAction(title: video.lastPathComponent, handler: actionClosure)
        }
        
        videoSelectorButton.menu = UIMenu(options: .displayInline, children: menuChildren)
        videoSelectorButton.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func applyChanges(_ sender: UIButton) {
        guard let asset = asset,
              let url = (asset as? AVURLAsset)?.url else { return }
        
        let composition = AVMutableComposition()
        
        // Handle video tracks
        let videoTracks = asset.tracks(withMediaType: .video)
        for assetTrack in videoTracks {
            guard let compositionTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: assetTrack.trackID) else { continue }
            
            do {
                try compositionTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: assetTrack,
                    at: .zero)
            } catch {
                print("Error inserting video track: \(error)")
                return
            }
        }
        
        // Handle audio tracks
        let audioTracks = asset.tracks(withMediaType: .audio)
        for audioTrack in audioTracks {
            guard let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: audioTrack.trackID) else { continue }
            
            do {
                try compositionAudioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: audioTrack,
                    at: .zero)
            } catch {
                print("Error inserting audio track: \(error)")
            }
        }
        
        // Define the color adjustment kernel
        let videoComposition = AVMutableVideoComposition(asset: asset) { [weak self] request in
            guard let self = self else { return }
            
            let image = request.sourceImage
            
            let colorKernel = """
                kernel vec4 colorAdjust(__sample s, float redScale, float greenScale, float blueScale, float contrast) {
                    vec4 color = s.rgba;
                    color.r *= redScale;
                    color.g *= greenScale;
                    color.b *= blueScale;
                    
                    float factor = (contrast * 2.0) - 1.0;
                    vec4 mean = vec4(0.5, 0.5, 0.5, 0.5);
                    color = mix(mean, color, 1.0 + factor);
                    
                    return clamp(color, vec4(0.0), vec4(1.0));
                }
            """
            
            guard let kernel = try? CIColorKernel(source: colorKernel) else { return }
            
            let redScale = self.redSlider.value / 100.0
            let greenScale = self.greenSlider.value / 100.0
            let blueScale = self.blueSlider.value / 100.0
            let contrastScale = self.contrastSlider.value / 100.0
            
            if let outputImage = kernel.apply(extent: image.extent,
                                              arguments: [image, redScale, greenScale, blueScale, contrastScale]) {
                request.finish(with: outputImage, context: self.context)
            } else {
                request.finish(with: image, context: self.context)
            }
        }
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality) else { return }
        
        // Determine the output URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let projectFolder = documentsDirectory.appendingPathComponent(projectNameColorGrade)
        let outputFolder = projectFolder.appendingPathComponent("Colour Graded Videos")
        
        // Create the output folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: outputFolder.path) {
            do {
                try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
            } catch {
                print("Error creating directory: \(error)")
                return
            }
        }
        
        // Create a color-graded file name
        let originalFileName = url.deletingPathExtension().lastPathComponent
        let colorGradedFileName = "\(originalFileName)_ColourGraded.mp4"
        let outputURL = outputFolder.appendingPathComponent(colorGradedFileName)
        
        // Check for existing file and remove if necessary
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch {
                print("Error removing existing file: \(error)")
                return
            }
        }
        
        // Configure the export session
        exportSession.outputFileType = .mp4
        exportSession.outputURL = outputURL
        exportSession.videoComposition = videoComposition
        
        // Display a progress alert
        let alert = UIAlertController(title: "Exporting", message: "Color grading in progress...", preferredStyle: .alert)
        present(alert, animated: true)
        
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    guard let self = self else { return }
                    switch exportSession.status {
                    case .completed:
                        let successAlert = UIAlertController(
                            title: "Export Successful",
                            message: "File exported to: \(outputURL.lastPathComponent)",
                            preferredStyle: .alert
                        )
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(successAlert, animated: true)
                    case .failed, .cancelled:
                        let errorAlert = UIAlertController(
                            title: "Export Failed",
                            message: exportSession.error?.localizedDescription ?? "Unknown error occurred.",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    default:
                        break
                    }
                }
            }
        }
    }

}
