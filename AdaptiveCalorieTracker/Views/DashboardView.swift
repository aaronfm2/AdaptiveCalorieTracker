import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .forward) private var logs: [DailyLog]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @StateObject var healthManager = HealthManager()
    
    @AppStorage("dailyCalorieGoal") private var dailyGoal: Int = 2000
    @AppStorage("targetWeight") private var targetWeight: Double = 70.0
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Progress to Target Calculation
                    targetProgressCard
                    
                    // 2. Weight Trend Graph
                    VStack(alignment: .leading) {
                        Text("Weight Trend").font(.headline)
                        if logs.filter({ $0.weight != nil }).isEmpty {
                            Text("No weight data logged yet").font(.caption).foregroundColor(.secondary)
                        } else {
                            Chart {
                                ForEach(logs.filter { $0.weight != nil }) { log in
                                    LineMark(
                                        x: .value("Date", log.date),
                                        y: .value("Weight", log.weight ?? 0)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(.blue)
                                }
                            }
                            .frame(height: 180)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                    
                    // 3. Calorie Balance Graph (Last 7 Days)
                    VStack(alignment: .leading) {
                        Text("Net Calories (Last 7 Days)").font(.headline)
                        Chart {
                            ForEach(logs.suffix(7)) { log in
                                BarMark(
                                    x: .value("Day", log.date, unit: .day),
                                    y: .value("Net", log.netCalories)
                                )
                                .foregroundStyle(log.netCalories > 0 ? .red : .green)
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                }
            }
            .sheet(isPresented: $showingSettings) {
                settingsSheet
            }
            .onAppear(perform: setupOnAppear)
        }
    }

    private var targetProgressCard: some View {
        // Uses the most recent weight from WeightEntry or DailyLog
        let currentWeight = weights.first?.weight ?? logs.last(where: { $0.weight != nil })?.weight ?? 0.0
        let weightDifference = currentWeight - targetWeight
        let avgDeficit = calculateAverageDeficit()
        
        return VStack(spacing: 12) {
            Text("Target: \(targetWeight, specifier: "%.1f") kg")
                .font(.subheadline).foregroundColor(.secondary)
            
            if weightDifference > 0 && avgDeficit > 0 {
                // Calculation: 1kg of fat ≈ 7700 calories
                let totalCaloriesToLose = weightDifference * 7700
                let daysLeft = Int(totalCaloriesToLose / Double(avgDeficit))
                
                Text("\(daysLeft)")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.orange)
                Text("Days until target hit")
                    .font(.headline)
                Text("Based on 7-day avg deficit: \(avgDeficit) kcal")
                    .font(.caption).foregroundColor(.secondary)
            } else if weightDifference <= 0 && currentWeight > 0 {
                Text("Target Reached!")
                    .font(.title).bold()
                    .foregroundColor(.green)
            } else {
                Text("Pending Data")
                    .font(.title3).bold()
                Text(avgDeficit <= 0 ? "Maintain a calorie deficit to see estimate" : "Log your weight to see progress")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.orange.opacity(0.1)))
    }

    private func calculateAverageDeficit() -> Int {
        let last7Logs = logs.suffix(7)
        guard !last7Logs.isEmpty else { return 0 }
        // Deficit = Burned - Consumed
        let totalDeficit = last7Logs.reduce(0) { $0 + ($1.caloriesBurned - $1.caloriesConsumed) }
        return max(0, totalDeficit / last7Logs.count)
    }

    private var settingsSheet: some View {
        NavigationView {
            Form {
                Section("Health Goals") {
                    HStack {
                        Text("Target Weight (kg)")
                        Spacer()
                        TextField("kg", value: $targetWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Daily Calorie Goal")
                        Spacer()
                        TextField("Calories", value: $dailyGoal, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Done") { showingSettings = false }
            }
        }
    }

    private func setupOnAppear() {
        healthManager.requestAuthorization()
        healthManager.fetchTodayCaloriesBurned()
        
        // Ensure today's log exists so Dashboard graphs update immediately
        let today = Calendar.current.startOfDay(for: Date())
        if !logs.contains(where: { $0.date == today }) {
            let newItem = DailyLog(date: today)
            modelContext.insert(newItem)
        }
    }
}
