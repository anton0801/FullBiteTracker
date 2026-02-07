import SwiftUI

struct SessionDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let session: Session
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary tiles
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                SummaryTile(
                                    title: "Total Bites",
                                    value: "\(session.totalBites)",
                                    icon: "circle.grid.cross.fill"
                                )
                                
                                SummaryTile(
                                    title: "Caught",
                                    value: "\(session.caughtCount)",
                                    icon: "checkmark.circle.fill"
                                )
                            }
                            
                            HStack(spacing: 16) {
                                SummaryTile(
                                    title: "Peak Hour",
                                    value: session.peakHour.map { "\($0):00" } ?? "N/A",
                                    icon: "clock.fill"
                                )
                                
                                SummaryTile(
                                    title: "Avg Strength",
                                    value: String(format: "%.1f", session.averageStrength),
                                    icon: "chart.line.uptrend.xyaxis"
                                )
                            }
                        }
                        .padding()
                        
                        // Timeline
                        if !session.bites.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Timeline")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal)
                                
                                BiteTimelineView(bites: session.bites)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical)
                            .cardStyle()
                            .padding(.horizontal)
                        }
                        
                        // Bites list
                        if !session.bites.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("All Bites")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal)
                                
                                ForEach(session.bites.sorted { $0.timestamp < $1.timestamp }) { bite in
                                    BiteDetailRow(bite: bite)
                                }
                            }
                            .padding(.vertical)
                            .cardStyle()
                            .padding(.horizontal)
                        }
                        
                        // Tags
                        if !session.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tags")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(session.tags, id: \.self) { tag in
                                            TagChip(tag: tag)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                            .cardStyle()
                            .padding(.horizontal)
                        }
                        
                        // Notes
                        if !session.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(session.notes)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .cardStyle()
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(session.name)
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
}

struct SummaryTile: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(AppColors.primaryAccent)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

struct BiteDetailRow: View {
    let bite: Bite
    
    var body: some View {
        HStack(spacing: 16) {
            // Time
            VStack(alignment: .leading, spacing: 4) {
                Text(bite.timeString)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            // Strength
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: bite.strength.color))
                    .frame(width: 8, height: 8)
                Text(bite.strength.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Result
            HStack(spacing: 6) {
                Image(systemName: bite.result.icon)
                    .font(.system(size: 16))
                    .foregroundColor(bite.result == .caught ? AppColors.highActivity : AppColors.textSecondary)
                Text(bite.result.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
