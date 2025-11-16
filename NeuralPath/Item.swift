//
//  Item.swift
//  NeuralPath
//
//  Created by Goša Lukyanau on 16/11/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
