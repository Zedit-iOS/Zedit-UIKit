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

class ColorViewController: UIViewController {
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
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var colorPlayerLayer: AVPlayerLayer?
    private var asset: AVAsset?
    private var context: CIContext?
    private var videoList: [URL] = []
    
    private var timeObserverToken: (observer: Any, player: AVPlayer)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPlayers()
        context = CIContext(options: nil)
        setupSliders()
        
        if let videos = fetchVideos() {
            videoList = videos
            setUpVideoSelector()
            if !videos.isEmpty {
                loadVideo(url: videos[0])
            }
        }
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
            
            guard let kernel =  CIColorKernel(source: colorKernel) else { return }
            
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
        redLabel.text = String(format: "Red: %.1f %", redSlider.value)
        greenLabel.text = String(format: "Green: %.1f %", greenSlider.value)
        blueLabel.text = String(format: "Blue: %.1f %", blueSlider.value)
        contrastLabel.text = String(format: "Contrast: %.1f %", contrastSlider.value)
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
    
    private func fetchVideos() -> [URL]? {
        guard let project = getProjects(ProjectName: projectNameColorGrade) else {
            print("Failed to get project")
            return nil
        }
        return project.videos
    }
    
    private func getProjects(ProjectName: String) -> Project? {
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
            let videoFiles = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil, options: [])
                .filter { ["mp4", "mov", "m4v", "avi", "mkv"].contains($0.pathExtension.lowercased()) }
            return Project(name: ProjectName, videos: videoFiles)
        } catch {
            print("Failed to fetch files: \(error)")
            return nil
        }
    }
    
    private func setUpVideoSelector() {
        videoSelectorButton.isEnabled = !videoList.isEmpty
        
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
    
    // Handle all video tracks
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
    
    // Handle audio tracks if present
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
    
    let outputURL = url.deletingLastPathComponent()
        .appendingPathComponent("color_" + url.lastPathComponent)
    
    try? FileManager.default.removeItem(at: outputURL)
    
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    exportSession.videoComposition = videoComposition
    
    let alert = UIAlertController(title: "Exporting Video",
                                  message: "Please wait...",
                                  preferredStyle: .alert)
    present(alert, animated: true)
    
    exportSession.exportAsynchronously {
        DispatchQueue.main.async {
            alert.dismiss(animated: true)
            
            switch exportSession.status {
            case .completed:
                let successAlert = UIAlertController(
                    title: "Success",
                    message: "Video exported successfully",
                    preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(successAlert, animated: true)
                
            case .failed, .cancelled:
                let errorAlert = UIAlertController(
                    title: "Error",
                    message: exportSession.error?.localizedDescription ?? "Export failed",
                    preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(errorAlert, animated: true)
                
            default:
                break
            }
        }
    }
}
}
