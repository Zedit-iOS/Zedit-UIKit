import UIKit
import AVKit
import MobileCoreServices
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation

class CreateProjectCollectionViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, PHPickerViewControllerDelegate, Encodable, UITextFieldDelegate {
    func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(projectNameTextField.text, forKey: .projectName)
            try container.encode(selectedVideoURL?.absoluteString, forKey: .selectedVideoURL)
        }

        private enum CodingKeys: String, CodingKey {
            case projectName
            case selectedVideoURL
        }
    
    fileprivate var playerObserver: Any?
    
    
    @IBOutlet weak var selectProjectButton: UIButton!
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var nameExistsLabel: UILabel!
    @IBOutlet weak var createProjectButton: UIButton!
    
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    var selectedVideoURL: URL? {
            didSet {
                updateVideoPreviewView()
                textFieldDidChange(projectNameTextField)
            }
        }
    
    var projects: [Project] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProjects()
        setupNotifications()
        setDefaultProjectName()
        projectNameTextField.delegate = self
        do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Error setting up AVAudioSession: \(error.localizedDescription)")
            }
        updateVideoPreviewView()
        view.backgroundColor = .black
        projectNameTextField.backgroundColor = .black
        projectNameTextField.textColor = .white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
            if player != nil{
                player?.pause()
                player?.replaceCurrentItem(with: nil)
                player = nil
            }
    }
    private func setDefaultProjectName() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        var projectNumber = 1
        var projectName: String
        let existingProjectNames = retrieveProjects().map { $0.name }
        
        repeat {
            projectName = "\(dateString)-project-\(projectNumber)"
            projectNumber += 1
        } while existingProjectNames.contains(projectName)
        
        projectNameTextField.text = projectName
        textFieldDidChange(projectNameTextField) // Trigger validation
    }
    
    private func loadProjects() {
        // Clear the existing data in the collection view to avoid duplicates
        if !projects.isEmpty {
            // Clear the collection view before reloading
            projects = []
        }
        
        // Retrieve new projects from storage or source
        projects = retrieveProjects()
    }
    
    private func setupUI() {
        setupVideoPreviewView()
        createProjectButton.isEnabled = false
        nameExistsLabel.isHidden = true
        projectNameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboard(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboard(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboard(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder() // Dismiss the keyboard
            return true
        }
    
    private func setupVideoPreviewView() {
        videoPlayerView.layer.borderWidth = 1
        videoPlayerView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    private func updateVideoPreviewView() {
        // Remove any existing subviews
        videoPlayerView.subviews.forEach { $0.removeFromSuperview() }
        
        if let videoURL = selectedVideoURL {
            // Video is selected → Setup AVPlayer
            playVideo(url: videoURL)
            selectProjectButton.isHidden = false
            videoPlayerView.isUserInteractionEnabled = true // Disable tap selection
        } else {
            // No video → Setup placeholder UI
            videoPlayerView.backgroundColor = UIColor.darkGray
                    
                    // Create the placeholder view and add it to the videoPlayerView
                    let placeholderView = UIView(frame: videoPlayerView.bounds)
            placeholderView.backgroundColor = UIColor.darkGray
                    placeholderView.layer.cornerRadius = 10
                    placeholderView.clipsToBounds = true
                    placeholderView.translatesAutoresizingMaskIntoConstraints = false
                    videoPlayerView.addSubview(placeholderView)
                    NSLayoutConstraint.activate([
                        placeholderView.topAnchor.constraint(equalTo: videoPlayerView.topAnchor),
                        placeholderView.bottomAnchor.constraint(equalTo: videoPlayerView.bottomAnchor),
                        placeholderView.leadingAnchor.constraint(equalTo: videoPlayerView.leadingAnchor),
                        placeholderView.trailingAnchor.constraint(equalTo: videoPlayerView.trailingAnchor)
                    ])
                    
                    // Create an image view for the placeholder icon
                    let imageView = UIImageView(image: UIImage(systemName: "video.fill"))
                    imageView.tintColor = .gray
                    imageView.contentMode = .scaleAspectFit
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    placeholderView.addSubview(imageView)
                    
                    // Instead of a multiplier constraint, set a fixed size (e.g., 100x100)
                    NSLayoutConstraint.activate([
                        imageView.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
                        imageView.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor),
                        imageView.widthAnchor.constraint(equalToConstant: 100),
                        imageView.heightAnchor.constraint(equalToConstant: 100)
                    ])
                    
                    // Create and add a label anchored to the bottom of the placeholder
                    let label = UILabel()
                    label.text = "Tap to select video"
                    label.textAlignment = .center
                    label.textColor = .white
                    label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                    label.translatesAutoresizingMaskIntoConstraints = false
                    placeholderView.addSubview(label)
                    
                    NSLayoutConstraint.activate([
                        label.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
                        label.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
                        label.bottomAnchor.constraint(equalTo: placeholderView.bottomAnchor),
                        label.heightAnchor.constraint(equalToConstant: 40)
                    ])
                    
                    // Add tap gesture to placeholder
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectVideoButtonTapped))
                    videoPlayerView.addGestureRecognizer(tapGesture)
                    
                    selectProjectButton.isHidden = true
        }
    }
//
//    @objc private func selectVideoButtonTapped() {
//            presentVideoSourceOptions()
//        }
    
    @IBAction func selectVideoButtonTapped(_ sender: UIButton) {
        presentVideoSourceOptions()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Create",
           let destination = segue.destination as? MainPageViewController{
            if saveProject(){
                updateTimesVisited(for: projectNameTextField.text!)
                destination.projectname = projectNameTextField.text!
                
            }
            
            // Set the destination's projectname with the selected project's name
                    
                    // Update the timesVisited count for the selected project
        }
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
    
    // MARK: - Unwind Segue Methods
    
    private func presentVideoSourceOptions() {
        let actionSheet = UIAlertController(title: "Select Video",
                                          message: "Choose a video source",
                                          preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            self.presentVideoPicker(sourceType: .camera)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentPHPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Documents", style: .default) { _ in
            self.presentDocumentPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.mediaTypes = [UTType.movie.identifier]
        present(picker, animated: true)
    }
    
    private func presentPHPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie])
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    private func saveProject() -> Bool {
        guard let projectName = projectNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !projectName.isEmpty else {
            return false
        }

        guard let videoURL = selectedVideoURL else {
            return false
        }

        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }

        let projectDirectory = documentsDirectory.appendingPathComponent(projectName)

        // Check if the project directory already exists
        if fileManager.fileExists(atPath: projectDirectory.path) {
            return false
        }

        do {
            // Create the directory for the new project
            try fileManager.createDirectory(at: projectDirectory, withIntermediateDirectories: true, attributes: nil)

            // Create subfolders
            let subfolderNames = ["Original Videos", "Clips", "Colour Graded Videos"]
            var subfolders: [Subfolder] = []

            for subfolderName in subfolderNames {
                let subfolderURL = projectDirectory.appendingPathComponent(subfolderName)
                try fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true, attributes: nil)

                if subfolderName == "Original Videos" {
                    // Copy the selected video into the "Original Videos" subfolder
                    let destinationURL = subfolderURL.appendingPathComponent(videoURL.lastPathComponent)
                    try fileManager.copyItem(at: videoURL, to: destinationURL)
                    // Add the video to the subfolder
                    subfolders.append(Subfolder(name: subfolderName, videos: [destinationURL]))
                } else {
                    // Initialize other subfolders with empty video arrays
                    subfolders.append(Subfolder(name: subfolderName, videos: []))
                }
            }

            // Initialize project with metadata
            let project = Project(
                name: projectName,
                dateCreated: Date(),
                timesVisited: 0,
                subfolders: subfolders
            )

            // Save project metadata to persistent storage
            var projects = retrieveProjects()
            projects.append(project)

            // Store updated project list in UserDefaults
            UserDefaults.standard.set(try? PropertyListEncoder().encode(projects), forKey: "projects")
            
            // Save additional metadata to a plist file
            let metadataURL = projectDirectory.appendingPathComponent("metadata.plist")
            let metadata: [String: Any] = ["timesVisited": project.timesVisited, "dateCreated": project.dateCreated]
            try PropertyListSerialization.data(fromPropertyList: metadata, format: .xml, options: 0).write(to: metadataURL)

            return true
        } catch {
            print("Error creating project: \(error.localizedDescription)")
            return false
        }
    }

}

// MARK: - Video Selection Delegates
extension CreateProjectCollectionViewController {
    func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            selectedVideoURL = videoURL
            playVideo(url: videoURL)
        }
        picker.dismiss(animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let videoURL = urls.first {
            selectedVideoURL = videoURL
            playVideo(url: videoURL)
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        
        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                guard let self = self, let tempURL = url else { return }
                
                let fileManager = FileManager.default
                guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                
                let destinationURL = documentsDirectory.appendingPathComponent(tempURL.lastPathComponent)
                
                do {
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.copyItem(at: tempURL, to: destinationURL)
                    
                    DispatchQueue.main.async {
                        self.selectedVideoURL = destinationURL
                        self.playVideo(url: destinationURL)
                    }
                } catch {
                    print("Error saving video: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func playVideo(url: URL) {
        // Clear any previous player and observer
        if let player = player {
            player.pause()
            player.replaceCurrentItem(with: nil)
            self.player = nil
        }
        
        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
            playerObserver = nil
        }
        
        // Clean up any existing player view controller
        if let existingPlayerVC = playerViewController {
            existingPlayerVC.willMove(toParent: nil)
            existingPlayerVC.view.removeFromSuperview()
            existingPlayerVC.removeFromParent()
            playerViewController = nil
        }
        
        // Remove all subviews from the videoPlayerView
        videoPlayerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create a new player with the given URL
        player = AVPlayer(url: url)
        
        // Create and configure the AVPlayerViewController
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true
        
        // Important: Set these properties to ensure controls are visible
        playerViewController?.videoGravity = .resizeAspect
        
        // Add the player view controller as a child
        if let playerVC = playerViewController {
            // Add as a child view controller
            addChild(playerVC)
            
            // Configure the player view to fill the container
            playerVC.view.frame = videoPlayerView.bounds
            playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Add to view hierarchy
            videoPlayerView.addSubview(playerVC.view)
            
            // Complete the parent-child relationship
            playerVC.didMove(toParent: self)
            
            // Enable user interaction
            playerVC.view.isUserInteractionEnabled = true
            videoPlayerView.isUserInteractionEnabled = true
        }
        
        // Set up loop playback
        playerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.player?.seek(to: CMTime.zero)
            self.player?.play()
        }
        
        // Start playback
        player?.play()
    }

}

// MARK: - TextField and Keyboard Handling
extension CreateProjectCollectionViewController {
    @objc func keyboard(notification: Notification) {
        if view.window?.isKind(of: UIWindow.self) == false {
            return
        }
        
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        if notification.name == UIResponder.keyboardWillShowNotification ||
            notification.name == UIResponder.keyboardWillChangeFrameNotification {
            view.frame.origin.y = 0
        } else {
            view.frame.origin.y = 0
            view.endEditing(true) // Dismiss keyboard when keyboard hides
        }
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        let isProjectNameValid = !(projectNameTextField.text?.isEmpty ?? true)
        
        // Retrieve projects and get their names as a list of strings
        let existingProjects = retrieveProjects()
        let existingProjectNames = existingProjects.map { $0.name }
        
        // Check if the current project name exists in the list
        let projectNameExists = existingProjectNames.contains { $0 == projectNameTextField.text }
        
        // Update UI based on project name validity and existence
        createProjectButton.isEnabled = isProjectNameValid && selectedVideoURL != nil && !projectNameExists
        nameExistsLabel.isHidden = !projectNameExists
        nameExistsLabel.text = projectNameExists ? "Name already exists!" : nil
    }
}

//extension CreateProjectCollectionViewController{
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
//        
//    }
//}
