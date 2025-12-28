import Foundation
import SwiftUI

// Struct to package all the settings needed for calculation
struct DashboardSettings {
    var dailyGoal: Int
    var targetWeight: Double
    var goalType: String
    var maintenanceCalories: Int
    var estimationMethod: Int
    var enableCaloriesBurned: Bool
    var isCalorieCountingEnabled: Bool
}

// Struct for the graph
struct ProjectionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let method: String
}

// --- NEW: Weight Change Metric Struct ---
struct WeightChangeMetric: Identifiable {
    let id = UUID()
    let period: String
    let value: Double?
}

@Observable
class DashboardViewModel {
    // MARK: - Output State
    var daysRemaining: Int?
    var estimatedMaintenance: Int?
    var projectionPoints: [ProjectionPoint] = []
    
    // --- NEW: Weight Change Metrics ---
    var weightChangeMetrics: [WeightChangeMetric] = []
    
    var logicDescription: String = ""
    var progressWarningMessage: String = ""
    
    // MARK: - Primary Calculation Function
    func updateMetrics(logs: [DailyLog], weights: [WeightEntry], settings: DashboardSettings) {
        
        // If calorie counting is disabled, we FORCE method 0 (Trend) logic
        // regardless of what the user selected in settings previously.
        let effectiveMethod = settings.isCalorieCountingEnabled ? settings.estimationMethod : 0
        
        updateLogicDescription(method: effectiveMethod)
        
        // 1. Calculate Maintenance
        // If disabled, we can't calculate maintenance from food logs accurately.
        if settings.isCalorieCountingEnabled {
            self.estimatedMaintenance = calculateEstimatedMaintenance(logs: logs, weights: weights)
        } else {
            self.estimatedMaintenance = nil
        }
        
        // 2. Calculate Days Remaining
        self.daysRemaining = calculateDaysRemaining(
            weights: weights,
            logs: logs,
            settings: settings,
            forcedMethod: effectiveMethod // Pass effective method
        )
        updateWarningMessage(settings: settings, hasDaysEstimate: daysRemaining != nil, effectiveMethod: effectiveMethod)
        
        // 3. Generate Projections
        self.projectionPoints = generateProjections(
            startWeight: weights.first?.weight ?? 0,
            weights: weights,
            logs: logs,
            settings: settings
        )
        
        // 4. Calculate Weight Changes (7, 30, 90, All Time)
        calculateWeightChanges(weights: weights)
    }
    
    // MARK: - Internal Logic
    
    private func calculateWeightChanges(weights: [WeightEntry]) {
        // weights are expected to be sorted reverse (newest first)
        guard let latestEntry = weights.first else {
            self.weightChangeMetrics = []
            return
        }
        
        let currentWeight = latestEntry.weight
        let today = Date()
        var metrics: [WeightChangeMetric] = []
        
        let periods = [7, 30, 90]
        
        for days in periods {
            if let targetDate = Calendar.current.date(byAdding: .day, value: -days, to: today) {
                // Find the first entry that is ON or BEFORE the target date.
                // Since the list is Newest -> Oldest, this gives us the most recent entry relative to that past date.
                if let pastEntry = weights.first(where: { $0.date <= targetDate }) {
                    let diff = currentWeight - pastEntry.weight
                    metrics.append(WeightChangeMetric(period: "\(days) Days", value: diff))
                }
                // --- UPDATED LOGIC: Fallback to oldest available entry if history is short ---
                else if let oldestEntry = weights.last {
                    let diff = currentWeight - oldestEntry.weight
                    metrics.append(WeightChangeMetric(period: "\(days) Days", value: diff))
                } else {
                    metrics.append(WeightChangeMetric(period: "\(days) Days", value: nil))
                }
            }
        }
        
        // All Time Change (Compare to the very last entry in the list, which is the oldest)
        if let firstEntry = weights.last {
            let diff = currentWeight - firstEntry.weight
            metrics.append(WeightChangeMetric(period: "All Time", value: diff))
        } else {
            metrics.append(WeightChangeMetric(period: "All Time", value: nil))
        }
        
        self.weightChangeMetrics = metrics
    }
    
    private func updateLogicDescription(method: Int) {
        switch method {
        case 0: logicDescription = "Based on 30-day Weight Trend"
        case 1: logicDescription = "Based on 7-day Average Calorie Intake"
        case 2: logicDescription = "Based on Fixed Daily Calorie Amount"
        default: logicDescription = ""
        }
    }
    
    private func updateWarningMessage(settings: DashboardSettings, hasDaysEstimate: Bool, effectiveMethod: Int) {
        if hasDaysEstimate {
            progressWarningMessage = ""
            return
        }
        
        switch effectiveMethod {
        case 0: // Weight Trend
            progressWarningMessage = "Need more weight data over 30 days, or trend is moving away from goal."
        case 1: // Avg Intake
            progressWarningMessage = settings.goalType == GoalType.cutting.rawValue
                ? "Eat less than maintenance on average to see estimate"
                : "Eat more than maintenance on average to see estimate"
        case 2: // Fixed Target
            progressWarningMessage = settings.goalType == GoalType.cutting.rawValue
                ? "Your daily goal must be lower than your maintenance (\(settings.maintenanceCalories))"
                : "Your daily goal must be higher than your maintenance (\(settings.maintenanceCalories))"
        default:
            progressWarningMessage = ""
        }
    }

    private func calculateEstimatedMaintenance(logs: [DailyLog], weights: [WeightEntry]) -> Int? {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let recentWeights = weights.filter { $0.date >= thirtyDaysAgo }.sorted { $0.date < $1.date }
            
            guard let first = recentWeights.first, let last = recentWeights.last, first.id != last.id else { return nil }
            
            let start = Calendar.current.startOfDay(for: first.date)
            let end = Calendar.current.startOfDay(for: last.date)
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            guard days > 0 else { return nil }
            
            let weightChange = last.weight - first.weight
            let today = Calendar.current.startOfDay(for: Date())
            
            // --- UPDATED FILTER: Exclude days with 0 calories ---
            let relevantLogs = logs.filter {
                $0.date >= first.date &&
                $0.date <= last.date &&
                $0.date < today &&
                $0.caloriesConsumed > 0 // Ignore empty logs
            }
            
            guard !relevantLogs.isEmpty else { return nil }
            
            let totalConsumed = relevantLogs.reduce(0) { $0 + $1.caloriesConsumed }
            let avgDailyIntake = Double(totalConsumed) / Double(relevantLogs.count)
            let dailyImbalance = (weightChange * 7700.0) / Double(days)
            
            return Int(avgDailyIntake - dailyImbalance)
        }

    private func calculateKgChangePerDay(method: Int, weights: [WeightEntry], logs: [DailyLog], maintenanceCalories: Int, dailyGoal: Int) -> Double? {
        // Method 0: Weight Trend (Last 30 Days)
        if method == 0 {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let recentWeights = weights.filter { $0.date >= thirtyDaysAgo }.sorted { $0.date < $1.date }
            
            guard let first = recentWeights.first, let last = recentWeights.last, first.id != last.id else { return nil }
            
            let start = Calendar.current.startOfDay(for: first.date)
            let end = Calendar.current.startOfDay(for: last.date)
            let timeSpan = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            
            if timeSpan > 0 {
                let weightChange = last.weight - first.weight
                return weightChange / Double(timeSpan)
            }
        }
        
        // Method 1: Avg Intake
        if method == 1 {
            let today = Calendar.current.startOfDay(for: Date())
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            let recentLogs = logs.filter { $0.date >= sevenDaysAgo && $0.date < today }
            
            if !recentLogs.isEmpty {
                let totalConsumed = recentLogs.reduce(0) { $0 + $1.caloriesConsumed }
                let avgConsumed = Double(totalConsumed) / Double(recentLogs.count)
                return (avgConsumed - Double(maintenanceCalories)) / 7700.0
            }
        }
        
        // Method 2: Fixed Target
        if method == 2 {
            return (Double(dailyGoal) - Double(maintenanceCalories)) / 7700.0
        }
        
        return nil
    }

    private func calculateDaysRemaining(weights: [WeightEntry], logs: [DailyLog], settings: DashboardSettings, forcedMethod: Int) -> Int? {
        guard let currentWeight = weights.first?.weight else { return nil }
        
        guard let kgPerDay = calculateKgChangePerDay(
            method: forcedMethod,
            weights: weights,
            logs: logs,
            maintenanceCalories: settings.maintenanceCalories,
            dailyGoal: settings.dailyGoal
        ) else { return nil }
        
        if settings.goalType == GoalType.cutting.rawValue && kgPerDay >= 0 { return nil }
        if settings.goalType == GoalType.bulking.rawValue && kgPerDay <= 0 { return nil }
        
        let weightDiff = settings.targetWeight - currentWeight
        let days = weightDiff / kgPerDay
        
        return days > 0 ? Int(days) : nil
    }
    
    private func generateProjections(startWeight: Double, weights: [WeightEntry], logs: [DailyLog], settings: DashboardSettings) -> [ProjectionPoint] {
        var points: [ProjectionPoint] = []
        let today = Date()
        
        // If disabled, ONLY calculate method 0. Otherwise show all 3 for comparison.
        var comparisonMethods = [(0, "Trend (30d)"), (1, "Avg Intake (7d)"), (2, "Fixed Goal")]
        if !settings.isCalorieCountingEnabled {
            comparisonMethods = [(0, "Trend (30d)")]
        }
        
        for (methodId, label) in comparisonMethods {
            if let rate = calculateKgChangePerDay(
                method: methodId,
                weights: weights,
                logs: logs,
                maintenanceCalories: settings.maintenanceCalories,
                dailyGoal: settings.dailyGoal
            ) {
                points.append(ProjectionPoint(date: today, weight: startWeight, method: label))
                for i in 1...60 {
                    let nextDate = Calendar.current.date(byAdding: .day, value: i, to: today)!
                    let projectedWeight = startWeight + (rate * Double(i))
                    points.append(ProjectionPoint(date: nextDate, weight: projectedWeight, method: label))
                }
            }
        }
        return points
    }
}
