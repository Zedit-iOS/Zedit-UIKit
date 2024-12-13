//
//  ExportViewController.swift
//  Zedit-UIKit
//
//  Created by VR on 05/11/24.
//

import UIKit

class ExportViewController: UIViewController {
    @IBOutlet weak var collectionView: ExportVideoCollectionView!
    
    var projectname: String?
    var videoList: [URL] = []
    
    override func viewDidLoad() {
        collectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let projectName = projectname else {
            print("Failure: Project name is nil")
            return
        }
        
        if let project = getProject(projectName: projectName) {
            videoList = project.subfolders.flatMap { $0.videoURLS }
        } else {
            print("Failed to load project.")
        }
        
        print("Project name is \(projectName)")
        collectionView.setupCollectionView(in: view)
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
    
    func fetchVideos() -> [URL]? {
        guard let projectName = projectname else {
            print("Failure: Project name is nil")
            return nil
        }
        
        if let project = getProject(projectName: projectName) {
            let videos = project.subfolders.flatMap { $0.videoURLS }
            print("Success: Found \(videos.count) videos")
            return videos
        } else {
            print("Failure: Could not get project")
            return nil
        }
    }
    
    @IBAction func ExportButton(_ sender: UIButton) {
        let selectedVideos = collectionView.getSelectedVideos()
        if selectedVideos.count > 0 {
            let activityController = UIActivityViewController(activityItems: selectedVideos, applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = sender
            present(activityController, animated: true)
        } else {
            let alert = UIAlertController(title: "No Videos Selected", message: "Select videos to export", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
