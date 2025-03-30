import UIKit
import AVFoundation

class ExportViewController: UIViewController {
    @IBOutlet weak var collectionView: ExportVideoCollectionView!
    @IBOutlet weak var videoFormatSegmentedControl: UISegmentedControl!
    @IBOutlet weak var videoResolutionSegmentedController: UISegmentedControl!
    
    var projectname = String()
    var videoList: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = true
        view.backgroundColor = .black
        collectionView.backgroundColor = .black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let videos = fetchVideos() {
            videoList = videos
            collectionView.videoList = videos
            print("Videos successfully loaded")
            collectionView.reloadData()
        }
        print("Project name is \(projectname)")
        collectionView.setupCollectionView(in: view)
    }
    
    func getProjects(ProjectName: String) -> Project? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access documents directory")
            return nil
        }
        
        let projectDirectory = documentsDirectory.appendingPathComponent(ProjectName)
        guard fileManager.fileExists(atPath: projectDirectory.path) else {
            print("Project folder does not exist")
            return nil
        }
        
        do {
            let predefinedSubfolderNames = ["Original Videos", "Clips", "Colour Graded Videos"]
            var subfolders: [Subfolder] = []
            for subfolderName in predefinedSubfolderNames {
                let subfolderPath = projectDirectory.appendingPathComponent(subfolderName)
                var videoURLs: [URL] = []
                if fileManager.fileExists(atPath: subfolderPath.path) {
                    let videoFiles = try fileManager.contentsOfDirectory(at: subfolderPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    videoURLs = videoFiles.filter { ["mp4", "mov"].contains($0.pathExtension.lowercased()) }
                }
                subfolders.append(Subfolder(name: subfolderName, videos: videoURLs))
            }
            return Project(name: ProjectName, subfolders: subfolders)
        } catch {
            print("Error reading project folder: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchVideos() -> [URL]? {
        guard let project = getProjects(ProjectName: projectname) else {
            print("Failure: Could not retrieve project")
            return nil
        }
        var allVideoURLs: [URL] = []
        for subfolder in project.subfolders {
            print("Found \(subfolder.videoURLS.count) videos in the '\(subfolder.name)' folder")
            allVideoURLs.append(contentsOf: subfolder.videoURLS)
        }
        if allVideoURLs.isEmpty {
            print("No videos found in any subfolder")
        }
        return allVideoURLs
    }
    
    @IBAction func ExportButton(_ sender: UIButton) {
        let selectedVideos = collectionView.getSelectedVideos()
        guard !selectedVideos.isEmpty else {
            showAlert(title: "No Videos Selected", message: "Select videos to export")
            return
        }
        
        let selectedFormat = getSelectedFormat()
        let selectedResolution = getSelectedResolution()
        
        var processedVideos: [URL] = []
        let dispatchGroup = DispatchGroup()
        
        for video in selectedVideos {
            dispatchGroup.enter()
            processVideo(videoURL: video, format: selectedFormat, resolution: selectedResolution) { outputURL, error in
                if let outputURL = outputURL {
                    processedVideos.append(outputURL)
                } else if let error = error {
                    print("Error processing video: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if processedVideos.isEmpty {
                self.showAlert(title: "Export Failed", message: "No videos were successfully converted.")
            } else {
                let activityController = UIActivityViewController(activityItems: processedVideos, applicationActivities: nil)
                activityController.popoverPresentationController?.sourceView = sender
                // When the activity controller finishes, delete the temporary files.
                activityController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
                    for url in processedVideos {
                        do {
                            try FileManager.default.removeItem(at: url)
                            print("🗑️ Deleted temporary file after export: \(url.path)")
                        } catch {
                            print("⚠️ Failed to delete temporary file after export: \(error.localizedDescription)")
                        }
                    }
                    self.performSegue(withIdentifier: "ExportCancel", sender: self)
                }
                self.present(activityController, animated: true)
            }
        }
        
    }
    
    func getSelectedFormat() -> AVFileType {
        switch videoFormatSegmentedControl.selectedSegmentIndex {
        case 0: return .mov  // MOV
        case 1: return .mp4  // MP4
        case 2: return .m4v  // M4V (Replaced MKV)
        default: return .mp4
        }
    }
    
    func getSelectedResolution() -> String {
        switch videoResolutionSegmentedController.selectedSegmentIndex {
        case 0: return AVAssetExportPreset640x480  // Low
        case 1: return AVAssetExportPreset1280x720 // HD
        case 2: return AVAssetExportPreset1920x1080 // Full HD
        case 3: return AVAssetExportPreset3840x2160 // 4K
        default: return AVAssetExportPreset1280x720
        }
    }
    
    func processVideo(videoURL: URL, format: AVFileType, resolution: String, completion: @escaping (URL?, Error?) -> Void) {
        // Check that the source file exists (without touching it)
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            completion(nil, NSError(domain: "FileError", code: 404, userInfo: [NSLocalizedDescriptionKey: "❌ File does not exist: \(videoURL.path)"]))
            return
        }
        
        let asset = AVURLAsset(url: videoURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: resolution) else {
            completion(nil, NSError(domain: "AVExportSessionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ AVAssetExportSession initialization failed."]))
            return
        }
        
        // Create a temporary file URL for the output
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputExtension = format == .mov ? "mov" : format == .mp4 ? "mp4" : "m4v"
        let outputURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(outputExtension)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = format
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("✅ Export successful: \(outputURL.path)")
                    completion(outputURL, nil)
                    
                case .failed:
                    let errorMessage = """
                    ❌ Export Failed for: \(videoURL.path)
                    Target Format: \(format.rawValue)
                    Target Resolution: \(resolution)
                    Error: \(exportSession.error?.localizedDescription ?? "Unknown error")
                    """
                    print(errorMessage)
                    // Delete the temporary file on error
                    do {
                        try FileManager.default.removeItem(at: outputURL)
                        print("🗑️ Deleted temporary file due to error: \(outputURL.path)")
                    } catch {
                        print("⚠️ Failed to delete temporary file on error: \(error.localizedDescription)")
                    }
                    completion(nil, NSError(domain: "AVExportError", code: -3, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                    
                case .cancelled:
                    print("❌ Export cancelled: \(videoURL.path)")
                    // Delete the temporary file if export is cancelled
                    do {
                        try FileManager.default.removeItem(at: outputURL)
                        print("🗑️ Deleted temporary file due to cancellation: \(outputURL.path)")
                    } catch {
                        print("⚠️ Failed to delete temporary file on cancellation: \(error.localizedDescription)")
                    }
                    completion(nil, NSError(domain: "AVExportError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Export was manually cancelled."]))
                    
                default:
                    let errorMessage = "❌ Unknown export failure: \(videoURL.path) \nStatus Code: \(exportSession.status.rawValue)"
                    print(errorMessage)
                    // Delete the temporary file on unknown failure
                    do {
                        try FileManager.default.removeItem(at: outputURL)
                        print("🗑️ Deleted temporary file due to unknown failure: \(outputURL.path)")
                    } catch {
                        print("⚠️ Failed to delete temporary file on unknown failure: \(error.localizedDescription)")
                    }
                    completion(nil, NSError(domain: "AVExportError", code: -5, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                }
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
