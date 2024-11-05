//
//  ExportViewController.swift
//  Zedit-UIKit
//
//  Created by VR on 05/11/24.
//

import UIKit

class ExportViewController: UIViewController{
    
    
    @IBOutlet weak var collectionView: ExportVideoCollectionView!

    
    var projectname: String?

        
    override func viewDidLoad() {
        collectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            if let videos = fetchVideos() {
                collectionView.videoList = videos
                print("Videos successfully loaded")
                collectionView.reloadData()
            }
            print("Project name is \(String(describing: projectname))")
            collectionView.setupCollectionView(in: view)
        }
        
        // MARK: - Helper Methods
        
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
                let videoFiles = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil, options: [])
                    .filter { $0.pathExtension == "mp4" || $0.pathExtension == "mov" }
                
                return Project(name: ProjectName, videos: videoFiles)
            } catch {
                print("Failed to fetch files")
                return nil
            }
        }
        
        func fetchVideos() -> [URL]? {
            if let project = getProjects(ProjectName: projectname!) {
                let videos = project.videos
                print("Success: Found \(videos.count) videos")
                return videos
            } else {
                print("Failure: Could not get project")
                return nil
            }
        }
    }
