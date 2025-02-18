//
//  HomePageCollectionViewCell.swift
//  Zedit-UIKit
//
//  Created by Avinash on 17/02/25.
//

import UIKit
import AVFoundation

class HomePageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var projectDetailsLabel: UILabel!
    
    let thumbnailImageView = UIImageView()
    let moreOptionsButton = UIButton(type: .system)
    
    var moreOptionsHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 3
        layer.cornerRadius = 8
        clipsToBounds = true
        backgroundColor = .darkGray
        
        // Thumbnail Image View
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)

        // More Options Button
        moreOptionsButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        moreOptionsButton.tintColor = .white
        moreOptionsButton.addTarget(self, action: #selector(didTapMoreOptions), for: .touchUpInside)
        moreOptionsButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(moreOptionsButton)

        // Constraints for Thumbnail
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 120) // Adjust based on your design
        ])

        // Constraints for More Options Button
        NSLayoutConstraint.activate([
            moreOptionsButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            moreOptionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            moreOptionsButton.widthAnchor.constraint(equalToConstant: 24),
            moreOptionsButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func update(with project: Project) {
        projectNameLabel.text = project.name
        projectDetailsLabel.text = "Videos: \(getVideoCount(for: project))"
        loadThumbnail(for: project)
    }

    private func getVideoCount(for project: Project) -> Int {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return 0 }
        let projectPath = documentsDirectory.appendingPathComponent(project.name).appendingPathComponent("Original Videos")
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: projectPath.path)
            return files.filter { $0.hasSuffix(".mp4") }.count
        } catch {
            return 0
        }
    }
    
    private func loadThumbnail(for project: Project) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            setPlaceholderThumbnail()
            return
        }
        
        let projectPath = documentsDirectory.appendingPathComponent(project.name).appendingPathComponent("Original Videos")
        
        do {
            let videoFiles = try fileManager.contentsOfDirectory(atPath: projectPath.path)
            if let firstVideo = videoFiles.first(where: { $0.hasSuffix(".mp4") }) {
                let videoURL = projectPath.appendingPathComponent(firstVideo)
                generateThumbnail(from: videoURL)
            } else {
                setPlaceholderThumbnail()
            }
        } catch {
            setPlaceholderThumbnail()
        }
    }
    
    private func generateThumbnail(from url: URL) {
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let assetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 1, preferredTimescale: 600)
            do {
                let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    self.thumbnailImageView.image = thumbnail
                }
            } catch {
                DispatchQueue.main.async {
                    self.setPlaceholderThumbnail()
                }
            }
        }
    }

    private func setPlaceholderThumbnail() {
        DispatchQueue.main.async {
            self.thumbnailImageView.image = UIImage(systemName: "video") // Placeholder icon
            self.thumbnailImageView.tintColor = .lightGray
        }
    }
    
    @objc private func didTapMoreOptions() {
        moreOptionsHandler?()
    }
}
