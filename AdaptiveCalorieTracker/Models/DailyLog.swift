import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var date: Date
    var weight: Double?
    var caloriesConsumed: Int
    var caloriesBurned: Int
    
    var netCalories: Int {
        return caloriesConsumed - caloriesBurned
    }

    init(date: Date, weight: Double? = nil, caloriesConsumed: Int = 0, caloriesBurned: Int = 0) {
        self.date = Calendar.current.startOfDay(for: date)
        self.weight = weight
        self.caloriesConsumed = caloriesConsumed
        self.caloriesBurned = caloriesBurned
    }
}
