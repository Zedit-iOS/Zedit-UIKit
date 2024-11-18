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
            let spacing: CGFloat = 10
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            
            // Calculate cell size (2 cells per row with spacing)
            let width = (view.bounds.width - spacing * 3) / 2
            layout.itemSize = CGSize(width: width, height: width * 1.2)
            layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
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
