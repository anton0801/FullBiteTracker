import SwiftUI

struct GearDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let gear: FishingGear
    let statistics: GearStatistics
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        VStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color(hex: gear.color).opacity(0.3),
                                                Color(hex: gear.color).opacity(0.1)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: gear.category.icon)
                                    .font(.system(size: 50))
                                    .foregroundColor(Color(hex: gear.color))
                            }
                            
                            VStack(spacing: 8) {
                                Text(gear.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(gear.category.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: gear.color).opacity(0.2))
                                    .cornerRadius(12)
                            }
                            
                            if !gear.notes.isEmpty {
                                Text(gear.notes)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .cardStyle()
                        .padding(.horizontal)
                        
                        // Statistics Summary
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(
                                title: "Total Uses",
                                value: "\(statistics.totalBites)",
                                icon: "circle.grid.cross.fill"
                            )
                            
                            StatCard(
                                title: "Caught",
                                value: "\(statistics.caughtCount)",
                                icon: "checkmark.circle.fill"
                            )
                            
                            StatCard(
                                title: "Success Rate",
                                value: String(format: "%.0f%%", statistics.successRate),
                                icon: "chart.line.uptrend.xyaxis"
                            )
                            
                            StatCard(
                                title: "Efficiency",
                                value: String(format: "%.1f", statistics.efficiencyScore),
                                icon: "star.fill"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Performance Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Performance Breakdown")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            GearPerformanceChart(statistics: statistics)
                                .frame(height: 200)
                                .padding()
                        }
                        .cardStyle()
                        .padding(.horizontal)
                        
                        // Detailed Stats
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Detailed Statistics")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                DetailStatRow(
                                    icon: "checkmark.circle.fill",
                                    label: "Caught",
                                    value: "\(statistics.caughtCount)",
                                    color: AppColors.highActivity
                                )
                                
                                DetailStatRow(
                                    icon: "circle.dotted",
                                    label: "Hooked",
                                    value: "\(statistics.hookedCount)",
                                    color: AppColors.primaryAccent
                                )
                                
                                DetailStatRow(
                                    icon: "xmark.circle",
                                    label: "Missed",
                                    value: "\(statistics.missCount)",
                                    color: AppColors.lowActivity
                                )
                                
                                Divider()
                                    .background(AppColors.divider)
                                
                                DetailStatRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    label: "Avg Strength",
                                    value: String(format: "%.1f", statistics.averageStrength),
                                    color: AppColors.textSecondary
                                )
                                
                                if let bestHour = statistics.bestHour {
                                    DetailStatRow(
                                        icon: "clock.fill",
                                        label: "Best Hour",
                                        value: "\(bestHour):00",
                                        color: AppColors.textSecondary
                                    )
                                }
                                
                                if let lastUsed = statistics.lastUsed {
                                    DetailStatRow(
                                        icon: "calendar",
                                        label: "Last Used",
                                        value: formatDate(lastUsed),
                                        color: AppColors.textSecondary
                                    )
                                }
                            }
                            .padding()
                        }
                        .cardStyle()
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Gear Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.primaryAccent)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct GearPerformanceChart: View {
    let statistics: GearStatistics
    
    var body: some View {
        let total = max(statistics.totalBites, 1)
        let caughtPercent = CGFloat(statistics.caughtCount) / CGFloat(total)
        let hookedPercent = CGFloat(statistics.hookedCount) / CGFloat(total)
        let missedPercent = CGFloat(statistics.missCount) / CGFloat(total)
        
        VStack(spacing: 16) {
            // Stacked Bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    if statistics.caughtCount > 0 {
                        Rectangle()
                            .fill(AppColors.highActivity)
                            .frame(width: geometry.size.width * caughtPercent)
                    }
                    
                    if statistics.hookedCount > 0 {
                        Rectangle()
                            .fill(AppColors.primaryAccent)
                            .frame(width: geometry.size.width * hookedPercent)
                    }
                    
                    if statistics.missCount > 0 {
                        Rectangle()
                            .fill(AppColors.lowActivity)
                            .frame(width: geometry.size.width * missedPercent)
                    }
                }
                .cornerRadius(8)
            }
            .frame(height: 40)
            
            // Legend
            HStack(spacing: 24) {
                LegendItem(
                    color: AppColors.highActivity,
                    label: "Caught",
                    count: statistics.caughtCount
                )
                
                LegendItem(
                    color: AppColors.primaryAccent,
                    label: "Hooked",
                    count: statistics.hookedCount
                )
                
                LegendItem(
                    color: AppColors.lowActivity,
                    label: "Missed",
                    count: statistics.missCount
                )
            }
            
            // Efficiency Score
            VStack(spacing: 8) {
                Text("Efficiency Score")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                Text(String(format: "%.2f", statistics.efficiencyScore))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.primaryAccent)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                
                Text("\(count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

struct DetailStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}
