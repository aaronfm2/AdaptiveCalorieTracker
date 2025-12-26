import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var category = "Push"
    @State private var selectedMuscles: Set<String> = []
    @State private var note = ""
    
    // Temporary storage for exercises being added
    @State private var tempExercises: [ExerciseEntry] = []
    @State private var showAddExerciseSheet = false
    
    // Predefined options
    let categories = ["Push", "Pull", "Legs", "Upper", "Lower", "Full Body", "Cardio", "Other"]
    let muscles = ["Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Abs", "Cardio"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Session Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    // Muscle Multi-Select
                    DisclosureGroup("Muscles Trained (\(selectedMuscles.count))") {
                        ForEach(muscles, id: \.self) { muscle in
                            HStack {
                                Text(muscle)
                                Spacer()
                                if selectedMuscles.contains(muscle) {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedMuscles.contains(muscle) {
                                    selectedMuscles.remove(muscle)
                                } else {
                                    selectedMuscles.insert(muscle)
                                }
                            }
                        }
                    }
                }
                
                Section("Exercises") {
                    ForEach(tempExercises, id: \.name) { ex in
                        VStack(alignment: .leading) {
                            Text(ex.name).font(.headline)
                            Text("\(ex.reps) reps @ \(ex.weight, specifier: "%.1f") kg")
                                .font(.subheadline).foregroundColor(.secondary)
                            if !ex.note.isEmpty {
                                Text(ex.note).font(.caption).italic()
                            }
                        }
                    }
                    .onDelete { indexSet in
                        tempExercises.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: { showAddExerciseSheet = true }) {
                        Label("Add Exercise", systemImage: "dumbbell.fill")
                    }
                }
                
                Section("Notes") {
                    TextField("Workout notes...", text: $note)
                }
            }
            .navigationTitle("Log Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWorkout() }
                        .disabled(selectedMuscles.isEmpty)
                }
            }
            .sheet(isPresented: $showAddExerciseSheet) {
                AddExerciseSheet(exercises: $tempExercises)
            }
        }
    }
    
    func saveWorkout() {
        let workout = Workout(date: date, category: category, muscleGroups: Array(selectedMuscles), note: note)
        workout.exercises = tempExercises
        
        // Remove existing workout for this day if strictly one per day is enforced, 
        // OR allow multiple. Logic here allows multiple but Calendar view handles them.
        // If you want to overwrite, you'd fetch existing here first.
        
        modelContext.insert(workout)
        dismiss()
    }
}

struct AddExerciseSheet: View {
    @Binding var exercises: [ExerciseEntry]
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Exercise Name (e.g. Bench Press)", text: $name)
                
                HStack {
                    Text("Reps")
                    Spacer()
                    TextField("0", text: $reps).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Weight (kg)")
                    Spacer()
                    TextField("0.0", text: $weight).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
                
                TextField("Note (Optional)", text: $note)
            }
            .navigationTitle("Add Details")
            .toolbar {
                Button("Add") {
                    if let r = Int(reps), let w = Double(weight), !name.isEmpty {
                        let newEx = ExerciseEntry(name: name, reps: r, weight: w, note: note)
                        exercises.append(newEx)
                        dismiss()
                    }
                }
                .disabled(name.isEmpty || reps.isEmpty || weight.isEmpty)
            }
        }
    }
}