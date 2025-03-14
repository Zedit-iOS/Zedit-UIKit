//
//  TrimVideoPreviewCollectionView.swift
//  Zedit-UIKit
//
//  Created by Avinash on 16/11/24.
//

import UIKit

class TrimVideoPreviewCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    public var videoList: [URL] = []
    
    func setupCollectionView(in view: UIView) {
        self.delegate = self
        self.dataSource = self
        
        // Register custom cell
        self.register(TrimVideoPreviewCollectionViewCell.self, forCellWithReuseIdentifier: "trimVideoCell")
        
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
        return videoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "trimVideoCell", for: indexPath) as? TrimVideoPreviewCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let videoURL = videoList[indexPath.item]
        cell.configure(with: videoURL)
        return cell
    }
}
