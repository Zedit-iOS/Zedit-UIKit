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
    
    override func viewWillAppear(_ animated: Bool) {
        addPulsatingAnimation(to: createProjectsButton)
        loadProjects()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        addPulsatingAnimation(to: createProjectsButton)
        
        RecentProjectsCollectionView.dataSource = self
        RecentProjectsCollectionView.delegate = self
        
        RecentProjectsCollectionView.collectionViewLayout = generateLayout()
        RecentProjectsCollectionView.setCollectionViewLayout(generateLayout(), animated: true)
        loadProjects()
        setupUI()
        if let onboardingVC = storyboard?.instantiateViewController(withIdentifier: "OnboardingVC") {
            onboardingVC.modalPresentationStyle = .fullScreen  // or .overFullScreen if you prefer transparency
            present(onboardingVC, animated: true)
        }
        setupNavigationTitle()
        view.backgroundColor = .black
        RecentProjectsCollectionView.backgroundColor = .black
    }
    
    
    
    
    private func setupNavigationTitle() {
        // Create the image view
        let logoImageView = UIImageView(image: UIImage(named: "zedit_logo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.widthAnchor.constraint(equalToConstant: 28).isActive = true  // Adjust size as needed
        logoImageView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        // Create the label
        let titleLabel = UILabel()
        titleLabel.text = "edit"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28) // Adjust size if needed
        titleLabel.textColor = .white  // Adapts to light/dark mode

        // Stack view to arrange them horizontally
        let titleStackView = UIStackView(arrangedSubviews: [logoImageView, titleLabel])
        titleStackView.axis = .horizontal
        titleStackView.spacing = 5 // Adjust spacing
        titleStackView.alignment = .center

        // Set the stack view as the title view
        navigationItem.titleView = titleStackView
    }
    
    private func setupBackgroundImage() {
            // Create an image view with the asset from the Assets catalog.
            // If you need to render SVG, you might consider using SVGKit or convert it to PDF/PNG.
            let backgroundImageView = UIImageView(frame: self.view.bounds)
            backgroundImageView.image = UIImage(named: "lol")
            backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            
            // Insert the image view behind all other views.
            self.view.insertSubview(backgroundImageView, at: 0)
            
            // Setup constraints so that the background fills the view.
            NSLayoutConstraint.activate([
                backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
                backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
    
    private func setupUI() {
        // Create Projects Button (Small Circle with +)
        createProjectsButton.layer.cornerRadius = 37.5  // half of 75
            createProjectsButton.clipsToBounds = true
            createProjectsButton.setTitle("+", for: .normal)
            createProjectsButton.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .bold)
            createProjectsButton.backgroundColor = UIColor.systemBlue
            createProjectsButton.setTitleColor(.white, for: .normal)
            
            // Button Auto Layout
            createProjectsButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(createProjectsButton)  // Make sure it's added to the view
            
            NSLayoutConstraint.activate([
                // Width and height
                createProjectsButton.widthAnchor.constraint(equalToConstant: 75),
                createProjectsButton.heightAnchor.constraint(equalToConstant: 75),
                
                // Center horizontally
                createProjectsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                
                // Position near bottom (adjust constant as needed)
                createProjectsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
        // Generate Clips Button (Scissor Icon + Text)
        styleButtonAsCard(generateClipsTrim, title: "Generate Clips", systemImageName: "scissors")
        styleButtonAsCard(colourGradeTrim, title: "Colour Grade", systemImageName: "wand.and.stars")
    }
    func styleButtonAsCard(_ button: UIButton, title: String, systemImageName: String) {
        // Set the image and title
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            let icon = UIImage(systemName: systemImageName, withConfiguration: imageConfig)
            
            // Set the image and title
            button.setImage(icon, for: .normal)
            button.setTitle(" \(title)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.tintColor = .white
            button.setTitleColor(.white, for: .normal)
            
            // Background color
            button.backgroundColor = UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1.0)
            
            // Bigger corner radius for a "boxier" feel
            button.layer.cornerRadius = 20
            
            // Shadow for depth
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
            button.layer.shadowOpacity = 0.3
            button.layer.shadowRadius = 6
            button.layer.masksToBounds = false
            
            // Increase content edge insets for more padding and height
            button.contentEdgeInsets = UIEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
            
            // Keep the icon on the left
            button.semanticContentAttribute = .forceLeftToRight
            
            // Ensure vertical alignment of image and text
            button.imageView?.contentMode = .center
            button.titleLabel?.textAlignment = .center
            
            // Fix for image and text alignment
            if #available(iOS 15.0, *) {
                var config = UIButton.Configuration.filled()
                config.imagePadding = 12
                config.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24)
                config.image = icon
                config.title = title
                config.imagePlacement = .leading
                config.baseBackgroundColor = UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1.0)
                config.baseForegroundColor = .white
                button.configuration = config
            } else {
                // For older iOS versions, adjust the image insets to align with text
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
                
                // Force layout update for proper alignment
                button.layoutIfNeeded()
            }
    }


    private func loadProjects() {
        // Retrieve projects and sort them by most recent creation date
        let allProjects = retrieveProjects().sorted(by: { $0.dateCreated > $1.dateCreated })
        
        // Take only the two most recently created projects
        projects = Array(allProjects.prefix(2))
        
        RecentProjectsCollectionView.reloadData()
    }
    
    func addPulsatingAnimation(to button: UIButton) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.8
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        button.layer.add(pulseAnimation, forKey: "pulsing")
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
            self.loadProjects()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "HomeMain", let destinationVC = segue.destination as? MainPageViewController, let indexPath = RecentProjectsCollectionView.indexPathsForSelectedItems?.first {
            updateTimesVisited(for: projects[indexPath.item].name)
            destinationVC.projectname = projects[indexPath.item].name
        }
    }
}

