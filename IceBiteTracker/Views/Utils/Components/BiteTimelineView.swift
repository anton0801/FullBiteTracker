import SwiftUI

struct BiteTimelineView: View {
    let bites: [Bite]
    let startHour: Int = 6
    let endHour: Int = 18
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Timeline background
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.divider)
                    .frame(height: 4)
                
                // Hour markers
                HStack(spacing: 0) {
                    ForEach(startHour...endHour, id: \.self) { hour in
                        VStack {
                            Rectangle()
                                .fill(AppColors.textSecondary.opacity(0.3))
                                .frame(width: 1, height: 8)
                            
                            Text("\(hour):00")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 12)
                
                // Bite markers
                ForEach(bites) { bite in
                    BiteMarker(bite: bite)
                        .offset(x: xPosition(for: bite, in: geometry.size.width))
                }
            }
        }
        .frame(height: 60)
    }
    
    private func xPosition(for bite: Bite, in width: CGFloat) -> CGFloat {
        let hour = Calendar.current.component(.hour, from: bite.timestamp)
        let minute = Calendar.current.component(.minute, from: bite.timestamp)
        let totalMinutes = CGFloat((hour - startHour) * 60 + minute)
        let totalRangeMinutes = CGFloat((endHour - startHour) * 60)
        
        return (totalMinutes / totalRangeMinutes) * width
    }
}

struct BiteMarker: View {
    let bite: Bite
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: bite.strength.color),
                        Color(hex: bite.strength.color).opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(Color(hex: bite.strength.color), lineWidth: 2)
                    .scaleEffect(isAnimating ? 1.4 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
            )
            .shadow(color: Color(hex: bite.strength.color).opacity(0.5), radius: 4)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}
