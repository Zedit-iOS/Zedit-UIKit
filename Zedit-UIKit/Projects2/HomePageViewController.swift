//
//  HomePageViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 17/02/25.
//

import UIKit

class HomePageViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var RecentProjectsCollectionView: UICollectionView!
    
    @IBOutlet weak var createProjectsButton: UIButton!
    
    @IBOutlet weak var colourGradeTrim: UIButton!
    
    @IBOutlet weak var generateClipsTrim: UIButton!
    
    
    
    var projects: [Project] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RecentProjectsCollectionView.dataSource = self
        RecentProjectsCollectionView.delegate = self
        
        RecentProjectsCollectionView.collectionViewLayout = generateLayout()
        RecentProjectsCollectionView.setCollectionViewLayout(generateLayout(), animated: true)
        loadProjects()
        setupUI()
    }
    
    private func setupUI() {
        // Create Projects Button (Small Circle with +)
        createProjectsButton.layer.cornerRadius = 35  // Half of width & height
        createProjectsButton.clipsToBounds = true
        createProjectsButton.setTitle("+", for: .normal)
        createProjectsButton.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        createProjectsButton.backgroundColor = UIColor.systemBlue
        createProjectsButton.setTitleColor(.white, for: .normal)
            
            // Increase size using Auto Layout
        createProjectsButton.translatesAutoresizingMaskIntoConstraints = false
        createProjectsButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        createProjectsButton.heightAnchor.constraint(equalToConstant: 70).isActive = true
        // Generate Clips Button (Scissor Icon + Text)
        let scissorIcon = UIImage(systemName: "scissors")
        generateClipsTrim.setImage(scissorIcon, for: .normal)
        generateClipsTrim.tintColor = .white
        generateClipsTrim.setTitle(" Generate Clips", for: .normal)
        generateClipsTrim.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        generateClipsTrim.setTitleColor(.white, for: .normal)
        generateClipsTrim.backgroundColor = UIColor.systemGreen
        generateClipsTrim.layer.cornerRadius = 10
        generateClipsTrim.clipsToBounds = true
        
        // Colour Grade Button (Magic Wand Icon + Text)
        let magicWandIcon = UIImage(systemName: "wand.and.stars")
        colourGradeTrim.setImage(magicWandIcon, for: .normal)
        colourGradeTrim.tintColor = .white
        colourGradeTrim.setTitle(" Colour Grade", for: .normal)
        colourGradeTrim.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        colourGradeTrim.setTitleColor(.white, for: .normal)
        colourGradeTrim.backgroundColor = UIColor.systemPurple
        colourGradeTrim.layer.cornerRadius = 10
        colourGradeTrim.clipsToBounds = true
    }
    
    private func loadProjects() {
        // Retrieve projects and sort them by most recent creation date
        let allProjects = retrieveProjects().sorted(by: { $0.dateCreated > $1.dateCreated })
        
        // Take only the two most recently created projects
        projects = Array(allProjects.prefix(2))
        
        RecentProjectsCollectionView.reloadData()
    }
    
    
    func generateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(150))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        group.interItemSpacing = .fixed(20)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return projects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = RecentProjectsCollectionView.dequeueReusableCell(withReuseIdentifier: "HomeCell", for: indexPath) as? HomePageCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let project = projects[indexPath.item]
        cell.update(with: project)
        cell.moreOptionsHandler = { [weak self] in
            self?.showProjectOptions(for: project, at: indexPath)
        }
        
        return cell
    }
    
    private func showProjectOptions(for project: Project, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Project Options", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "More Info", style: .default, handler: { _ in
            self.showProjectDetails(for: project)
        }))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteProject(at: indexPath)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showProjectDetails(for project: Project) {
        let infoMessage = """
        Name: \(project.name)
        Videos: \(getVideoCount(in: project))
        Created at: \(project.dateCreated)
        """
        let alert = UIAlertController(title: "Project Details", message: infoMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func getVideoCount(in project: Project) -> Int {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return 0 }
        let projectPath = documentsDirectory.appendingPathComponent(project.name).appendingPathComponent("clip")
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: projectPath.path)
            return files.filter { $0.hasSuffix(".mp4") }.count  // Assuming videos are in .mp4 format
        } catch {
            print("Error fetching video count: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func deleteProject(at indexPath: IndexPath) {
        let projectToDelete = projects[indexPath.item]
        deleteProjectFromDirectory(projectToDelete.name)
        removeProjectFromUserDefaults(projectToDelete.name)
        
        projects.remove(at: indexPath.item)
        RecentProjectsCollectionView.performBatchUpdates({
            RecentProjectsCollectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.RecentProjectsCollectionView.reloadData()
        })
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
}
