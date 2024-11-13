//
//  ColorViewController.swift
//  Zedit-UIKit
//
//  Created by VR on 13/11/24.
//

import UIKit
import AVFoundation
import AVKit
import CoreImage

class ColorViewController: UIViewController {
    
    @IBOutlet weak var videoPlayer: UIView!  
    @IBOutlet weak var framePreview: UIImageView!  

    
    @IBOutlet weak var videoSelectorButton: UIButton!
    
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var redLabel: UILabel!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var greenLabel: UILabel!
    @IBOutlet weak var blueSlider: UISlider!
    @IBOutlet weak var blueLabel: UILabel!
    @IBOutlet weak var alphaSlider: UISlider!
    @IBOutlet weak var alphaLabel: UILabel!
    
    @IBOutlet weak var applyChanges: UIButton!
//    @IBOutlet weak var resetButton: UIButton!
    var projectNameColorGrade = String()
       private var player: AVPlayer?
       private var playerViewController: AVPlayerViewController?
       private var imageGenerator: AVAssetImageGenerator?
       private var asset: AVAsset?
       private var currentFilter: CIFilter?
       private var context: CIContext?
       private var videoList: [URL] = []
       private var timeObserverToken: Any?
       
    
    private var currentPlayer: AVPlayer? {
            willSet {

                if let token = timeObserverToken {
                    currentPlayer?.removeTimeObserver(token)
                    timeObserverToken = nil
                }
                currentPlayer?.removeObserver(self, forKeyPath: "timeControlStatus")
            }
            didSet {
                addPeriodicTimeObserver()
                currentPlayer?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
            }
        }
    
    override func viewDidLoad() {
           super.viewDidLoad()
           context = CIContext(options: nil)
           setupSliders()
           addSliderTargets()
           setupUI()
           
           if let videos = fetchVideos() {
               videoList = videos
               setUpVideoSelector()
               if !videos.isEmpty {
                   loadVideo(url: videos[0])
               }
           }
       }
       
       private func setupUI() {
           navigationItem.title = projectNameColorGrade
           framePreview.contentMode = .scaleAspectFit
           framePreview.backgroundColor = .black
       }
       
    private func loadVideo(url: URL) {

            asset = AVAsset(url: url)
            imageGenerator = AVAssetImageGenerator(asset: asset!)
            imageGenerator?.appliesPreferredTrackTransform = true
            imageGenerator?.maximumSize = CGSize(width: 1280, height: 720)
            
            let newPlayer = AVPlayer(url: url)
            playerViewController = AVPlayerViewController()
            playerViewController?.player = newPlayer
            playerViewController?.showsPlaybackControls = true
            

            videoPlayer.subviews.forEach { $0.removeFromSuperview() }
            

            if let playerVC = playerViewController {
                addChild(playerVC)
                playerVC.view.frame = videoPlayer.bounds
                videoPlayer.addSubview(playerVC.view)
                playerVC.didMove(toParent: self)
            }
            

            self.currentPlayer = newPlayer
            self.currentPlayer?.play()
        }
        
       
    private func addPeriodicTimeObserver() {
            let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = currentPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
                self?.checkPlayerStatus()
            }
        }
        
       
       
       override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
           if keyPath == "timeControlStatus",
              let player = object as? AVPlayer {
               checkPlayerStatus()
           }
       }
       
       private func checkPlayerStatus() {
           if player?.timeControlStatus == .paused {
               if let currentTime = player?.currentTime() {
                   updateFramePreview(at: currentTime)
               }
           }
       }
       
       private func updateFramePreview(at time: CMTime) {
           guard let imageGenerator = imageGenerator else { return }
           
           Task {
               do {
                   let cgImage = try await imageGenerator.copyCGImage(at: time, actualTime: nil)
                   let ciImage = CIImage(cgImage: cgImage)
                   if let gradedImage = applyColorGrading(to: ciImage) {
                       DispatchQueue.main.async {
                           self.framePreview.image = UIImage(ciImage: gradedImage)
                       }
                   }
               } catch {
                   print("Error generating frame: \(error)")
               }
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
                   .filter { $0.pathExtension == "mp4" || $0.pathExtension == "mov" }
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
       
       private func addSliderTargets() {
           [redSlider, greenSlider, blueSlider, alphaSlider].forEach { slider in
               slider?.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
           }
       }
       
       @objc private func sliderValueChanged() {
           updateLabels()
           if player?.timeControlStatus == .paused,
              let currentTime = player?.currentTime() {
               updateFramePreview(at: currentTime)
           }
       }
       
       private func applyColorGrading(to image: CIImage) -> CIImage? {
           let colorMatrix = CIFilter(name: "CIColorMatrix")
           colorMatrix?.setValue(image, forKey: kCIInputImageKey)
           
           let r = Float(redSlider.value)
           let g = Float(greenSlider.value)
           let b = Float(blueSlider.value)
           let a = Float(alphaSlider.value)
           
           colorMatrix?.setValue(CIVector(x: CGFloat(r), y: 0, z: 0, w: 0), forKey: "inputRVector")
           colorMatrix?.setValue(CIVector(x: 0, y: CGFloat(g), z: 0, w: 0), forKey: "inputGVector")
           colorMatrix?.setValue(CIVector(x: 0, y: 0, z: CGFloat(b), w: 0), forKey: "inputBVector")
           colorMatrix?.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(a)), forKey: "inputAVector")
           
           return colorMatrix?.outputImage
       }
       
    @IBAction func applyChangesTapped(_ sender: Any) {
            guard let asset = asset else { return }
            
            let composition = AVMutableVideoComposition(asset: asset) { [weak self] request in
                guard let self = self else { return }
                if let gradedImage = self.applyColorGrading(to: request.sourceImage) {
                    request.finish(with: gradedImage, context: nil)
                } else {
                    request.finish(with: request.sourceImage, context: nil)
                }
            }
            
            composition.renderSize = asset.tracks(withMediaType: .video).first?.naturalSize ?? CGSize(width: 1280, height: 720)
            composition.frameDuration = CMTime(value: 1, timescale: 30)
            
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.videoComposition = composition
            
            currentPlayer?.replaceCurrentItem(with: playerItem)
            currentPlayer?.play()
        }
        
        
       
       private func setupSliders() {
           // Initial values
           [redSlider, greenSlider, blueSlider, alphaSlider].forEach { $0?.value = 1.0 }
           
           // Customize appearances
           let sliderConfig = [
               (redSlider, UIColor.red),
               (greenSlider, UIColor.green),
               (blueSlider, UIColor.blue),
               (alphaSlider, UIColor.brown)
           ]
           
           sliderConfig.forEach { slider, color in
               slider?.minimumTrackTintColor = color
               slider?.maximumTrackTintColor = .lightGray
               slider?.thumbTintColor = color
           }
           
           updateLabels()
       }
       
       private func updateLabels() {
           redLabel.text = String(format: "Red: %.2f", redSlider.value)
           greenLabel.text = String(format: "Green: %.2f", greenSlider.value)
           blueLabel.text = String(format: "Blue: %.2f", blueSlider.value)
           alphaLabel.text = String(format: "Alpha: %.2f", alphaSlider.value)
       }
       
       override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()
           playerViewController?.view.frame = videoPlayer.bounds
       }
       
       deinit {
           if let token = timeObserverToken {
               player?.removeTimeObserver(token)
           }
           player?.removeObserver(self, forKeyPath: "timeControlStatus")
       }
   }
