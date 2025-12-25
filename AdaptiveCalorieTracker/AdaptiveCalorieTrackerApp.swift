import SwiftUI
import SwiftData

@main
struct AdaptiveCalorieTrackerApp: App {
    // This sets up the database for DailyLog
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyLog.self, // We tell it to use our new DailyLog model
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [DailyLog.self, WeightEntry.self])
    }
}
