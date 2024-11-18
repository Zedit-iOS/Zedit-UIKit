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
        imageView.tintColor = .systemGreen
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
            
            tickMarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            tickMarkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            tickMarkView.widthAnchor.constraint(equalToConstant: 20),
            tickMarkView.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }
    
    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? .systemBlue.withAlphaComponent(0.3) : .clear
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
