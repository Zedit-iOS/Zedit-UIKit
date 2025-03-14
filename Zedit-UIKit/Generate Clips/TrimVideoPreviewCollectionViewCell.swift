//
//  TrimVideoPreviewCollectionViewCell.swift
//  Zedit-UIKit
//
//  Created by Avinash on 16/11/24.
//

import UIKit
import AVFoundation

class TrimVideoPreviewCollectionViewCell: UICollectionViewCell {
    
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
    
    private let waveformView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 10
        view.isHidden = true // Hidden by default
        return view
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
        contentView.addSubview(waveformView)

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
            
            // Center waveform animation
            waveformView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            waveformView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            waveformView.widthAnchor.constraint(equalToConstant: 20),
            waveformView.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        // Add white outline
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                showWaveformAnimation()
            } else {
                hideWaveformAnimation()
            }
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
    
    // MARK: - Waveform Animation
    private func showWaveformAnimation() {
        waveformView.isHidden = false
        
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.5
        animation.duration = 0.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        
        waveformView.layer.add(animation, forKey: "waveformPulse")
    }
    
    private func hideWaveformAnimation() {
        waveformView.layer.removeAllAnimations()
        waveformView.isHidden = true
    }
}
