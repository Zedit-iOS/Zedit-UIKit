import UIKit
import AVKit
import MobileCoreServices
import UniformTypeIdentifiers
import PhotosUI

class CreateProjectCollectionViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
    
    @IBOutlet weak var selectProjectButton: UIButton!
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var nameExistsLabel: UILabel!
    @IBOutlet weak var createProjectButton: UIButton!
    
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    var selectedVideoURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
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
    
    private func setupVideoPreviewView() {
        videoPlayerView.layer.borderWidth = 1
        videoPlayerView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    @IBAction func selectVideoButtonTapped(_ sender: UIButton) {
        presentVideoSourceOptions()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Create" {
            if !saveProject() {
                // If save fails, prevent the segue from occurring
                segue.destination.presentationController?.presentedViewController.dismiss(animated: true)
                
                let alert = UIAlertController(
                    title: "Save Failed",
                    message: "Unable to save project. Please ensure all fields are filled out correctly.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
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
        
        // Copy the selected video into the project directory
        let destinationURL = projectDirectory.appendingPathComponent(videoURL.lastPathComponent)
        try fileManager.copyItem(at: videoURL, to: destinationURL)
        
        // Save project metadata in UserDefaults
        let project = ["name": projectName, "videoURL": destinationURL.path]
        var projects = UserDefaults.standard.array(forKey: "projects") as? [[String: String]] ?? []
        projects.append(project)
        UserDefaults.standard.setValue(projects, forKey: "projects")
        
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
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true
        
        videoPlayerView.subviews.forEach { $0.removeFromSuperview() }
        
        if let playerVC = playerViewController {
            addChild(playerVC)
            playerVC.view.frame = videoPlayerView.bounds
            videoPlayerView.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)
        }
        
        player?.play()
    }
}

// MARK: - TextField and Keyboard Handling
extension CreateProjectCollectionViewController {
    @objc func keyboard(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if notification.name == UIResponder.keyboardWillShowNotification ||
            notification.name == UIResponder.keyboardWillChangeFrameNotification {
            view.frame.origin.y = -keyboardRect.height
        } else {
            view.frame.origin.y = 0
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let isProjectNameValid = !(projectNameTextField.text?.isEmpty ?? true)
        
        // Load the most recent projects from UserDefaults
        let existingProjects = UserDefaults.standard.array(forKey: "projects") as? [[String: String]] ?? []
        
        // Check if the current project name exists in the list
        let projectNameExists = existingProjects.contains { $0["name"] == projectNameTextField.text }
        
        createProjectButton.isEnabled = isProjectNameValid && selectedVideoURL != nil && !projectNameExists
        
        nameExistsLabel.isHidden = !projectNameExists
        nameExistsLabel.text = projectNameExists ? "Name already exists!" : nil
    }
}
