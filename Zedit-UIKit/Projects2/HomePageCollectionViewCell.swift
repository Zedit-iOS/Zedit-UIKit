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
    
    let thumbnailImageView = UIImageView()
    let moreOptionsButton = UIButton(type: .system)
    
    var moreOptionsHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        // Cell appearance
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 3
        layer.cornerRadius = 8
        clipsToBounds = true
        backgroundColor = .clear  // Transparent so background image shows
        
        // Setup Thumbnail Image View
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)
        
        // Setup More Options Button
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
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 120) // Adjust if needed
        ])
        
        // Constraints for More Options Button
        NSLayoutConstraint.activate([
            moreOptionsButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            moreOptionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            moreOptionsButton.widthAnchor.constraint(equalToConstant: 24),
            moreOptionsButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    /// Update the cell with a Project
    func update(with project: Project) {
        // Set project title
        projectNameLabel.text = project.name

        // Generate thumbnail and set it as backgroundView
        if let originalVideosSubfolder = project.subfolders.first(where: {
            $0.name == "Original Videos"
        }),
           let firstVideoURL = originalVideosSubfolder.videoURLS.first{
            generateThumbnail(from: firstVideoURL) { [weak self] image in
                DispatchQueue.main.async {
                    if let thumbnail = image {
                        let imageView = UIImageView(image: thumbnail)
                        imageView.contentMode = .scaleAspectFill
                        imageView.clipsToBounds = true
                        self?.backgroundView = imageView
                    } else {
                        // Set a default background if thumbnail generation fails
                        self?.backgroundView = UIImageView(image: UIImage(named: "placeholder"))
                    }
                }
            }
        } else {
            // Set a default placeholder background if no video exists
            backgroundView = UIImageView(image: UIImage(named: "placeholder"))
        }
    }

    private func generateThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 1.0, preferredTimescale: 600)

        DispatchQueue.global().async {
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                completion(thumbnail)
            } catch {
                print("Error generating thumbnail: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    @objc private func didTapMoreOptions() {
        moreOptionsHandler?()
    }
}
