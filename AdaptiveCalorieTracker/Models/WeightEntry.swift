import Foundation
import SwiftData

@Model
final class WeightEntry {
    var date: Date = Date()
    var weight: Double = 0.0
    var note: String = ""
    
    init(date: Date = Date(), weight: Double, note: String) {
        self.date = date
        self.weight = weight
        self.note = note
    }
}
