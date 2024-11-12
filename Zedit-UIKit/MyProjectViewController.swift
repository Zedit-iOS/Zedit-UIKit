//
//  MyProjectViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 09/11/24.
//

import UIKit

class MyProjectViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var projectsCollectionView: UICollectionView!
    var projects: [Project] = []
    var isEditingMode = false  // Track if edit mode is enabled

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.title = "My Projects"
        navigationItem.leftBarButtonItem = editButtonItem
        
        projectsCollectionView.dataSource = self
        projectsCollectionView.delegate = self
        
        if let flowLayout = projectsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = CGSize.zero
        }

        // Enable reordering support
        projectsCollectionView.allowsMultipleSelection = true
        projectsCollectionView.isEditing = true
        
        loadProjects()
    }

    private func loadProjects() {
        projects = retrieveProjects()
        projectsCollectionView.reloadData()
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
        return projects.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = projectsCollectionView.dequeueReusableCell(withReuseIdentifier: "ProjectCell", for: indexPath) as? MyProjectViewControllerCell else {
            return UICollectionViewCell()
        }

        cell.layer.borderColor = UIColor.yellow.cgColor
        cell.layer.borderWidth = 1
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 1.0, height: 4.0)
        cell.layer.masksToBounds = false

        let project = projects[indexPath.item]
        cell.update(with: project)

        // Add delete button if in edit mode
        cell.showDeleteButton(isEditingMode) { [weak self] in
            self?.deleteProject(at: indexPath)
        }

        return cell
    }

    // Handle project deletion
    private func deleteProject(at indexPath: IndexPath) {
        // Get the project to delete using the current index
        let projectToDelete = projects[indexPath.item]
        
        // Remove the project from the local storage directory
        deleteProjectFromDirectory(projectToDelete.name)
        
        // Update the data source and delete the project from the array
        projects.remove(at: indexPath.item)
        
        // Delete the item in the collection view
        projectsCollectionView.performBatchUpdates({
            projectsCollectionView.deleteItems(at: [indexPath])
        }, completion: nil)
    }


    // Enable reordering (requires setting `isEditing` to true)
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedProject = projects.remove(at: sourceIndexPath.item)
        projects.insert(movedProject, at: destinationIndexPath.item)
        
        // Update the data source and reload the collection view
        projectsCollectionView.reloadData() // Optionally, you can use more specific updates like `insertItems(at:)` and `deleteItems(at:)` for better performance.
    }
    
    private func deleteProjectFromDirectory(_ projectName: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let projectPath = documentsDirectory.appendingPathComponent(projectName)
        
        do {
            try fileManager.removeItem(at: projectPath)
            print("Deleted project: \(projectName)")
        } catch {
            print("Failed to delete project: \(error)")
        }
    }
    
    @IBAction func unwindToMyProjects(_ unwindSegue: UIStoryboardSegue) {
        print("Unwind segue triggered")  // Debug print
        guard unwindSegue.identifier == "Create" else {
            print("Wrong identifier or cancelled")  // Debug print
            return
        }
        
        print("Before loading projects")  // Debug print
        loadProjects()
        print("After loading projects: \(projects)")  // Debug print
    }
    
    let mainSegueIdentifier = "Main"
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == mainSegueIdentifier,
           let destination = segue.destination as? MainPageViewController,
           let indexPath = projectsCollectionView.indexPathsForSelectedItems?.first {
            
            // Set the destination's projectname with the selected project's name
            destination.projectname = projects[indexPath.item].name
        }
    }
}
