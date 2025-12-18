//
//  Item.swift
//  AdaptiveCalorieTracker
//
//  Created by Aaron Franklin-Martinez on 18/12/2025.
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
