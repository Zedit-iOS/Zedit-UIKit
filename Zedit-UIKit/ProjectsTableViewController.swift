//
//  ProjectsTableViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 28/10/24.
//

import UIKit

class ProjectsTableViewController: UITableViewController {
    
    var projects: [Project] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = editButtonItem
        loadProjects()
    }
    
    // MARK: - Load projects from Documents directory
    private func loadProjects() {
        projects = retrieveProjects() 
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "project", for: indexPath)
        
        let project = projects[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = project.name // Display the project name only
        cell.contentConfiguration = content
        cell.showsReorderControl = true
        cell.accessoryType = .disclosureIndicator

        return cell
    }
    
    // Reload data when the view appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProjects() // Reloads projects in case any were added or removed
    }
    
    // Handle selection of a project
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let project = projects[indexPath.row]
        print("Project selected: \(project.name)")
    }
    
    // Support for rearranging projects
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedProject = projects.remove(at: sourceIndexPath.row)
        projects.insert(movedProject, at: destinationIndexPath.row)
    }
    
    // Enable deletion of projects
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    // Handle deletion of a project from the table view and file system
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let project = projects[indexPath.row]
            deleteProjectFromDirectory(project.name) // Delete the folder from the file system
            projects.remove(at: indexPath.row) // Remove from the array
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: - Helper function to delete a project folder from Documents directory
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
}
