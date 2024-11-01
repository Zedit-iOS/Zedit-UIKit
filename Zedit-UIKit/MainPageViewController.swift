//
//  MainPageViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 31/10/24.
//

import UIKit

class MainPageViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var videoSelector: UIButton!
    var projectname = String()
    var videoList:[URL]=[]
    
    @IBOutlet weak var videoPreviewView: UIView!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nameLabel.text = projectname
        if let videos = fetchVideos() {
            videoList = videos
            print("videos sucessfully loaded")
            setUpButton()
        }
    }
    
    func getProjects(ProjectName: String)->Project?{
        let filemanager = FileManager.default
        
        guard let documentsDirectory = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("unable to acess directory")
            return nil
        }
        
        let projectsDirectory = documentsDirectory.appendingPathComponent(ProjectName)
        
        guard filemanager.fileExists(atPath: projectsDirectory.path)else{
            print("folder does not exist")
            return nil
        }
        do{
            let videoFiles = try filemanager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil, options: []).filter{$0.pathExtension == "mp4"||$0.pathExtension == "mov"}
            return Project(name: ProjectName, videos: videoFiles)
        } catch{
            print("failed to fetch files")
            return nil
        }
        
    }
    
    
    func fetchVideos()->[URL]?{
        if let project = getProjects(ProjectName: projectname){
            let videos = project.videos
            print("sucess")
            return videos
        }
        else{
            print("failure")
            return nil
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func setUpButton (){
        let actionClosure = {(action: UIAction) in
            print(action.title)
        }
        var menuChilderen:[UIMenuElement]=[]
        for videoName in videoList {
            menuChilderen.append(UIAction(title: videoName.lastPathComponent, handler: actionClosure))
        }
        videoSelector.menu = UIMenu(options: .displayInline, children: menuChilderen)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
