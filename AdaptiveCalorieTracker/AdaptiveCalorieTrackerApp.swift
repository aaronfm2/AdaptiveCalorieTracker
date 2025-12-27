import SwiftUI
import SwiftData

@main
struct AdaptiveCalorieTrackerApp: App {
    @StateObject private var healthManager = HealthManager()
    
    // Tracks if onboarding is finished
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyLog.self,
            WeightEntry.self,
            Workout.self,
            ExerciseEntry.self,
            WorkoutTemplate.self,
            TemplateExerciseEntry.self,
            ExerciseDefinition.self
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
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(healthManager)
            } else {
                OnboardingView(isCompleted: $hasCompletedOnboarding)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
