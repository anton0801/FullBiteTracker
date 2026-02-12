import SwiftUI

struct GearView: View {
    @StateObject private var viewModel = GearViewModel()
    @State private var showingAddGear = false
    @State private var selectedGearStats: GearStatistics?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.dataManager.fishingGear.isEmpty {
                    EmptyGearView {
                        showingAddGear = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Search Bar
                            SearchBar(text: $viewModel.searchText)
                                .padding(.horizontal)
                            
                            // Sort & Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Sort Menu
                                    Menu {
                                        ForEach(GearViewModel.SortOption.allCases, id: \.self) { option in
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.sortOption = option
                                                }
                                            }) {
                                                Label(option.rawValue, systemImage: option.icon)
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: viewModel.sortOption.icon)
                                            Text(viewModel.sortOption.rawValue)
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(AppColors.cardBackground)
                                        .cornerRadius(20)
                                    }
                                    
                                    // Category Filters
                                    Button(action: {
                                        withAnimation {
                                            viewModel.selectedCategory = nil
                                        }
                                    }) {
                                        Text("All")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(
                                                viewModel.selectedCategory == nil ?
                                                AppColors.textPrimary : AppColors.textSecondary
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedCategory == nil ?
                                                AppColors.primaryAccent.opacity(0.2) : AppColors.cardBackground
                                            )
                                            .cornerRadius(20)
                                    }
                                    
                                    ForEach(GearCategory.allCases, id: \.self) { category in
                                        Button(action: {
                                            withAnimation {
                                                viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: category.icon)
                                                Text(category.rawValue)
                                            }
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(
                                                viewModel.selectedCategory == category ?
                                                AppColors.textPrimary : AppColors.textSecondary
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedCategory == category ?
                                                AppColors.primaryAccent.opacity(0.2) : AppColors.cardBackground
                                            )
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Top Performers (если есть статистика)
                            if !viewModel.topPerformingGear.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(AppColors.primaryAccent)
                                        Text("Top Performers")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                    .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(viewModel.topPerformingGear, id: \.gear.id) { stats in
                                                TopPerformerCard(statistics: stats)
                                                    .onTapGesture {
                                                        selectedGearStats = stats
                                                    }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
                            }
                            
                            // Gear List
                            VStack(alignment: .leading, spacing: 12) {
                                Text("All Gear (\(viewModel.sortedGearStatistics.count))")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.sortedGearStatistics, id: \.gear.id) { stats in
                                        GearCard(statistics: stats, viewModel: viewModel)
                                            .onTapGesture {
                                                selectedGearStats = stats
                                            }
                                            .contextMenu {
                                                Button(action: {
                                                    viewModel.toggleFavorite(stats.gear)
                                                }) {
                                                    Label(
                                                        stats.gear.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                                        systemImage: stats.gear.isFavorite ? "star.slash" : "star.fill"
                                                    )
                                                }
                                                
                                                Button(action: {
                                                    viewModel.editingGear = stats.gear
                                                    showingAddGear = true
                                                }) {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                
                                                Button(role: .destructive, action: {
                                                    withAnimation {
                                                        viewModel.deleteGear(stats.gear)
                                                    }
                                                }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            viewModel.editingGear = nil
                            showingAddGear = true
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Fishing Gear")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddGear) {
                AddGearView(viewModel: viewModel, editingGear: viewModel.editingGear)
            }
            .sheet(item: $selectedGearStats) { stats in
                GearDetailView(gear: stats.gear, statistics: stats)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Search gear...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
}

struct TopPerformerCard: View {
    let statistics: GearStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: statistics.gear.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: statistics.gear.color))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", statistics.efficiencyScore))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.primaryAccent)
                    
                    Text("Score")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Text(statistics.gear.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(statistics.totalBites)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Uses")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(statistics.caughtCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.highActivity)
                    Text("Caught")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding()
        .frame(width: 200)
        .cardStyle()
    }
}

struct GearCard: View {
    let statistics: GearStatistics
    @ObservedObject var viewModel: GearViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: statistics.gear.color).opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: statistics.gear.category.icon)
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: statistics.gear.color))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(statistics.gear.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if statistics.gear.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.primaryAccent)
                    }
                }
                
                Text(statistics.gear.category.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: 12) {
                    StatBadge(
                        icon: "circle.grid.cross",
                        value: "\(statistics.totalBites)",
                        color: AppColors.textSecondary
                    )
                    
                    StatBadge(
                        icon: "checkmark.circle.fill",
                        value: "\(statistics.caughtCount)",
                        color: AppColors.highActivity
                    )
                    
                    StatBadge(
                        icon: "star.fill",
                        value: String(format: "%.1f", statistics.efficiencyScore),
                        color: AppColors.primaryAccent
                    )
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .cardStyle()
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(color)
    }
}

struct EmptyGearView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.primaryAccent.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.primaryAccent.opacity(0.5))
            }
            
            VStack(spacing: 12) {
                Text("No Fishing Gear Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Add your first lure, bait, or jig to start tracking performance")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            CustomButton(title: "Add First Gear", style: .primary, action: action)
                .padding(.horizontal, 60)
                .padding(.top, 8)
        }
    }
}

// Extension для использования GearStatistics как Identifiable
extension GearStatistics: Identifiable {
    var id: UUID { gear.id }
}
