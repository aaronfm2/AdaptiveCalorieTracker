import Foundation
import SwiftData

@Model
class WeightEntry {
    var date: Date = Date()
    var weight: Double = 0.0
    
    init(date: Date = Date(), weight: Double) {
        self.date = date
        self.weight = weight
    }
}
