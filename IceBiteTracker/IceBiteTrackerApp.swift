import SwiftUI

@main
struct IceBiteTrackerApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegateApp
    
    var body: some Scene {
        WindowGroup {
            ZStack {
               SplashScreenView()
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {

    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingContainerView(showOnboarding: $showOnboarding)
            } else {
                MainTabView()
            }
        }
    }
    
}

class AttributionHandler: NSObject {
    var onTracking: (([AnyHashable: Any]) -> Void)?
    var onLinking: (([AnyHashable: Any]) -> Void)?
    
    private var trackingBuffer: [AnyHashable: Any] = [:]
    private var linkingBuffer: [AnyHashable: Any] = [:]
    private var timer: Timer?
    private let flag = "fb_attribution_merged"
    
    func receiveTracking(_ data: [AnyHashable: Any]) {
        trackingBuffer = data
        scheduleTimer()
        if !linkingBuffer.isEmpty { merge() }
    }
    
    func receiveLinking(_ data: [AnyHashable: Any]) {
        guard !isMerged() else { return }
        linkingBuffer = data
        onLinking?(data)
        timer?.invalidate()
        if !trackingBuffer.isEmpty { merge() }
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.merge() }
    }
    
    private func merge() {
        var result = trackingBuffer
        linkingBuffer.forEach { key, value in
            let newKey = "deep_\(key)"
            if result[newKey] == nil { result[newKey] = value }
        }
        onTracking?(result)
    }
    
    private func isMerged() -> Bool {
        UserDefaults.standard.bool(forKey: flag)
    }
}
