import Foundation
import SwiftData

@Model
class WeightEntry {
    var date: Date
    var weight: Double
    
    init(date: Date = Date(), weight: Double) {
        self.date = date
        self.weight = weight
    }
}
