import SwiftUI

struct AnalysisView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time range selector
                        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                            ForEach(AnalyticsViewModel.TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        // Hourly Activity Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Hourly Activity")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            HourlyActivityChart(data: viewModel.hourlyActivity)
                                .frame(height: 200)
                                .padding()
                        }
                        .cardStyle()
                        .padding(.horizontal)
                        
                        // Result Breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Result Breakdown")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            ResultBreakdownView(data: viewModel.resultBreakdown)
                        }
                        .padding(.vertical)
                        .cardStyle()
                        .padding(.horizontal)
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(
                                title: "Total Bites",
                                value: "\(viewModel.totalBites)",
                                icon: "circle.grid.cross.fill"
                            )
                            
                            StatCard(
                                title: "Avg Strength",
                                value: String(format: "%.1f", viewModel.averageStrength),
                                icon: "chart.line.uptrend.xyaxis"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HourlyActivityChart: View {
    let data: [(hour: Int, count: Int)]
    
    var body: some View {
        GeometryReader { geometry in
            let maxCount = data.map { $0.count }.max() ?? 1
            let barWidth = (geometry.size.width - CGFloat((data.count - 1) * 4)) / CGFloat(max(data.count, 1))
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data, id: \.hour) { item in
                    VStack(spacing: 8) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.primaryAccent,
                                        AppColors.primaryAccent.opacity(0.6)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: barWidth,
                                height: CGFloat(item.count) / CGFloat(maxCount) * (geometry.size.height - 40)
                            )
                        
                        // Hour label
                        Text("\(item.hour)")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
}

struct ResultBreakdownView: View {
    let data: [(result: BiteResult, count: Int)]
    
    var body: some View {
        let total = data.reduce(0) { $0 + $1.count }
        
        VStack(spacing: 12) {
            ForEach(data, id: \.result) { item in
                let percentage = total > 0 ? Double(item.count) / Double(total) : 0
                
                HStack(spacing: 16) {
                    Image(systemName: item.result.icon)
                        .font(.system(size: 20))
                        .foregroundColor(resultColor(for: item.result))
                        .frame(width: 30)
                    
                    Text(item.result.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 80, alignment: .leading)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.divider)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(resultColor(for: item.result))
                                .frame(width: geometry.size.width * CGFloat(percentage))
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(item.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func resultColor(for result: BiteResult) -> Color {
        switch result {
        case .caught: return AppColors.highActivity
        case .hooked: return AppColors.primaryAccent
        case .miss: return AppColors.lowActivity
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(AppColors.primaryAccent)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}
