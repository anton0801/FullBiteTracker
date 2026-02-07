import SwiftUI

struct CustomButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppColors.primaryAccent
            case .secondary: return AppColors.cardBackground
            case .destructive: return AppColors.lowActivity
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary: return AppColors.background
            case .secondary: return AppColors.textPrimary
            case .destructive: return .white
            }
        }
    }
    
    var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(style.textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(style.backgroundColor)
                )
                .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(SpringButtonStyle(isPressed: $isPressed))
    }
}

struct SpringButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = pressed
                }
            }
    }
}
