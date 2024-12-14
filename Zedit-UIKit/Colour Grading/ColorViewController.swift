
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
    @IBOutlet weak var redLabel: UILabel!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var greenLabel: UILabel!
    @IBOutlet weak var blueSlider: UISlider!
    @IBOutlet weak var blueLabel: UILabel!
    @IBOutlet weak var contrastSlider: UISlider!
    @IBOutlet weak var contrastLabel: UILabel!
    
    var projectNameColorGrade = String()
    private var project: Project?
    private var videoList: [URL] = []
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var colorPlayerLayer: AVPlayerLayer?
    private var asset: AVAsset?
    private var context: CIContext?
    private var timeObserverToken: (observer: Any, player: AVPlayer)?
    private var isNavigatingBack = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPlayers()
        context = CIContext(options: nil)
        setupSliders()
        
        navigationController?.delegate = self
        
        self.navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(title: " Back", style: .plain, target: self, action: #selector(backButtonTapped))
        self.navigationItem.leftBarButtonItem = backButton
        
        if let projectData = getProjects(ProjectName: projectNameColorGrade) {
            project = projectData
            videoList = fetchVideos()
            setUpVideoSelector()
        } else {
            print("Failed to load project.")
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
        redSlider.minimumValue = 0
        redSlider.maximumValue = 200
        redSlider.value = 100
        
        greenSlider.minimumValue = 0
        greenSlider.maximumValue = 200
        greenSlider.value = 100
        
        blueSlider.minimumValue = 0
        blueSlider.maximumValue = 200
        blueSlider.value = 100
        
        contrastSlider.minimumValue = 0
        contrastSlider.maximumValue = 150
        contrastSlider.value = 50
        
        redSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        greenSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        blueSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        contrastSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        updateColorLabels()
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
    
    private func loadVideo(url: URL) {
        asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(url: url)
        
        let mainPlayer = AVPlayer(playerItem: playerItem)
        playerViewController?.player = mainPlayer
        
        setupColorAdjustedVideo(with: url)
        mainPlayer.play()
        
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
    
    @objc private func sliderValueChanged() {
        updateColorLabels()
        if let url = playerViewController?.player?.currentItem?.asset as? AVURLAsset {
            setupColorAdjustedVideo(with: url.url)
        }
    }
    
    private func updateColorLabels() {
        redLabel.text = String(format: "Red: %.1f%%", redSlider.value)
        greenLabel.text = String(format: "Green: %.1f%%", greenSlider.value)
        blueLabel.text = String(format: "Blue: %.1f%%", blueSlider.value)
        contrastLabel.text = String(format: "Contrast: %.1f%%", contrastSlider.value)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerViewController?.view.frame = videoPlayer.bounds
        colorPlayerLayer?.frame = colorVideoPlayer.bounds
    }
    
    deinit {
        if let token = timeObserverToken {
            token.player.removeTimeObserver(token.observer)
        }
    }
    
    func fetchVideos() -> [URL] {
        guard let project = getProjects(ProjectName: projectNameColorGrade) else {
            print("Failure: Could not get project")
            return []
        }
        
        var allVideos: [URL] = []
        
        // Fetch videos from "clips" folder
        if let clipsFolder = project.subfolders.first(where: { $0.name == "clips" }) {
            print("Found \(clipsFolder.videoURLS.count) videos in the clips folder")
            allVideos.append(contentsOf: clipsFolder.videoURLS)
        }
        
        // Fetch videos from "original videos" folder
        if let originalFolder = project.subfolders.first(where: { $0.name == "original videos" }) {
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
        
        // Handle video and audio tracks
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
        
        let outputFolder = url.deletingLastPathComponent().appendingPathComponent("Color Graded Videos")
        if !FileManager.default.fileExists(atPath: outputFolder.path) {
            try? FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        }
        
        let outputURL = outputFolder.appendingPathComponent(url.lastPathComponent)
        exportSession.outputFileType = .mp4
        exportSession.outputURL = outputURL
        exportSession.videoComposition = videoComposition
        
        exportSession.exportAsynchronously { [weak self] in
            guard let self = self else { return }
            if exportSession.status == .completed {
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Export Successful",
                        message: "File exported to: \(outputURL.lastPathComponent)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } else {
                print("Export failed with error: \(String(describing: exportSession.error))")
            }
        }
    }
}
