import SwiftUI
import Combine

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.95
    @State private var opacity: Double = 0.0
    @State private var waveOffset: CGFloat = 0
    @State private var snowflakeRotation: Double = 0
    
    @StateObject private var program = Program()
    @State private var streams = Set<AnyCancellable>()
    
    private func setupEventStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { program.send(.trackingArrived($0)) }
            .store(in: &streams)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { program.send(.linkingArrived($0)) }
            .store(in: &streams)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "071B27"),
                        Color(hex: "0F2F42")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated particles
                GeometryReader { geometry in
                    ForEach(0..<20, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: CGFloat.random(in: 2...6))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 3...6))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                value: opacity
                            )
                    }
                }
                
                VStack(spacing: 24) {
                    ZStack {
                        // Wave effect
                        WaveShape(offset: waveOffset)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "4FC3F7").opacity(0.6),
                                        Color(hex: "6FE3C1").opacity(0.4)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 120, height: 60)
                            .offset(y: 20)
                        
                        // Snowflake icon
                        Image(systemName: "snowflake")
                            .font(.system(size: 60, weight: .thin))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "4FC3F7"),
                                        Color(hex: "6FE3C1")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(snowflakeRotation))
                            .shadow(color: Color(hex: "4FC3F7").opacity(0.5), radius: 20)
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                    
                    // App name
                    VStack(spacing: 8) {
                        Text("FULL BITE")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(4)
                        
                        Text("TRACKER")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "9CB6C9"))
                            .tracking(8)
                    }
                    .opacity(opacity)
                }
                
                NavigationLink(destination: BiteWebView().navigationBarBackButtonHidden(true), isActive: $program.viewModel.navigateToContent) {
                    EmptyView()
                }

                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $program.viewModel.navigateToMain
                ) {
                    EmptyView()
                }
            }
            .onAppear {
                // Scale and fade animation
                
                setupEventStreams()
                
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                // Wave animation
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    waveOffset = 20
                }
                
                // Snowflake rotation
                withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                    snowflakeRotation = 360
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())

        .fullScreenCover(isPresented: $program.viewModel.showAlertPrompt) {
            BiteAlertView(program: program)
        }

        .fullScreenCover(isPresented: $program.viewModel.showOfflineView) {
            UnavailableView()
        }
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 4 + offset / 10)
            let y = midHeight + sine * 15
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("wifi_screen_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                Image("wifi_screen_alert")
                    .resizable()
                    .frame(width: 300, height: 270)
            }
        }
        .ignoresSafeArea()
    }
}
