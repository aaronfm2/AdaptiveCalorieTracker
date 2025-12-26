import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: Dashboard
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            // Tab 2: Logs
            ContentView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.clipboard.fill")
                }
            
            // Tab 3: Workouts (NEW)
            WorkoutTabView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }
            
            // Tab 4: Weight
            WeightTrackerView()
                .tabItem {
                    Label("Weight", systemImage: "scalemass.fill")
                }
        }
    }
}
