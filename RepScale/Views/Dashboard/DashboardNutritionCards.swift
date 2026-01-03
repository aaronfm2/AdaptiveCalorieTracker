import SwiftUI
import SwiftData
import Charts

enum NutritionMetric: String, CaseIterable, Identifiable {
    case calories = "Calories"
    case protein = "Protein"
    case carbs = "Carbs"
    case fat = "Fat"
    
    var id: String { rawValue }
    
    var unit: String {
        switch self {
        case .calories: return "kcal"
        case .protein, .carbs, .fat: return "g"
        }
    }
    
    var color: Color {
        switch self {
        case .calories: return .orange
        case .protein: return .blue
        case .carbs: return .green
        case .fat: return .red
        }
    }
}

struct MonthlyNutritionData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct NutritionHistoryCard: View {
    var profile: UserProfile
    var index: Int
    var totalCount: Int
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    
    @Query(sort: \DailyLog.date, order: .forward) private var logs: [DailyLog]
    @State private var selectedMetric: NutritionMetric = .calories
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrition History")
                        .font(.headline)
                    Text("Monthly Average")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Reorder Buttons
                HStack(spacing: 4) {
                    if index > 0 {
                        Button(action: onMoveUp) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                    }
                    if index < totalCount - 1 {
                        Button(action: onMoveDown) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                    }
                }
            }
            
            // Picker
            Picker("Metric", selection: $selectedMetric) {
                ForEach(NutritionMetric.allCases) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)
            
            // Chart
            let data = calculateMonthlyAverages()
            
            if data.isEmpty {
                ContentUnavailableView("No Data", systemImage: "chart.bar.xaxis", description: Text("Log your nutrition to see monthly trends."))
                    .frame(height: 200)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value(selectedMetric.rawValue, item.value)
                    )
                    .foregroundStyle(selectedMetric.color.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated))
                            }
                        }
                    }
                }
                .frame(height: 220)
                
                // Average Indicator
                if let last = data.last {
                    HStack {
                        Text("Latest Average:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(Int(last.value)) \(selectedMetric.unit)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(selectedMetric.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func calculateMonthlyAverages() -> [MonthlyNutritionData] {
        // Group logs by Year+Month
        let grouped = Dictionary(grouping: logs) { log -> DateComponents in
            Calendar.current.dateComponents([.year, .month], from: log.date)
        }
        
        var results: [MonthlyNutritionData] = []
        
        for (components, monthLogs) in grouped {
            guard let date = Calendar.current.date(from: components) else { continue }
            
            let totalValue: Double = monthLogs.reduce(0) { sum, log in
                switch selectedMetric {
                case .calories:
                    return sum + Double(log.caloriesConsumed)
                case .protein:
                    return sum + Double(log.protein ?? 0)
                case .carbs:
                    return sum + Double(log.carbs ?? 0)
                case .fat:
                    return sum + Double(log.fat ?? 0)
                }
            }
            
            // Filter out logs that have 0 for the selected metric to avoid skewing average with empty days
            let validLogCount = monthLogs.filter { log in
                switch selectedMetric {
                case .calories: return log.caloriesConsumed > 0
                case .protein: return (log.protein ?? 0) > 0
                case .carbs: return (log.carbs ?? 0) > 0
                case .fat: return (log.fat ?? 0) > 0
                }
            }.count
            
            if validLogCount > 0 {
                let average = totalValue / Double(validLogCount)
                results.append(MonthlyNutritionData(date: date, value: average))
            }
        }
        
        return results.sorted { $0.date < $1.date }
    }
}
