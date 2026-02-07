import SwiftUI


struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let description: String
    let color: Color
    let animationType: AnimationType
    
    enum AnimationType {
        case dots, wave, bars
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated illustration
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                page.color.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(animationProgress)
                
                // Icon and animation
                VStack {
                    Image(systemName: page.icon)
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(page.color)
                        .scaleEffect(animationProgress)
                    
                    // Custom animation based on type
                    animationView
                        .frame(height: 60)
                        .padding(.top, 20)
                }
            }
            .frame(height: 300)
            
            // Text content
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(page.subtitle)
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "9CB6C9"))
                }
                .multilineTextAlignment(.center)
                .opacity(animationProgress)
                
                Text(page.description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(hex: "9CB6C9"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animationProgress)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animationProgress = 1.0
            }
        }
    }
    
    @ViewBuilder
    private var animationView: some View {
        switch page.animationType {
        case .dots:
            DotsAnimation(progress: animationProgress, color: page.color)
        case .wave:
            WaveLineAnimation(progress: animationProgress, color: page.color)
        case .bars:
            BarsAnimation(progress: animationProgress, color: page.color)
        }
    }
}

struct DotsAnimation: View {
    let progress: CGFloat
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .scaleEffect(progress)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6)
                            .delay(Double(index) * 0.1),
                        value: progress
                    )
            }
        }
    }
}

struct WaveLineAnimation: View {
    let progress: CGFloat
    let color: Color
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, through: width * progress, by: 2) {
                    let relativeX = x / 50
                    let sine = sin(relativeX + phase)
                    let y = midHeight + sine * 15
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .trim(from: 0, to: progress)
            .stroke(color, lineWidth: 3)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct BarsAnimation: View {
    let progress: CGFloat
    let color: Color
    let barHeights: [CGFloat] = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.3]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<barHeights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 20, height: 60 * barHeights[index] * progress)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6)
                            .delay(Double(index) * 0.08),
                        value: progress
                    )
            }
        }
    }
}
