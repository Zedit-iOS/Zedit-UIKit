//
//  HomePageCollectionViewCell.swift
//  Zedit-UIKit
//
//  Created by Avinash on 17/02/25.
//

import UIKit
import AVFoundation

class HomePageCollectionViewCell: UICollectionViewCell {
    
    
    let thumbnailImageView = UIImageView()
    let moreOptionsButton = UIButton(type: .system)
    
    var moreOptionsHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
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
            
            // Add titleLabel to contentView
            contentView.addSubview(titleLabel)
            
            // Constraints for Thumbnail Image View
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
            
            // Constraints for Title Label.
            // Here we overlay the titleLabel near the bottom of the thumbnail.
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
                titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5)
            ])
        }
    
    /// Update the cell with a Project
    func update(with project: Project) {
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
                            // Set a default background if thumbnail generation fails.
                            self?.backgroundView = UIImageView(image: UIImage(named: "placeholder"))
                        }
                    }
                }
            } else {
                // Use a default placeholder background if no video exists.
                backgroundView = UIImageView(image: UIImage(named: "placeholder"))
            }
            
            // Update titleLabel with project details (name, date, clips, days ago)
            updateTitleLabel(with: project)
        }
    
    private func updateTitleLabel(with project: Project) {
            // Format the creation date.
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let dateCreatedString = dateFormatter.string(from: project.dateCreated)
            
            // Calculate how many days ago the project was created.
            let daysAgo = Calendar.current.dateComponents([.day], from: project.dateCreated, to: Date()).day ?? 0
            
            // Get clips count from the "Clips" subfolder.
            let clipsCount = project.subfolders.first(where: { $0.name == "Clips" })?.videoURLS.count ?? 0
            
            // Build the text with tab characters for separation:
            // Top line: project name (left) and date created (right)
            // Bottom line: clips count (left) and days ago (right)
            let text = "\(project.name)\t\(dateCreatedString)\n\(clipsCount) clips\t\(daysAgo) days ago"
            
            // Configure paragraph style with a tab stop for right alignment.
            let paragraphStyle = NSMutableParagraphStyle()
            // Calculate a tab location based on the cell’s content width (minus margins).
            let tabLocation = contentView.frame.width - 16  // Adjust this value as needed
            let tabStop = NSTextTab(textAlignment: .right, location: tabLocation, options: [:])
            paragraphStyle.tabStops = [tabStop]
            paragraphStyle.defaultTabInterval = tabLocation
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
    
    @objc private func didTapMoreOptions() {
        moreOptionsHandler?()
    }
}
