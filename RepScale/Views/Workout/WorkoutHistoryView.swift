import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Bindable var profile: UserProfile
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    enum FilterType: String, CaseIterable {
        case category = "Category"
        case muscle = "Muscle"
        case exercise = "Exercise"
    }
    
    @State private var filterType: FilterType = .category
    
    // Defaults
    @State private var selectedCategory: String = "All"
    @State private var selectedMuscle: String = "All"
    @State private var selectedExercise: String = "All"
    
    var appBackgroundColor: Color {
        profile.isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(uiColor: .systemGroupedBackground)
    }
    
    var cardBackgroundColor: Color {
        profile.isDarkMode ? Color(red: 0.153, green: 0.153, blue: 0.165) : Color.white
    }
    
    var uniqueExercises: [String] {
        let names = workouts.flatMap { $0.exercises ?? [] }.map { $0.name }
        return Array(Set(names)).sorted()
    }
    
    var filteredWorkouts: [Workout] {
        switch filterType {
        case .category:
            if selectedCategory == "All" { return workouts }
            return workouts.filter { $0.category == selectedCategory }
        case .muscle:
            if selectedMuscle == "All" { return workouts }
            return workouts.filter { $0.muscleGroups.contains(selectedMuscle) }
        case .exercise:
            if selectedExercise == "All" { return workouts }
            // For granular exercise view, we still filter workouts that contain the exercise
            return workouts.filter { w in w.exercises?.contains(where: { $0.name == selectedExercise }) ?? false }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Filter Controls
            VStack(spacing: 12) {
                Picker("Filter", selection: $filterType) {
                    ForEach(FilterType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        switch filterType {
                        case .category:
                            FilterChip(title: "All", isSelected: selectedCategory == "All") { selectedCategory = "All" }
                            ForEach(WorkoutCategories.allCases, id: \.self) { cat in
                                FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat.rawValue) {
                                    selectedCategory = cat.rawValue
                                }
                            }
                        case .muscle:
                            FilterChip(title: "All", isSelected: selectedMuscle == "All") { selectedMuscle = "All" }
                            ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                                FilterChip(title: muscle.rawValue, isSelected: selectedMuscle == muscle.rawValue) {
                                    selectedMuscle = muscle.rawValue
                                }
                            }
                        case .exercise:
                            if uniqueExercises.isEmpty {
                                Text("No exercises logged yet").font(.caption).foregroundColor(.secondary)
                            } else {
                                ForEach(uniqueExercises, id: \.self) { ex in
                                    FilterChip(title: ex, isSelected: selectedExercise == ex) {
                                        selectedExercise = ex
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
            .background(cardBackgroundColor)
            
            // MARK: - Results List
            List {
                if filterType == .exercise && selectedExercise == "All" {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Select an exercise")
                            .font(.headline)
                        Text("Choose an exercise from the top bar to view its history.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
                    .listRowBackground(Color.clear)
                }
                else if filteredWorkouts.isEmpty {
                    Text("No matching workouts found.")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    if filterType == .exercise {
                        ForEach(filteredWorkouts) { workout in
                            Section(header:
                                HStack {
                                    Text(workout.date, format: .dateTime.weekday().day().month().year())
                                    Spacer()
                                    Text(workout.category).font(.caption).foregroundColor(.blue)
                                }
                            ) {
                                let relevantEntries = (workout.exercises ?? []).filter { $0.name == selectedExercise }
                                ForEach(relevantEntries) { entry in
                                    ExerciseHistoryRow(entry: entry, profile: profile)
                                }
                            }
                        }
                    } else {
                        // Standard Workout Summary View
                        ForEach(filteredWorkouts) { workout in
                            NavigationLink(destination: destinationFor(workout)) {
                                WorkoutHistoryRow(
                                    workout: workout,
                                    showExercises: filterType == .muscle
                                )
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .background(appBackgroundColor)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func destinationFor(_ workout: Workout) -> some View {
        if filterType == .muscle && selectedMuscle != "All" {
            WorkoutDetailView(workout: workout, profile: profile, filterMuscle: selectedMuscle)
        } else {
            WorkoutDetailView(workout: workout, profile: profile)
        }
    }
}

// MARK: - Helper Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseHistoryRow: View {
    let entry: ExerciseEntry
    let profile: UserProfile
    
    var body: some View {
        HStack {
            if entry.isCardio {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill").font(.caption).foregroundColor(.red)
                    if let dist = entry.distance, dist > 0 {
                        Text("\(dist.toUserDistance(system: profile.unitSystem), specifier: "%.2f") \(profile.unitSystem == UnitSystem.imperial.rawValue ? "mi" : "km")")
                    }
                    if let dur = entry.duration, dur > 0 {
                        Text("\(Int(dur)) min")
                    }
                }
            } else {
                HStack(spacing: 4) {
                    Text("\(entry.reps ?? 0)")
                        .bold()
                    Text("reps")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("x")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("\(entry.weight?.toUserWeight(system: profile.unitSystem) ?? 0, specifier: "%.1f")")
                        .bold()
                    Text(profile.unitSystem == UnitSystem.imperial.rawValue ? "lbs" : "kg")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            Spacer()
            if !entry.note.isEmpty {
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct WorkoutHistoryRow: View {
    let workout: Workout
    var showExercises: Bool = false
    
    var body: some View {
        let exercises = workout.exercises ?? []
        // Calculate unique names maintaining order of appearance
        let uniqueNames = exercises.map { $0.name }.reduce(into: [String]()) { (result, name) in
            if !result.contains(name) { result.append(name) }
        }
        let uniqueCount = uniqueNames.count
        let totalSets = exercises.count
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.date, format: .dateTime.day().month().year())
                    .font(.body).bold()
                Text(workout.category).font(.caption).foregroundColor(.blue)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(
                    "\(uniqueCount) \(uniqueCount == 1 ? "exercise" : "exercises"), " +
                    "\(totalSets) \(totalSets == 1 ? "set" : "sets")"
                )
                .font(.caption)
                .foregroundColor(.secondary)
                if !exercises.isEmpty {
                    if showExercises {
                        // UPDATED: Shows unique list of names (e.g. "Bench Press" only once)
                        Text(uniqueNames.joined(separator: ", "))
                            .font(.caption2).foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        // Shows Muscle Groups
                        Text(workout.muscleGroups.joined(separator: ", "))
                            .font(.caption2).foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text("No exercises")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
