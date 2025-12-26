import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var date: Date
    var weight: Double?
    var caloriesConsumed: Int
    var caloriesBurned: Int
    var goalType: String?
    
    // --- NEW: Macro Tracking (Optional) ---
    var protein: Int? // grams
    var carbs: Int?   // grams
    var fat: Int?     // grams
    // --------------------------------------
    
    var netCalories: Int {
        return caloriesConsumed - caloriesBurned
    }

    init(date: Date, weight: Double? = nil, caloriesConsumed: Int = 0, caloriesBurned: Int = 0, goalType: String? = nil, protein: Int? = nil, carbs: Int? = nil, fat: Int? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.weight = weight
        self.caloriesConsumed = caloriesConsumed
        self.caloriesBurned = caloriesBurned
        self.goalType = goalType
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}
