//
//  safe+extension.swift
//  Zedit-UIKit
//
//  Created by Avinash on 16/11/24.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
