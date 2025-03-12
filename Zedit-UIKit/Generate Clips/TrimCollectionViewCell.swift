//
//  TrimCollectionViewCell.swift
//  Zedit-UIKit
//
//  Created by Avinash on 09/03/25.
//

import UIKit
import AVFoundation

class TrimCollectionViewCell: UICollectionViewCell {
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private let waveformStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let bar1 = UIView()
    private let bar2 = UIView()
    private let bar3 = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(waveformStackView)
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            waveformStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            waveformStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        setupWaveformBars()
    }
    private func setupWaveformBars() {
        let bars = [bar1, bar2, bar3]
        for bar in bars {
            bar.backgroundColor = .systemBlue
            bar.layer.cornerRadius = 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            waveformStackView.addArrangedSubview(bar)
            NSLayoutConstraint.activate([
                bar.widthAnchor.constraint(equalToConstant: 5),
                bar.heightAnchor.constraint(equalToConstant: 10)
            ])
        }
        waveformStackView.isHidden = true
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
        generateThumbnail(for: videoURL) { [weak self] image in
            DispatchQueue.main.async {
                self?.thumbnailImageView.image = image
            }
        }
    }
    
    private func generateThumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 0, preferredTimescale: 1)
            if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                completion(UIImage(cgImage: cgImage))
            } else {
                completion(nil)
            }
        }
    }
    
    private func showWaveformAnimation() {
        waveformStackView.isHidden = false
        animateBar(bar1, delay: 0.0)
        animateBar(bar2, delay: 0.2)
        animateBar(bar3, delay: 0.4)
    }
    
    private func animateBar(_ bar: UIView, delay: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "transform.scale.y")
        animation.fromValue = 1.0
        animation.toValue = 2.0
        animation.duration = 0.4
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.beginTime = CACurrentMediaTime() + delay
        bar.layer.add(animation, forKey: "waveform")
    }
    
    private func hideWaveformAnimation() {
        waveformStackView.isHidden = true
        for bar in [bar1, bar2, bar3] {
            bar.layer.removeAllAnimations()
        }
    }
    
}
