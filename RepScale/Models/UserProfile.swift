import Foundation
import SwiftData

@Model
final class UserProfile {
    var createdAt: Date = Date()
    
    // MARK: - Premium Status
    var isPremium: Bool = false // Feature Flag for Premium Features
    
    // MARK: - Core Profile
    var unitSystem: String = UnitSystem.metric.rawValue
    var gender: String = Gender.male.rawValue
    var isDarkMode: Bool = true
    
    // MARK: - Goals & Strategy
    var dailyCalorieGoal: Int = 2000
    var targetWeight: Double = 70.0
    var goalType: String = GoalType.cutting.rawValue
    var maintenanceCalories: Int = 2500
    var maintenanceTolerance: Double = 2.0
    var estimationMethod: Int = 0
    
    // MARK: - Feature Flags
    var isCalorieCountingEnabled: Bool = true
    var enableCaloriesBurned: Bool = true
    var enableHealthKitSync: Bool = true
    
    // MARK: - Dashboard Customization
    var dashboardLayoutJSON: String = ""
    var workoutTimeRange: String = "30 Days"
    var weightHistoryTimeRange: String = "30 Days"
    var strengthGraphTimeRange: String = "90 Days"
    var strengthGraphExercise: String = "Barbell Bench Press" // Default
    var strengthGraphReps: Int = 5
    
    // MARK: - Workout Preferences (NEW)
    var trackedMuscles: String = "Chest,Back,Legs,Shoulders,Abs,Cardio,Biceps,Triceps"
    // Persistent storage for user-defined muscles so they aren't lost when untracked
    var customMuscles: String = ""
    var weeklyWorkoutGoal: Int = 3 // Default to 3 workouts per week
    
    init() {
        self.createdAt = Date()
    }
    
    // MARK: - Helper Methods
    
    /// Adds a new custom muscle to the persistent list if it doesn't already exist.
    func addCustomMuscle(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Split current string into array, filter out empties
        var current = customMuscles.components(separatedBy: ",").filter { !$0.isEmpty }
        
        // Case-insensitive check to prevent duplicates like "Calves" and "calves"
        if !current.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            current.append(trimmed)
            customMuscles = current.joined(separator: ",")
        }
    }
}
