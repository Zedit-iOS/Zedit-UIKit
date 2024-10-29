//
//  CreateProjectViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 29/10/24.
//

import UIKit
import AVKit
import MobileCoreServices

class CreateProjectViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate {

    @IBOutlet weak var selectVideoButton: UIButton!
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var saveProjectButton: UIButton!
    
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    var selectedVideoURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPreviewView()
    }
    
    private func setupVideoPreviewView() {
        videoPreviewView.layer.borderWidth = 1
        videoPreviewView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    // Action for the select video button
    @IBAction func selectVideoButtonTapped(_ sender: UIButton) {
        presentVideoSourceOptions()
    }
    
    // Action for the create project button
    @IBAction func createProjectButtonTapped(_ sender: UIButton) {
        saveProject()
    }
    
    // Show action sheet for video source options
    private func presentVideoSourceOptions() {
        let actionSheet = UIAlertController(title: "Select Video", message: "Choose a video source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.presentVideoPicker(sourceType: .camera)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.presentVideoPicker(sourceType: .savedPhotosAlbum)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Documents", style: .default, handler: { _ in
            self.presentDocumentPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    // Helper function to present UIImagePickerController
    private func presentVideoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.mediaTypes = [kUTTypeMovie as String]
        present(picker, animated: true, completion: nil)
    }
    
    // Helper function to present UIDocumentPicker
    private func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
}

extension CreateProjectViewController {
    private func saveProject() {
        // Ensure the project has a name
        guard let projectName = projectNameTextField.text, !projectName.isEmpty else {
            showAlert(title: "Error", message: "Please enter a project name.")
            return
        }
        
        // Ensure a video has been selected
        guard let videoURL = selectedVideoURL else {
            showAlert(title: "Error", message: "Please select a video.")
            return
        }
        
        // Define the project directory path based on the project name
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            showAlert(title: "Error", message: "Unable to access the documents directory.")
            return
        }
        
        let projectDirectory = documentsDirectory.appendingPathComponent(projectName)
        
        // Check if a directory with the same project name already exists
        if fileManager.fileExists(atPath: projectDirectory.path) {
            showAlert(title: "Error", message: "A project with this name already exists. Please choose a different name.")
            return
        }
        
        // Create the project directory
        do {
            try fileManager.createDirectory(at: projectDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            showAlert(title: "Error", message: "Unable to create project directory.")
            return
        }
        
        // Copy the video to the project directory
        let videoFileName = videoURL.lastPathComponent
        let destinationURL = projectDirectory.appendingPathComponent(videoFileName)
        
        do {
            try fileManager.copyItem(at: videoURL, to: destinationURL)
        } catch {
            showAlert(title: "Error", message: "Unable to save the video in the project directory.")
            return
        }
        
        // Save project details in UserDefaults with the directory path
        let project = ["name": projectName, "videoURL": destinationURL.path]
        var projects = UserDefaults.standard.array(forKey: "projects") as? [[String: String]] ?? []
        projects.append(project)
        UserDefaults.standard.setValue(projects, forKey: "projects")
        
        showAlert(title: "Success", message: "Project saved successfully.")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
extension CreateProjectViewController {
    // Handle video selection from UIImagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            selectedVideoURL = videoURL
            playVideo(url: videoURL)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    // Handle video selection from UIDocumentPicker
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let videoURL = urls.first {
            selectedVideoURL = videoURL
            playVideo(url: videoURL)
        }
    }

    // Use AVPlayerViewController to play video with controls
    private func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true

        // Remove any previous subviews
        videoPreviewView.subviews.forEach { $0.removeFromSuperview() }

        // Embed the AVPlayerViewController's view inside videoPreviewView
        if let playerVC = playerViewController {
            addChild(playerVC)
            playerVC.view.frame = videoPreviewView.bounds
            videoPreviewView.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)
        }

        // Start playing the video
        player?.play()
    }
}
