import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    func glassEffect() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.divider, lineWidth: 1)
                    )
                    .blur(radius: 0.5)
            )
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}
