//
//  Project.swift
//  Zedit-UIKit
//
//  Created by Avinash on 28/10/24.
//

import Foundation

struct Subfolder {
    var name: String
    var videoURLS: [URL]
    
    init(name: String, videos: [URL] = []) {
        self.name = name
        self.videoURLS = videos
    }
}

struct Project {
    var name: String
    var dateCreated: Date
    var timesVisited: Int
    var subfolders: [Subfolder]  // Array of Subfolder structs

        init(name: String,
             dateCreated: Date = Date(),
             timesVisited: Int = 0,
             subfolders: [Subfolder] = [
                Subfolder(name: "Original Videos"),
                Subfolder(name: "Clips"),
                Subfolder(name: "Colour Graded Videos")
             ]) {
            self.name = name
            self.dateCreated = dateCreated
            self.timesVisited = timesVisited
            self.subfolders = subfolders
        }
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

            // Retrieve subfolder data
            var subfolders: [Subfolder] = []
            
            // Check for predefined subfolders
            let predefinedSubfolderNames = ["Original Videos", "Clips", "Colour Graded Videos"]
            for subfolderName in predefinedSubfolderNames {
                let subfolderURL = directory.appendingPathComponent(subfolderName)
                
                if fileManager.fileExists(atPath: subfolderURL.path) {
                    // Get the list of video files in the subfolder
                    let videoFiles = try fileManager.contentsOfDirectory(at: subfolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    let videoURLs = videoFiles.filter { $0.pathExtension.lowercased() == "mp4" || $0.pathExtension.lowercased() == "mov" } // Adjust for supported video extensions

                    // Add to subfolders
                    subfolders.append(Subfolder(name: subfolderName, videos: videoURLs))
                } else {
                    // Add an empty subfolder if it doesn't exist
                    subfolders.append(Subfolder(name: subfolderName))
                }
            }

            // Create a Project object and add it to the array
            let project = Project(name: projectName, subfolders: subfolders)
            projects.append(project)
        }
        
    } catch {
        print("Error retrieving projects: \(error)")
    }

    return projects
}
