import SwiftUI
import SwiftData

struct GoalConfigurationView: View {
    // --- CLOUD SYNC: Injected Profile ---
    @Bindable var profile: UserProfile
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Passed from Parent (Calculated values, not stored)
    let appEstimatedMaintenance: Int?
    let latestWeightKg: Double?
    
    // Local State for Form Inputs
    @State private var localGoalType: GoalType = .cutting
    @State private var localTargetWeight: Double = 70.0
    @State private var localMaintenance: String = ""
    @State private var localDailyGoal: String = ""
    @State private var targetDate: Date = Date()
    @State private var recommendedGoal: Int?
    
    // Helpers
    var unitLabel: String { profile.unitSystem == UnitSystem.imperial.rawValue ? "lbs" : "kg" }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Goal Type
                Section(header: Text("Goal Strategy")) {
                    Picker("Goal Type", selection: $localGoalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: localGoalType) { _, _ in calculateRecommendation() }
                }
                
                // MARK: - Targets
                Section(header: Text("Targets")) {
                    // Target Weight
                    HStack {
                        Text("Target Weight (\(unitLabel))")
                        Spacer()
                        TextField("Required", value: $localTargetWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    if localGoalType != .maintenance {
                        DatePicker("Target Date", selection: $targetDate, in: Date()..., displayedComponents: .date)
                            .onChange(of: targetDate) { _, _ in calculateRecommendation() }
                    }
                }
                
                // MARK: - Energy Settings
                Section(header: Text("Calorie Settings")) {
                    HStack {
                        Text("Maintenance Calories")
                        Spacer()
                        TextField("kcal", text: $localMaintenance)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: localMaintenance) { _, _ in calculateRecommendation() }
                    }
                    
                    HStack {
                        Text("Daily Goal")
                        Spacer()
                        TextField("kcal", text: $localDailyGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    if let rec = recommendedGoal {
                        HStack {
                            Text("Recommended based on date:")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("\(rec) kcal")
                                .font(.caption).bold().foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Information
                if let estimate = appEstimatedMaintenance {
                    Section {
                        HStack {
                            Text("App Estimated Maintenance:")
                            Spacer()
                            Text("\(estimate) kcal").bold()
                        }
                        .foregroundColor(.secondary)
                        .font(.caption)
                    } footer: {
                        Text("Calculated from your logged weight and calorie data over the last 30 days.")
                    }
                }
            }
            .navigationTitle("Reconfigure Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadCurrentSettings)
        }
    }
    
    // MARK: - Logic
    
    private func loadCurrentSettings() {
        // Load from Profile
        if let type = GoalType(rawValue: profile.goalType) {
            localGoalType = type
        }
        
        // Convert stored Kg to display unit
        localTargetWeight = profile.targetWeight.toUserWeight(system: profile.unitSystem)
        
        localMaintenance = String(profile.maintenanceCalories)
        localDailyGoal = String(profile.dailyCalorieGoal)
        
        // Default target date (arbitrary, usually user sets this fresh)
        targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    }
    
    private func saveChanges() {
        // Save back to Profile
        profile.goalType = localGoalType.rawValue
        
        // Convert display unit back to Kg
        profile.targetWeight = localTargetWeight.toStoredWeight(system: profile.unitSystem)
        
        if let m = Int(localMaintenance) { profile.maintenanceCalories = m }
        if let g = Int(localDailyGoal) { profile.dailyCalorieGoal = g }
        
        // Also update the active GoalPeriod in DataManager logic if needed
        // (Assuming you want to track this history)
        let dataManager = DataManager(modelContext: modelContext)
        dataManager.startNewGoalPeriod(
            goalType: localGoalType.rawValue,
            startWeight: latestWeightKg ?? 0, // Fallback if weight unknown
            targetWeight: profile.targetWeight,
            dailyCalorieGoal: profile.dailyCalorieGoal,
            maintenanceCalories: profile.maintenanceCalories
        )
    }
    
    private func calculateRecommendation() {
        guard localGoalType != .maintenance else {
            // For maintenance, goal = maintenance
            localDailyGoal = localMaintenance
            recommendedGoal = nil
            return
        }
        
        guard let maintenance = Int(localMaintenance),
              let currentWeight = latestWeightKg else { return }
        
        let targetKg = localTargetWeight.toStoredWeight(system: profile.unitSystem)
        let weightDiff = targetKg - currentWeight
        
        // If goals conflict (e.g. cutting but target > current)
        if (localGoalType == .cutting && weightDiff > 0) ||
           (localGoalType == .bulking && weightDiff < 0) {
            recommendedGoal = nil
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: targetDate)
        let components = Calendar.current.dateComponents([.day], from: today, to: end)
        let days = components.day ?? 1
        
        guard days > 0 else { return }
        
        // 7700 kcal per kg approx
        let totalCaloriesNeeded = weightDiff * 7700.0
        let dailyAdjustment = Int(totalCaloriesNeeded / Double(days))
        
        let calculated = maintenance + dailyAdjustment
        recommendedGoal = calculated
        
        // Optional: Auto-fill daily goal if it wasn't manually edited yet
        // localDailyGoal = String(calculated)
    }
}
