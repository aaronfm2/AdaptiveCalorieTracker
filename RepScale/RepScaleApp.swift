import SwiftUI
import SwiftData

@main
struct RepScaleApp: App {
    @StateObject private var healthManager = HealthManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyLog.self,
            WeightEntry.self,
            Workout.self,
            ExerciseEntry.self,
            WorkoutTemplate.self,
            TemplateExerciseEntry.self,
            ExerciseDefinition.self,
            GoalPeriod.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(healthManager)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Query var userProfiles: [UserProfile]
    @AppStorage("hasSeenAppTutorial") private var hasSeenAppTutorial: Bool = false
    
    var body: some View {
        Group {
            if let profile = userProfiles.first {
                // Scenario 1: Profile Found -> Show Main App
                MainTabView(profile: profile)
                    .preferredColorScheme(profile.isDarkMode ? .dark : .light)
                    .transition(.opacity)
                
            } else {
                // Scenario 2: No Profile -> Show Onboarding
                // (If iCloud is syncing in background, this will swap to MainTabView automatically when data arrives)
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.default, value: userProfiles.isEmpty)
    }
}
