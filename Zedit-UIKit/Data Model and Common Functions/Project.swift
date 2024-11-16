//
//  Project.swift
//  Zedit-UIKit
//
//  Created by Avinash on 28/10/24.
//

import Foundation

struct Project {
    var name: String
    var videos: [URL] // List of video URLs in the folder
}

func retrieveProjects() -> [Project] {
    var projects: [Project] = []
    let fileManager = FileManager.default
    
    // Get the URL for the Documents directory
    guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("Unable to access the documents directory.")
        return []
    }
    
    do {
        // Get the contents of the Documents directory (all files and folders)
        let projectDirectories = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        // Iterate over each item and filter out folders only
        for directory in projectDirectories where directory.hasDirectoryPath {
            let projectName = directory.lastPathComponent // Folder name as the project name
            
            // Get the list of video URLs inside the project folder
            let videoFiles = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let videoURLs = videoFiles.filter { $0.pathExtension.lowercased() == "mp4" || $0.pathExtension.lowercased() == "mov" } // Adjust for any supported video extensions
            
            // Create a Project object and add it to the array
            let project = Project(name: projectName, videos: videoURLs)
            projects.append(project)
        }
        
    } catch {
        print("Error retrieving projects: \(error)")
    }
    
    return projects
}
