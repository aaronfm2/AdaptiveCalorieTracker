import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    @State private var showingAddWorkout = false
    @State private var showingSettings = false
    
    // Muscles the user cares about tracking (saved in UserDefaults)
    @AppStorage("trackedMuscles") private var trackedMusclesString: String = "Chest,Back,Legs"
    
    var trackedMuscles: [String] {
        trackedMusclesString.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // 1. Calendar View
                    WorkoutCalendarView(workouts: workouts)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                        .padding(.horizontal)
                    
                    // 2. Recovery Counters
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Recovery Tracker").font(.headline)
                            Spacer()
                            Button("Select Muscles") { showingSettings = true }
                                .font(.caption)
                        }
                        
                        if trackedMuscles.isEmpty {
                            Text("Select muscles to track recovery time.")
                                .font(.caption).foregroundColor(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                                ForEach(trackedMuscles, id: \.self) { muscle in
                                    RecoveryCard(muscle: muscle, days: daysSinceLastTrained(muscle))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 3. Recent History List
                    VStack(alignment: .leading) {
                        Text("Recent Workouts").font(.headline).padding(.horizontal)
                        ForEach(workouts.prefix(5)) { workout in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(workout.date, format: .dateTime.day().month())
                                        .font(.subheadline).bold()
                                    Text(workout.category)
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(workout.muscleGroups.joined(separator: ", "))
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            Divider()
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Workouts")
            .toolbar {
                Button(action: { showingAddWorkout = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView()
            }
            .sheet(isPresented: $showingSettings) {
                MuscleSelectionView(selectedMusclesString: $trackedMusclesString)
            }
        }
    }
    
    // Logic to calculate days since a specific muscle was trained
    private func daysSinceLastTrained(_ muscle: String) -> Int? {
        // Workouts are already sorted by date desc
        if let lastWorkout = workouts.first(where: { $0.muscleGroups.contains(muscle) }) {
            let components = Calendar.current.dateComponents([.day], from: lastWorkout.date, to: Calendar.current.startOfDay(for: Date()))
            return components.day
        }
        return nil
    }
}

// Subview: Recovery Card
struct RecoveryCard: View {
    let muscle: String
    let days: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(muscle).font(.headline)
            if let d = days {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(d)").font(.title).bold()
                        .foregroundColor(d > 4 ? .red : .green)
                    Text("days ago").font(.caption).foregroundColor(.secondary)
                }
            } else {
                Text("Not trained yet").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Subview: Simple Calendar Grid
struct WorkoutCalendarView: View {
    let workouts: [Workout]
    let days = ["S", "M", "T", "W", "T", "F", "S"]
    @State private var currentMonth = Date()
    
    var body: some View {
        VStack {
            // Month Header
            HStack {
                Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left") }
                Spacer()
                Text(currentMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right") }
            }
            .padding(.bottom, 10)
            
            // Days Header
            HStack {
                ForEach(days, id: \.self) { day in
                    Text(day).font(.caption).bold().frame(maxWidth: .infinity)
                }
            }
            
            // Grid
            let daysInMonth = calendarDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        let workout = workouts.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
                        
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                            
                            // Dot indicator
                            if let w = workout {
                                Circle()
                                    .fill(categoryColor(w.category))
                                    .frame(width: 6, height: 6)
                            } else {
                                Circle().fill(Color.clear).frame(width: 6, height: 6)
                            }
                        }
                        .frame(height: 40)
                        .background(Calendar.current.isDateInToday(date) ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    } else {
                        Text("").frame(height: 40)
                    }
                }
            }
        }
    }
    
    func categoryColor(_ cat: String) -> Color {
        switch cat.lowercased() {
        case "push": return .red
        case "pull": return .blue
        case "legs": return .green
        default: return .orange
        }
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    func calendarDays() -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        
        let weekday = calendar.component(.weekday, from: firstDay) // 1 = Sun, 2 = Mon...
        
        var days: [Date?] = Array(repeating: nil, count: weekday - 1)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}

// Subview: Muscle Selection Settings
struct MuscleSelectionView: View {
    @Binding var selectedMusclesString: String
    @Environment(\.dismiss) var dismiss
    
    let allMuscles = ["Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Abs", "Cardio"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allMuscles, id: \.self) { muscle in
                    HStack {
                        Text(muscle)
                        Spacer()
                        if selectedMusclesString.contains(muscle) {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleMuscle(muscle)
                    }
                }
            }
            .navigationTitle("Track Muscles")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
    
    func toggleMuscle(_ muscle: String) {
        var current = selectedMusclesString.components(separatedBy: ",").filter { !$0.isEmpty }
        if current.contains(muscle) {
            current.removeAll { $0 == muscle }
        } else {
            current.append(muscle)
        }
        selectedMusclesString = current.joined(separator: ",")
    }
}