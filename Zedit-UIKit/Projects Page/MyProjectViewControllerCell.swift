//
//  MyProjectViewControllerCell.swift
//  Zedit-UIKit
//
//  Created by Avinash on 09/11/24.
//

import UIKit
import AVFoundation

class MyProjectViewControllerCell: UICollectionViewCell {

    private var customSelected: Bool = false
    private var currentProject: Project? 
    
    override var isSelected: Bool {
        get { return customSelected }
        set { 
            customSelected = newValue
            updateSelectionAppearance(newValue)
        }
    }

    private func updateSelectionAppearance(_ selected: Bool) {
        selectionOverlay.isHidden = !selected
        checkmarkImageView.isHidden = !selected
        contentView.backgroundColor = selected ? .systemBlue.withAlphaComponent(0.3) : .clear
        deleteButton.isHidden = !selected
    }

    private let titleLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 2  // Two rows for the info
            label.textAlignment = .left
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = .white
            // Background for readability
            label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.tintColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.isHidden = true  // Initially hidden, only shows in edit mode
        button.backgroundColor = UIColor.white.withAlphaComponent(0.6) // Light background to ensure visibility
        button.layer.cornerRadius = 12  // Round the button edges for a cleaner look
        return button
    }()
    
    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        imageView.tintColor = .white
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
    
    override func layoutSubviews() {
            super.layoutSubviews()
            // Reapply title label formatting with the finalized label bounds.
            if let project = currentProject {
                updateTitleLabel(with: project)
            }
        }

    private func setupUI() {
        contentView.addSubview(titleLabel)
//        contentView.addSubview(deleteButton)
        contentView.addSubview(selectionOverlay)
        contentView.addSubview(checkmarkImageView)

        // Constraints for the title label at the bottom
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5)
        ])

        // Layout for delete button at top-right
//        NSLayoutConstraint.activate([
//            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
//            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
//            deleteButton.widthAnchor.constraint(equalToConstant: 24),
//            deleteButton.heightAnchor.constraint(equalToConstant: 24)
//        ])
//        
        NSLayoutConstraint.activate([
            selectionOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            checkmarkImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        layer.cornerRadius = 8
        layer.masksToBounds = true
    }

    func update(with project: Project) {
            // Store the project so we can update later on layoutSubviews
            currentProject = project
            
            // Generate thumbnail from the first video in the "Original Videos" subfolder.
            if let originalVideosSubfolder = project.subfolders.first(where: { $0.name == "Original Videos" }),
               let firstVideoURL = originalVideosSubfolder.videoURLS.first {
                generateThumbnail(from: firstVideoURL) { [weak self] image in
                    DispatchQueue.main.async {
                        if let thumbnail = image {
                            let imageView = UIImageView(image: thumbnail)
                            imageView.contentMode = .scaleAspectFill
                            imageView.clipsToBounds = true
                            self?.backgroundView = imageView
                        } else {
                            self?.backgroundView = UIImageView(image: UIImage(named: "placeholder"))
                        }
                    }
                }
            } else {
                backgroundView = UIImageView(image: UIImage(named: "placeholder"))
            }
            
            // Update titleLabel initially.
            updateTitleLabel(with: project)
        }
        
        private func updateTitleLabel(with project: Project) {
            // Format the creation date.
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let dateCreatedString = dateFormatter.string(from: project.dateCreated)
            
            let daysAgo = Calendar.current.dateComponents([.day], from: project.dateCreated, to: Date()).day ?? 0
            let clipsCount = project.subfolders.first(where: { $0.name == "Clips" })?.videoURLS.count ?? 0
            
            let text = " \(project.name)\t\(dateCreatedString) \n \(clipsCount) clips\t\(daysAgo) days ago "
            
            // Use the titleLabel's finalized bounds for tab stop location.
            let labelWidth = titleLabel.bounds.width > 0 ? titleLabel.bounds.width : (contentView.frame.width - 16)
            
            let paragraphStyle = NSMutableParagraphStyle()
            let tabStop = NSTextTab(textAlignment: .right, location: labelWidth, options: [:])
            paragraphStyle.tabStops = [tabStop]
            paragraphStyle.defaultTabInterval = labelWidth
            paragraphStyle.lineBreakMode = .byTruncatingTail
            
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 12, weight: .bold)
            ]
            
            titleLabel.attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    
    
    private func generateThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            // Get video duration in seconds.
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            var firstThumbnail: UIImage?
            
            DispatchQueue.global().async {
                // Iterate through the video at 1-second intervals.
                // If the duration is 0 or invalid, try once at 0 seconds.
                let step = durationSeconds > 0 ? 1.0 : durationSeconds
                let endTime = durationSeconds > 0 ? durationSeconds : 0.0
                
                for currentSecond in stride(from: 0.0, through: endTime, by: step) {
                    let time = CMTime(seconds: currentSecond, preferredTimescale: 600)
                    do {
                        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                        let thumbnail = UIImage(cgImage: cgImage)
                        
                        if firstThumbnail == nil {
                            firstThumbnail = thumbnail
                        }
                        
                        // Check if the thumbnail is not entirely black.
                        if !self.isImageEntirelyBlack(thumbnail) {
                            DispatchQueue.main.async {
                                completion(thumbnail)
                            }
                            return
                        }
                    } catch {
                        print("Error generating thumbnail at \(currentSecond) seconds: \(error.localizedDescription)")
                    }
                }
                // If all frames are entirely black (or errors occurred), return the first thumbnail (even if black)
                DispatchQueue.main.async {
                    completion(firstThumbnail)
                }
            }
        }
        
        /// Helper method to determine if an image is entirely black using an average color calculation.
        private func isImageEntirelyBlack(_ image: UIImage) -> Bool {
            guard let ciImage = CIImage(image: image) else { return false }
            let extent = ciImage.extent
            let filter = CIFilter(name: "CIAreaAverage", parameters: [
                kCIInputImageKey: ciImage,
                kCIInputExtentKey: CIVector(cgRect: extent)
            ])
            guard let outputImage = filter?.outputImage else { return false }
            
            var bitmap = [UInt8](repeating: 0, count: 4)
            let context = CIContext(options: nil)
            context.render(outputImage,
                           toBitmap: &bitmap,
                           rowBytes: 4,
                           bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                           format: .RGBA8,
                           colorSpace: CGColorSpaceCreateDeviceRGB())
            let red = CGFloat(bitmap[0]) / 255.0
            let green = CGFloat(bitmap[1]) / 255.0
            let blue = CGFloat(bitmap[2]) / 255.0
            
            // Calculate the average brightness.
            let brightness = (red + green + blue) / 3.0
            // Consider the image "entirely black" if the brightness is very low.
            return brightness < 0.05
        }

    func showDeleteButton(_ show: Bool, deleteAction: @escaping () -> Void) {
        deleteButton.isHidden = !show
        self.deleteAction = deleteAction
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
    }

    @objc private func deleteTapped() {
        deleteAction?()
    }
}
