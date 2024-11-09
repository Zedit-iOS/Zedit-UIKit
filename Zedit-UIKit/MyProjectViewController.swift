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
        navigationItem.leftBarButtonItem = editButtonItem
        
        projectsCollectionView.dataSource = self
        projectsCollectionView.delegate = self
        
        if let flowLayout = projectsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = CGSize.zero
        }
        
        navigationItem.leftBarButtonItem = editButtonItem  // Enables the edit button
        loadProjects()
    }
    
    private func loadProjects() {
        projects = retrieveProjects()
        projectsCollectionView.reloadData()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        isEditingMode = editing
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
        projects.remove(at: indexPath.item)  // Update data source
        projectsCollectionView.deleteItems(at: [indexPath])  // Delete item in collection view
    }
}
