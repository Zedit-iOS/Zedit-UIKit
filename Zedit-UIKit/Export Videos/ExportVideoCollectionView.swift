//
//  ExportVideoCollectionView.swift
//  Zedit-UIKit
//
//  Created by VR on 05/11/24.
//

import UIKit


class ExportVideoCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    public var videoList: [URL] = []
    public var selectedVideo: [URL] = []
    
    func setupCollectionView(in view: UIView) {
        self.delegate = self
        self.dataSource = self
        
        // Register custom cell
        self.register(ExportVideoCollectionViewCell.self, forCellWithReuseIdentifier: "exportVideoCell")
        
        // Setup collection view layout
        if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            let leadingTrailingSpacing: CGFloat = 35 // Slightly more space on the sides
            let interItemSpacing: CGFloat = 5 // Reduce center gap
            let numberOfColumns: CGFloat = 2

            // Calculate cell width with proper spacing
            let totalSpacing = interItemSpacing * (numberOfColumns - 1) // Only between items
            let availableWidth = view.bounds.width - (leadingTrailingSpacing * 2) - totalSpacing
            let cellWidth = availableWidth / numberOfColumns

            layout.minimumInteritemSpacing = interItemSpacing
            layout.minimumLineSpacing = interItemSpacing
            layout.itemSize = CGSize(width: cellWidth + 15, height: (cellWidth + 15) * 1.2) // Increase cell width

            // Ensure more space on leading & trailing
            layout.sectionInset = UIEdgeInsets(top: interItemSpacing, left: leadingTrailingSpacing, bottom: interItemSpacing, right: leadingTrailingSpacing)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Number of videos: \(videoList.count)")
        return videoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exportVideoCell", for: indexPath) as? ExportVideoCollectionViewCell else {
            print("Failed to dequeue ExportVideoCollectionViewCell")
            return UICollectionViewCell()
        }
        
        let videoURL = videoList[indexPath.item]
        cell.configure(with: videoURL)
        print("Configuring cell with video: \(videoURL)")
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = videoList[indexPath.item]
        if !selectedVideo.contains(video) {
            selectedVideo.append(video)
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? ExportVideoCollectionViewCell {
            cell.isSelected = true // Update UI to show tick mark
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let video = videoList[indexPath.item]
        selectedVideo.removeAll { $0 == video }
        if let cell = collectionView.cellForItem(at: indexPath) as? ExportVideoCollectionViewCell {
            cell.isSelected = false // Update UI to hide tick mark
        }
    }
    
    func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        let selectedItems = collectionView.indexPathsForSelectedItems
        print("Selected videos: \(selectedItems?.map { $0.item } ?? [])")
    }
    
    func getSelectedVideos() -> [URL] {
        return selectedVideo
    }
}
