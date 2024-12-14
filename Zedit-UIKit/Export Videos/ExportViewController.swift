//
//  ExportViewController.swift
//  Zedit-UIKit
//
//  Created by VR on 05/11/24.
//

import UIKit

class ExportViewController: UIViewController {
    @IBOutlet weak var collectionView: ExportVideoCollectionView!
    
    var projectname = String()
    var videoList: [URL] = []
    
    override func viewDidLoad() {
        collectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        if let videos = fetchVideos() {
            videoList = videos
            collectionView.videoList = videos
            print("Videos successfully loaded")
            collectionView.reloadData()
        }
        print("Project name is \(projectname)")
        collectionView.setupCollectionView(in: view)
    }
    
    func getProjects(ProjectName: String) -> Project? {
        let fileManager = FileManager.default
        
        // Access the documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access documents directory")
            return nil
        }
        
        // Navigate to the project directory using the project name
        let projectDirectory = documentsDirectory.appendingPathComponent(ProjectName)
        guard fileManager.fileExists(atPath: projectDirectory.path) else {
            print("Project folder does not exist")
            return nil
        }
        
        do {
            // Initialize subfolders based on the expected folder structure
            let predefinedSubfolderNames = ["Original Videos", "Clips", "Colour Graded Videos"]
            var subfolders: [Subfolder] = []
            
            // Populate each subfolder with video files (if present)
            for subfolderName in predefinedSubfolderNames {
                let subfolderPath = projectDirectory.appendingPathComponent(subfolderName)
                var videoURLs: [URL] = []
                
                if fileManager.fileExists(atPath: subfolderPath.path) {
                    let videoFiles = try fileManager.contentsOfDirectory(at: subfolderPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    videoURLs = videoFiles.filter { ["mp4", "mov"].contains($0.pathExtension.lowercased()) }
                }
                
                // Append the subfolder with videos to the list
                subfolders.append(Subfolder(name: subfolderName, videos: videoURLs))
            }
            
            return Project(name: ProjectName, subfolders: subfolders)
        } catch {
            print("Error reading project folder: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchVideos() -> [URL]? {
        guard let project = getProjects(ProjectName: projectname) else {
            print("Failure: Could not retrieve project")
            return nil
        }
        
        // Filter videos from the "Clips" folder only
        if let clipsFolder = project.subfolders.first(where: { $0.name.lowercased() == "clips" }) {
            print("Found \(clipsFolder.videoURLS.count) videos in the 'Clips' folder")
            return clipsFolder.videoURLS
        }
        
        print("No 'Clips' folder found")
        return []
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
