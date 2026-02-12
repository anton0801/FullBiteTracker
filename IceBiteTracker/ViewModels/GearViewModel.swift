import Foundation
import Combine

class GearViewModel: ObservableObject {
    @Published var dataManager = DataManager.shared
    @Published var selectedGear: FishingGear?
    @Published var showingAddGear = false
    @Published var editingGear: FishingGear?
    @Published var searchText = ""
    @Published var selectedCategory: GearCategory?
    @Published var sortOption: SortOption = .efficiency
    
    enum SortOption: String, CaseIterable {
        case efficiency = "Efficiency"
        case name = "Name"
        case recent = "Recent"
        case usage = "Usage"
        
        var icon: String {
            switch self {
            case .efficiency: return "star.fill"
            case .name: return "textformat.abc"
            case .recent: return "clock.fill"
            case .usage: return "chart.bar.fill"
            }
        }
    }
    
    var filteredGear: [FishingGear] {
        var gear = dataManager.fishingGear
        
        // Filter by search
        if !searchText.isEmpty {
            gear = gear.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by category
        if let category = selectedCategory {
            gear = gear.filter { $0.category == category }
        }
        
        return gear
    }
    
    var sortedGearStatistics: [GearStatistics] {
        let stats = filteredGear.map { dataManager.getGearStatistics(for: $0) }
        
        switch sortOption {
        case .efficiency:
            return stats.sorted { $0.efficiencyScore > $1.efficiencyScore }
        case .name:
            return stats.sorted { $0.gear.name < $1.gear.name }
        case .recent:
            return stats.sorted { ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast) }
        case .usage:
            return stats.sorted { $0.totalBites > $1.totalBites }
        }
    }
    
    var favoriteGear: [FishingGear] {
        dataManager.fishingGear.filter { $0.isFavorite }
    }
    
    var topPerformingGear: [GearStatistics] {
        dataManager.getAllGearStatistics()
            .filter { $0.totalBites >= 3 } // Минимум 3 использования
            .prefix(5)
            .map { $0 }
    }
    
    func addGear(name: String, category: GearCategory, color: String, notes: String) {
        let gear = FishingGear(name: name, category: category, color: color, notes: notes)
        dataManager.addGear(gear)
    }
    
    func updateGear(_ gear: FishingGear) {
        dataManager.updateGear(gear)
    }
    
    func deleteGear(_ gear: FishingGear) {
        dataManager.deleteGear(gear)
    }
    
    func toggleFavorite(_ gear: FishingGear) {
        dataManager.toggleFavoriteGear(gear)
    }
}
