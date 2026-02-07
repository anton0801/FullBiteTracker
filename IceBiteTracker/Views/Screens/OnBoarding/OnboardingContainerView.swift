import SwiftUI

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    @Binding var showOnboarding: Bool
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Log every bite",
            subtitle: "with time",
            icon: "clock.fill",
            description: "Track each bite instantly with precise timing",
            color: Color(hex: "4FC3F7"),
            animationType: .dots
        ),
        OnboardingPage(
            title: "See activity peaks",
            subtitle: "during the day",
            icon: "waveform.path.ecg",
            description: "Visualize when fish are most active",
            color: Color(hex: "6FE3C1"),
            animationType: .wave
        ),
        OnboardingPage(
            title: "Find patterns",
            subtitle: "across trips",
            icon: "chart.bar.fill",
            description: "Discover your best fishing times",
            color: Color(hex: "4FC3F7"),
            animationType: .bars
        )
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "071B27").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color(hex: "4FC3F7") : Color(hex: "123A4F"))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        CustomButton(title: "Get Started", style: .primary) {
                            completeOnboarding()
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        CustomButton(title: "Continue", style: .primary) {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                    
                    Button(action: completeOnboarding) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "9CB6C9"))
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.easeOut(duration: 0.4)) {
            showOnboarding = false
        }
    }
}
