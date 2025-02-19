
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
    
    fileprivate var playerObserver: Any?
    
    var projectname = String()
    var videoList: [URL] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    let trimSegueIdentifier = "Trim"
    
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
        
    }
    
    @objc func backButtonTapped(){
        self.navigationController?.popToRootViewController(animated: false)
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
    
    private func playVideo(url: URL) {
        
        if player != nil{
            player?.replaceCurrentItem(with: nil)
            player = nil
        }
        player = AVPlayer(url: url)
        let resetPlayer                  = {
            self.player?.seek(to: CMTime.zero)
                    self.player?.play()
                }
        playerObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: nil) { notification in resetPlayer() }
        
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true
        
        videoPreviewView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
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
