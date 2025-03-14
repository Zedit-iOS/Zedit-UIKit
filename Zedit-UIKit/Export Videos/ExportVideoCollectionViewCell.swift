//
//  ExportVideoCollectionViewCell.swift
//  Zedit-UIKit
//
//  Created by VR on 05/11/24.
//

import UIKit
import AVFoundation

class ExportVideoCollectionViewCell: UICollectionViewCell {
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3) // Darken effect
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true // Hidden by default
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tickMarkView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white // Brighter tick
        imageView.backgroundColor = .systemGreen // Green background for visibility
        imageView.layer.cornerRadius = 30 // Make it circular
        imageView.layer.masksToBounds = true
        imageView.layer.shadowColor = UIColor.black.cgColor // Add shadow
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.shadowOffset = CGSize(width: 2, height: 2)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true // Hidden by default
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(tickMarkView)
        contentView.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: 150),
            contentView.heightAnchor.constraint(equalToConstant: 200),
            
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.8),
            thumbnailImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: thumbnailImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor),
            
            tickMarkView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            tickMarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tickMarkView.widthAnchor.constraint(equalToConstant: 60), // Increased size
            tickMarkView.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }
    
    override var isSelected: Bool {
        didSet {
            overlayView.isHidden = !isSelected
            tickMarkView.isHidden = !isSelected
        }
    }
    
    func configure(with videoURL: URL) {
        // Set video filename as title
        titleLabel.text = videoURL.lastPathComponent
        
        // Generate thumbnail
        generateThumbnail(for: videoURL) { [weak self] image in
            DispatchQueue.main.async {
                self?.thumbnailImageView.image = image
            }
        }
    }
    
    private func generateThumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0, preferredTimescale: 1)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                let thumbnail = UIImage(cgImage: cgImage)
                completion(thumbnail)
            } else {
                completion(nil)
            }
        }
    }
}
