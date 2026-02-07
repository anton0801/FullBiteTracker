import SwiftUI

struct SessionsListView: View {
    @StateObject private var viewModel = SessionViewModel()
    @State private var showingFilters = false
    @State private var selectedSession: Session?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.dataManager.sessions.isEmpty {
                    EmptySessionsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.dataManager.sessions) { session in
                                SessionCard(session: session)
                                    .onTapGesture {
                                        selectedSession = session
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(AppColors.primaryAccent)
                    }
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }
}

struct SessionCard: View {
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(Session.sessionDateFormatter.string(from: session.date))
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                if let peakHour = session.peakHour {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Peak")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(peakHour):00")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primaryAccent)
                    }
                }
            }
            
            // Stats
            HStack(spacing: 24) {
                StatItem(icon: "circle.grid.cross", value: "\(session.totalBites)", label: "Bites")
                StatItem(icon: "checkmark.circle.fill", value: "\(session.caughtCount)", label: "Caught")
                
                Spacer()
                
                // Mini activity indicator
                MiniActivityBar(hourlyActivity: session.hourlyActivity)
            }
            
            // Tags
            if !session.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(session.tags, id: \.self) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primaryAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

struct MiniActivityBar: View {
    let hourlyActivity: [Int: Int]
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(6..<18, id: \.self) { hour in
                let count = hourlyActivity[hour] ?? 0
                let maxCount = hourlyActivity.values.max() ?? 1
                let height = count > 0 ? CGFloat(count) / CGFloat(maxCount) * 30 : 2
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(count > 0 ? AppColors.primaryAccent : AppColors.divider)
                    .frame(width: 4, height: height)
            }
        }
        .frame(height: 30)
    }
}

struct TagChip: View {
    let tag: SessionTag
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tag.icon)
                .font(.system(size: 12))
            Text(tag.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(AppColors.primaryAccent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.primaryAccent.opacity(0.15))
        .cornerRadius(12)
    }
}

struct EmptySessionsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Sessions Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Start your first session")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}
