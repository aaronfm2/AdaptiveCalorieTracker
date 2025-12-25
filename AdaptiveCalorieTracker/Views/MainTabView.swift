import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: New Dashboard with Graphs
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            // Tab 2: Your original tracker (The list/log)
            ContentView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.clipboard.fill")
                }
            
            // Tab 3: Weight history
            WeightTrackerView()
                .tabItem {
                    Label("Weight", systemImage: "scalemass.fill")
                }
        }
    }
}
