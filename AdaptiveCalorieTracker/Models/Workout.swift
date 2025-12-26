import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    @Attribute(.unique) var date: Date // Normalized to start of day
    var category: String // e.g., "Push", "Pull", "Legs"
    var muscleGroups: [String] // e.g., ["Chest", "Triceps"]
    var note: String
    
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseEntry] = []
    
    init(date: Date, category: String, muscleGroups: [String], note: String = "") {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.category = category
        self.muscleGroups = muscleGroups
        self.note = note
    }
}

@Model
final class ExerciseEntry {
    var name: String
    var reps: Int
    var weight: Double
    var note: String
    
    init(name: String, reps: Int, weight: Double, note: String = "") {
        self.name = name
        self.reps = reps
        self.weight = weight
        self.note = note
    }
}