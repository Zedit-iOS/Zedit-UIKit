//
//  MyProjectViewControllerCell.swift
//  Zedit-UIKit
//
//  Created by Avinash on 09/11/24.
//

import UIKit
import AVFoundation

class MyProjectViewControllerCell: UICollectionViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6) // Background for readability
        return label
    }()
    
    private lazy var deleteButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "trash"), for: .normal)
            button.tintColor = .red
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
            button.isHidden = true  // Initially hidden, only shows in edit mode
            return button
        }()
        
    var deleteAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(deleteButton)
        
        // Constraints for the title label at the bottom
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30) // Height for the label
        ])
        
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    titleLabel.heightAnchor.constraint(equalToConstant: 30)
                ])
                
                // Layout for delete button at top-right
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
            
            ])
                
            layer.cornerRadius = 8
            layer.masksToBounds = true
    }
    
    func update(with project: Project) {
        // Set project title
        titleLabel.text = project.name
        
        // Generate thumbnail and set it as backgroundView
        if let firstVideoURL = project.videos.first {
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
    
    func showDeleteButton(_ show: Bool, deleteAction: @escaping () -> Void) {
            deleteButton.isHidden = !show
            self.deleteAction = deleteAction
        }
        
    @objc private func deleteTapped() {
            deleteAction?()
        }
}
