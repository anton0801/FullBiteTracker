import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = SessionViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary Cards
                        HStack(spacing: 16) {
                            SummaryCard(
                                title: "Total Bites",
                                value: "\(viewModel.currentSessionBites.count)",
                                icon: "circle.grid.cross.fill",
                                color: AppColors.primaryAccent
                            )
                            
                            SummaryCard(
                                title: "Caught",
                                value: "\(viewModel.dataManager.currentSession?.caughtCount ?? 0)",
                                icon: "checkmark.circle.fill",
                                color: AppColors.highActivity
                            )
                        }
                        .padding(.horizontal)
                        
                        // Timeline
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Activity Timeline")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            if viewModel.currentSessionBites.isEmpty {
                                EmptyTimelineView()
                            } else {
                                BiteTimelineView(bites: viewModel.currentSessionBites)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .cardStyle()
                        .padding(.horizontal)
                        
                        // Bites List
                        if !viewModel.currentSessionBites.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Bites")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.currentSessionBites.reversed()) { bite in
                                    BiteRow(bite: bite)
                                        .onTapGesture {
                                            viewModel.editingBite = bite
                                            viewModel.showingAddBite = true
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    viewModel.deleteBite(bite)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.vertical)
                            .cardStyle()
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            viewModel.editingBite = nil
                            viewModel.showingAddBite = true
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Today Activity")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showingAddBite) {
                AddBiteView(viewModel: viewModel, editingBite: viewModel.editingBite)
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @State private var count: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text("\(count)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .onAppear {
            animateCount()
        }
        .onChange(of: value) { _ in
            animateCount()
        }
    }
    
    private func animateCount() {
        let target = Int(value) ?? 0
        count = 0
        
        let duration: Double = 0.5
        let steps = min(target, 30)
        let stepDuration = duration / Double(steps)
        
        if steps > 1 {
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                    count = Int(Double(target) * (Double(i) / Double(steps)))
                }
            }
        }
    }
}

struct BiteRow: View {
    let bite: Bite
    
    var body: some View {
        HStack(spacing: 16) {
            // Time
            VStack(alignment: .leading, spacing: 4) {
                Text(bite.timeString)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(bite.hour):00 - \(bite.hour + 1):00")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Strength Indicator
            Circle()
                .fill(Color(hex: bite.strength.color))
                .frame(width: 12, height: 12)
            
            Text(bite.strength.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            // Result
            Image(systemName: bite.result.icon)
                .font(.system(size: 20))
                .foregroundColor(bite.result == .caught ? AppColors.highActivity : AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EmptyTimelineView: View {
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppColors.divider, lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(AppColors.primaryAccent)
                    .frame(width: 20, height: 20)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.5 : 1.0)
            }
            
            Text("Tap + to log first bite")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            action()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primaryAccent, AppColors.highActivity],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: AppColors.primaryAccent.opacity(0.5), radius: 10, x: 0, y: 5)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}
