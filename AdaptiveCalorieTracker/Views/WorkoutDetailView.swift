import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @State private var isEditing = false
    
    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(workout.date, format: .dateTime.day().month().year())
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Category")
                    Spacer()
                    Text(workout.category)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                HStack {
                    Text("Muscles")
                    Spacer()
                    Text(workout.muscleGroups.joined(separator: ", "))
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Exercises") {
                if workout.exercises.isEmpty {
                    Text("No exercises logged").italic().foregroundColor(.secondary)
                } else {
                    ForEach(workout.exercises) { exercise in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.name).font(.headline)
                                if !exercise.note.isEmpty {
                                    Text(exercise.note).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            
                            // --- NEW: Display Logic ---
                            if exercise.isCardio {
                                VStack(alignment: .trailing) {
                                    if let dist = exercise.distance, dist > 0 {
                                        Text("\(dist, specifier: "%.2f") km")
                                    }
                                    if let time = exercise.duration, time > 0 {
                                        Text("\(Int(time)) min")
                                    }
                                }
                                .font(.callout).monospacedDigit().foregroundColor(.blue)
                            } else {
                                Text("\(exercise.reps ?? 0) x \(exercise.weight ?? 0.0, specifier: "%.1f")")
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            
            if !workout.note.isEmpty {
                Section("Notes") {
                    Text(workout.note)
                }
            }
        }
        .navigationTitle(workout.category)
        .toolbar {
            Button("Edit") {
                isEditing = true
            }
        }
        .sheet(isPresented: $isEditing) {
            AddWorkoutView(workoutToEdit: workout)
        }
    }
}
