////
////  MainPageCollectionView.swift
////  Zedit-UIKit
////
////  Created by Avinash on 06/03/25.
////
//
//import UIKit
//
//
//
//class MainPageCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
//    
//    public var videoListHome: [URL] = []
//    public var selectedVideoHome: URL
//    
//    func setupCollectionView(in view: UIView) {
//        self.delegate = self
//        self.dataSource = self
//        
//        // Register custom cell
//        self.register(MainPageCollectionViewCell.self, forCellWithReuseIdentifier: "HomeCell")
//        
//        // Setup collection view layout
//        if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
//        let leadingTrailingSpacing: CGFloat = 35 // Slightly more space on the sides
//        let interItemSpacing: CGFloat = 5 // Reduce center gap
//        let numberOfColumns: CGFloat = 1
//
//            // Calculate cell width with proper spacing
//            let totalSpacing = interItemSpacing * (numberOfColumns - 1) // Only between items
//            let availableWidth = view.bounds.width - (leadingTrailingSpacing * 2) - totalSpacing
//            let cellWidth = availableWidth / numberOfColumns
//
//            layout.minimumInteritemSpacing = interItemSpacing
//            layout.minimumLineSpacing = interItemSpacing
//            layout.itemSize = CGSize(width: cellWidth + 15, height: (cellWidth + 15) * 1.2) // Increase cell width
//
//            // Ensure more space on leading & trailing
//            layout.sectionInset = UIEdgeInsets(top: interItemSpacing, left: leadingTrailingSpacing, bottom: interItemSpacing, right: leadingTrailingSpacing)
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return videoListHome.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeCell", for: indexPath) as? MainPageCollectionViewCell else {
//            print("Failed to dequeue ExportVideoCollectionViewCell")
//            return UICollectionViewCell()
//        }
//        
//        let videoURL = videoListHome[indexPath.item]
//        cell.configure(with: videoURL)
//        print("Configuring cell with video: \(videoURL)")
//        
//        return cell
//    }
//    
//    // MARK: - UICollectionViewDelegate
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if let cell = collectionView.cellForItem(at: indexPath) as? MainPageCollectionViewCell {
//            cell.isSelected = true // Update UI to show tick mark
//            selectedVideoHome = videoListHome[indexPath.item]
//        }
//    }
//    
//
//    /*
//    // Only override draw() if you perform custom drawing.
//    // An empty implementation adversely affects performance during animation.
//    override func draw(_ rect: CGRect) {
//        // Drawing code
//    }
//    */
//
//}
