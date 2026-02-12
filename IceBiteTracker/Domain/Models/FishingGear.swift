import Foundation

struct FishingGear: Codable, Identifiable {
    let id: UUID
    var name: String
    var category: GearCategory
    var color: String
    var notes: String
    var dateAdded: Date
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        category: GearCategory,
        color: String = "4FC3F7",
        notes: String = "",
        dateAdded: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.color = color
        self.notes = notes
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
    }
}

enum GearCategory: String, Codable, CaseIterable {
    case lure = "Lure"
    case bait = "Bait"
    case jig = "Jig"
    case spoon = "Spoon"
    case fly = "Fly"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .lure: return "point.topleft.down.curvedto.point.bottomright.up"
        case .bait: return "circle.fill"
        case .jig: return "triangle.fill"
        case .spoon: return "oval.fill"
        case .fly: return "figure.walk"
        case .other: return "square.fill"
        }
    }
    
    var displayColor: String {
        switch self {
        case .lure: return "4FC3F7"
        case .bait: return "6FE3C1"
        case .jig: return "FF8A8A"
        case .spoon: return "FFD93D"
        case .fly: return "B388FF"
        case .other: return "9CB6C9"
        }
    }
}

// Статистика по снасти
struct GearStatistics {
    let gear: FishingGear
    let totalBites: Int
    let caughtCount: Int
    let missCount: Int
    let hookedCount: Int
    let successRate: Double
    let averageStrength: Double
    let lastUsed: Date?
    let bestHour: Int?
    
    var efficiencyScore: Double {
        // Формула эффективности: (caught * 3 + hooked * 1.5) / totalBites
        guard totalBites > 0 else { return 0 }
        return (Double(caughtCount) * 3.0 + Double(hookedCount) * 1.5) / Double(totalBites)
    }
}
