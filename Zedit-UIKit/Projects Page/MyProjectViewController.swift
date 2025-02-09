//
//  MyProjectViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 09/11/24.
//

import UIKit

class MyProjectViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UISearchResultsUpdating {

    @IBOutlet weak var projectsCollectionView: UICollectionView!
    
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    var projects: [Project] = []  // Array holding all projects
    var filteredProjects: [Project] = []  // Array to hold filtered projects based on search
    
    var isEditingMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSearchController()
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.title = "My Projects"
        navigationItem.leftBarButtonItem = editButtonItem
        
        projectsCollectionView.dataSource = self
        projectsCollectionView.delegate = self
        
        projectsCollectionView.collectionViewLayout = generateLayout()
        projectsCollectionView.setCollectionViewLayout(generateLayout(), animated: true)

        // Enable reordering support
        projectsCollectionView.allowsMultipleSelection = true
        projectsCollectionView.isEditing = true
        //projectsCollectionView.backgroundColor = .black
        
        loadProjects()
        filteredProjects = projects// Initially, show all projects
        print(projects)
    }
    

    
    private func loadProjects() {
        // Clear the existing data in the collection view to avoid duplicates
        if !projects.isEmpty {
            // Clear the collection view before reloading
            filteredProjects.removeAll()
            projectsCollectionView.reloadData()
        }
        
        // Retrieve new projects from storage or source
        projects = retrieveProjects()
        filteredProjects = projects  // Initially, show all projects
        projectsCollectionView.reloadData()
    }
    
    func generateLayout() -> UICollectionViewLayout {
        // Size of each item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        
        // Create the layout item
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Create a group size
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(150))
        
        // Create a horizontal group
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        group.interItemSpacing = .fixed(20)  // Horizontal spacing between items
        
        // Create a section with vertical spacing between groups
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20  // Vertical spacing between groups
        
        // Add padding to the left and right ends
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)  // Adjust leading and trailing for padding
        
        // Create a collection view compositional layout
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }


    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        isEditingMode = editing
        projectsCollectionView.isEditing = editing  // Enable reordering when editing mode is active
        projectsCollectionView.reloadData()  // Reload to show/hide delete button
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 150)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredProjects.count  // Return the count of filtered projects
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = projectsCollectionView.dequeueReusableCell(withReuseIdentifier: "ProjectCell", for: indexPath) as? MyProjectViewControllerCell else {
            return UICollectionViewCell()
        }

        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 3
//        cell.layer.shadowColor = UIColor.black.cgColor
//        cell.layer.shadowOffset = CGSize(width: 1.0, height: 4.0)
//        cell.layer.masksToBounds = false

        let project = filteredProjects[indexPath.item]  // Get project from filtered array
        cell.update(with: project)

        cell.showDeleteButton(isEditingMode) { [weak self] in
            self?.deleteProject(at: indexPath)
        }

        return cell
    }

    private func deleteProject(at indexPath: IndexPath) {
        let projectToDelete = filteredProjects[indexPath.item]  // Get the project from filtered array
        
        // Remove the project from the local storage directory (delete the folder)
        deleteProjectFromDirectory(projectToDelete.name)
        
        // Remove the project from both projects and filteredProjects arrays before reloading the collection view
        if let index = projects.firstIndex(where: { $0.name == projectToDelete.name }) {
            projects.remove(at: index)  // Remove from the full project list
        }
        filteredProjects.remove(at: indexPath.item)  // Remove from the filtered list

        // Also remove the project from UserDefaults
        removeProjectFromUserDefaults(projectToDelete.name)
        
        // Delete the item in the collection view
        projectsCollectionView.performBatchUpdates({
            projectsCollectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            // After deletion, reload data
            self.projectsCollectionView.reloadData()
        })
        print(projects)
    }
    
    private func clearProjectCache(for projectName: String) {
        // If you're using NSCache or some other cache storage, clear it.
        // For example, if you use NSCache, you can do something like this:
        // Cache.removeObject(forKey: projectName)
        // If you store images or other files in cache, you might also want to clear them.
        
        let cache = URLCache.shared
        let url = URL(string: "cacheURL/\(projectName)") // Replace with your actual cache URL
        
        if let url = url {
            cache.removeCachedResponse(for: URLRequest(url: url))
            print("Cache cleared for project: \(projectName)")
        }
        
        // If you use a custom cache:
        // CustomCacheManager.shared.clearCache(for: projectName)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedProject = filteredProjects.remove(at: sourceIndexPath.item)
        filteredProjects.insert(movedProject, at: destinationIndexPath.item)
        
        // Update the data source and reload the collection view
        projectsCollectionView.reloadData()
    }
    
    private func deleteProjectFromDirectory(_ projectName: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let projectPath = documentsDirectory.appendingPathComponent(projectName)

        do {
            // Remove the project folder and its contents
            try fileManager.removeItem(at: projectPath)
            print("Deleted project folder: \(projectName)")
        } catch {
            print("Failed to delete project folder: \(error.localizedDescription)")
        }
    }
    
    private func removeProjectFromUserDefaults(_ projectName: String) {
        var projects = UserDefaults.standard.array(forKey: "projects") as? [[String: String]] ?? []
        
        // Remove project from the array
        projects.removeAll { $0["name"] == projectName }
        
        // Save the updated array back to UserDefaults
        UserDefaults.standard.setValue(projects, forKey: "projects")
    }



     
    private func setupSearchController(){
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.searchBar.placeholder = "Search Projects"
        self.navigationItem.searchController = searchController
        self.definesPresentationContext = false
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        if searchText!.isEmpty{
            filteredProjects = projects
        } else {
            filteredProjects = projects.filter {
                project in project.name.lowercased().contains((searchText!.lowercased()))
            }
        }
        projectsCollectionView.reloadData()
    }
    
    func updateTimesVisited(for projectName: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access the documents directory.")
            return
        }

        let projectDirectory = documentsDirectory.appendingPathComponent(projectName)
        let metadataURL = projectDirectory.appendingPathComponent("metadata.plist")

        // Check if the metadata file exists
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            print("Metadata file does not exist for project: \(projectName)")
            return
        }

        do {
            // Load existing metadata
            let metadataData = try Data(contentsOf: metadataURL)
            guard var metadata = try PropertyListSerialization.propertyList(from: metadataData, options: [], format: nil) as? [String: Any] else {
                print("Error reading metadata.")
                return
            }

            // Update timesVisited
            let currentTimesVisited = metadata["timesVisited"] as? Int ?? 0
            metadata["timesVisited"] = currentTimesVisited + 1 // Increment the count

            // Save updated metadata back to the plist file
            let updatedMetadataData = try PropertyListSerialization.data(fromPropertyList: metadata, format: .xml, options: 0)
            try updatedMetadataData.write(to: metadataURL)

            print("Successfully updated timesVisited for project: \(projectName)")
        } catch {
            print("Error updating timesVisited: \(error.localizedDescription)")
        }
    }

    private func saveProjectsToUserDefaults() {
        // Convert your projects array to an array of dictionaries or a format suitable for saving
        let projectsToSave = projects.map { ["name": $0.name, "timesVisited": $0.timesVisited] }
        UserDefaults.standard.setValue(projectsToSave, forKey: "projects")
    }




    // Unwind Segue for updating collection viewi
    @IBAction func unwindToMyProjects(_ unwindSegue: UIStoryboardSegue) {
        print("Unwind segue triggered")
        guard unwindSegue.identifier == "Create" else {
            print("Wrong identifier or cancelled")
            return
        }
        if let sourceVC = unwindSegue.source as? CreateProjectViewController {
                // Pause the player
                sourceVC.player?.pause()
            } else {
                print("Source view controller is not of type CreateProjectViewController")
            }
        //player?.pause()
        
        print("Before loading projects")
        loadProjects()
        filteredProjects = projects  // Reset filtered projects to all after unwinding
        projectsCollectionView.reloadData()
        print("After loading projects: \(projects)")
    }
    
    let mainSegueIdentifier = "Main"
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == mainSegueIdentifier,
           let destination = segue.destination as? MainPageViewController,
           let indexPath = projectsCollectionView.indexPathsForSelectedItems?.first {
            
            // Set the destination's projectname with the selected project's name
            let selectedProjectName = filteredProjects[indexPath.item].name
                    
                    // Update the timesVisited count for the selected project
            updateTimesVisited(for: selectedProjectName)
            destination.projectname = filteredProjects[indexPath.item].name
        }
    }
}

