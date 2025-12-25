import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    @StateObject var healthManager = HealthManager()
    
    @AppStorage("dailyCalorieGoal") private var dailyGoal: Int = 2000

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                summaryHeader
                
                List {
                    ForEach(logs) { log in
                        logRow(for: log)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Daily Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addItem) { Label("Add", systemImage: "plus") }
                }
            }
            .onAppear(perform: setupOnAppear)
            .onChange(of: healthManager.caloriesBurnedToday) { _, newValue in
                updateTodayBurned(newValue)
            }
        }
    }

    @ViewBuilder
    private var summaryHeader: some View {
        if let today = logs.first(where: { Calendar.current.isDateInToday($0.date) }) {
            let remaining = dailyGoal + today.caloriesBurned - today.caloriesConsumed
            
            VStack(spacing: 5) {
                Text("\(remaining)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.blue)
                Text("Calories Left Today")
                    .font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.05))
        }
    }

    private func logRow(for log: DailyLog) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(log.date, style: .date).font(.body)
                if let w = log.weight {
                    Text("\(w, specifier: "%.1f") kg").font(.caption).foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife").font(.caption2)
                    Text("\(log.caloriesConsumed) kcal")
                }.foregroundColor(.blue)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.caption2)
                    Text("\(log.caloriesBurned) kcal")
                }.foregroundColor(.orange)
            }
            .font(.subheadline)
        }
    }

    private func setupOnAppear() {
        healthManager.fetchTodayCaloriesBurned()
        let today = Calendar.current.startOfDay(for: Date())
        if !logs.contains(where: { $0.date == today }) {
            addItem()
        }
    }

    private func updateTodayBurned(_ newValue: Double) {
        let todayDate = Calendar.current.startOfDay(for: Date())
        if let today = logs.first(where: { $0.date == todayDate }) {
            today.caloriesBurned = Int(newValue)
        }
    }

    private func addItem() {
        let today = Calendar.current.startOfDay(for: Date())
        if !logs.contains(where: { $0.date == today }) {
            withAnimation {
                let newItem = DailyLog(date: today)
                modelContext.insert(newItem)
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(logs[index]) }
        }
    }
}
