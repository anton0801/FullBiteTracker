import SwiftUI

@main
struct IceBiteTrackerApp: App {
    @State private var showSplash = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView(isActive: $showSplash)
                } else if showOnboarding {
                    OnboardingContainerView(showOnboarding: $showOnboarding)
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
