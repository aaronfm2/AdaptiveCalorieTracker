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
    
    // --- NEW: Master switch for Onboarding ---
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    
    var body: some View {
        Group {
            // Check BOTH the flag AND if a profile exists.
            if isOnboardingCompleted, let profile = userProfiles.first {
                // Scenario 1: Ready -> Show Main App
                MainTabView(profile: profile)
                    .preferredColorScheme(profile.isDarkMode ? .dark : .light)
                    .transition(.opacity)
                
            } else {
                // Scenario 2: Flag is false OR No Profile -> Show Onboarding
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.default, value: isOnboardingCompleted)
    }
}
