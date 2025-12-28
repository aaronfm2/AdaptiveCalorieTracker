import SwiftUI

struct MainTabView: View {
    // ... [Keep properties] ...
    @AppStorage("hasSeenAppTutorial") private var hasSeenAppTutorial: Bool = false
    @State private var currentTutorialStepIndex = 0
    @State private var selectedTab = 0
    
    @State private var spotlightRects: [String: CGRect] = [:]
    
    // ... [Keep tutorialSteps] ...
    private let tutorialSteps: [TutorialStep] = [
        TutorialStep(
            id: 0,
            title: "Dashboard Tab",
            description: "This is your main dashboard. It shows your weight trends, calorie balance, and goal projections.",
            tabIndex: 0,
            highlights: [.tab(index: 0)]
        ),
        TutorialStep(
            id: 1,
            title: "Settings",
            description: "Tap the Gear icon to configure your goals, dietary preferences, and calculation methods.",
            tabIndex: 0,
            highlights: [.target(.settings)]
        ),
        TutorialStep(
            id: 2,
            title: "Apple Health Sync",
            description: "Sync data from Apple Health. If you use other apps (like MyFitnessPal), ensure they are connected to Apple Health.",
            tabIndex: 0,
            highlights: []
        ),
        TutorialStep(
            id: 3,
            title: "Logs Tab",
            description: "Track your daily nutrition here. This data syncs automatically with Apple Health.",
            tabIndex: 1,
            highlights: [.tab(index: 1)]
        ),
        TutorialStep(
            id: 4,
            title: "Add Entries",
            description: "Use the + button to manually add calories or macros.",
            tabIndex: 1,
            highlights: [.target(.addLog)]
        ),
        TutorialStep(
            id: 5,
            title: "Workouts Tab",
            description: "Track your training sessions and view history.",
            tabIndex: 2,
            highlights: [.tab(index: 2)]
        ),
        TutorialStep(
            id: 6,
            title: "Workout Controls",
            description: "Top Right: Start a new workout.\nTop Left: Manage your Exercise Library.",
            tabIndex: 2,
            highlights: [.target(.addWorkout), .target(.library)]
        ),
        TutorialStep(
            id: 7,
            title: "Weight Tab",
            description: "Keep track of your weigh-ins here.",
            tabIndex: 3,
            highlights: [.tab(index: 3)]
        ),
        TutorialStep(
            id: 8,
            title: "Log Weight",
            description: "Tap the + button to log today's weight.",
            tabIndex: 3,
            highlights: [.target(.addWeight)]
        )
    ]
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView().tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }.tag(0)
                ContentView().tabItem { Label("Logs", systemImage: "list.bullet.clipboard.fill") }.tag(1)
                WorkoutTabView().tabItem { Label("Workouts", systemImage: "figure.strengthtraining.traditional") }.tag(2)
                WeightTrackerView().tabItem { Label("Weight", systemImage: "scalemass.fill") }.tag(3)
            }
            // --- FIX 1: Force Bottom Tabs on iPad ---
            .environment(\.horizontalSizeClass, .compact)
            
            if !hasSeenAppTutorial {
                TutorialOverlayView(
                    step: tutorialSteps[currentTutorialStepIndex],
                    spotlightRects: spotlightRects,
                    onNext: {
                        withAnimation {
                            if currentTutorialStepIndex < tutorialSteps.count - 1 {
                                currentTutorialStepIndex += 1
                                selectedTab = tutorialSteps[currentTutorialStepIndex].tabIndex
                            }
                        }
                    },
                    onFinish: {
                        withAnimation { hasSeenAppTutorial = true }
                    },
                    isLastStep: currentTutorialStepIndex == tutorialSteps.count - 1
                )
                .zIndex(10)
                // --- FIX 2: Ignore Safe Area to cover the Tab Bar ---
                .ignoresSafeArea()
            }
        }
        .coordinateSpace(name: "TutorialSpace")
        .onPreferenceChange(SpotlightRectsKey.self) { prefs in
            self.spotlightRects = prefs
        }
    }
}
