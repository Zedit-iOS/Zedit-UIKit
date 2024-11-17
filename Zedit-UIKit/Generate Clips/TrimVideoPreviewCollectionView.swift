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
            let spacing: CGFloat = 10
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            
            // Calculate cell size (2 cells per row with equal spacing)
            let width = (view.bounds.width - spacing * 3) / 2
            layout.itemSize = CGSize(width: width, height: width * 1.2)
            layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
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
