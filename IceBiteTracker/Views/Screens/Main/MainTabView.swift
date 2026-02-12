import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "clock.fill")
                }
                .tag(0)
            
            SessionsListView()
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet")
                }
                .tag(1)
            
            GearView()
                .tabItem {
                    Label("Gear", systemImage: "figure.fishing")
                }
                .tag(2)
            
            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.bar.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(AppColors.primaryAccent)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppColors.cardBackground)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
