import Foundation

struct Session: Codable, Identifiable {
    let id: UUID
    var name: String
    var date: Date
    var bites: [Bite]
    var tags: [SessionTag]
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        date: Date = Date(),
        bites: [Bite] = [],
        tags: [SessionTag] = [],
        notes: String = ""
    ) {
        self.id = id
        self.name = name.isEmpty ? "Session \(Self.sessionDateFormatter.string(from: date))" : name
        self.date = date
        self.bites = bites
        self.tags = tags
        self.notes = notes
    }
    
    var totalBites: Int {
        bites.count
    }
    
    var caughtCount: Int {
        bites.filter { $0.result == .caught }.count
    }
    
    var peakHour: Int? {
        let hourCounts = Dictionary(grouping: bites, by: { $0.hour })
            .mapValues { $0.count }
        return hourCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var averageStrength: Double {
        guard !bites.isEmpty else { return 0 }
        let sum = bites.reduce(0) { $0 + $1.strength.rawValue }
        return Double(sum) / Double(bites.count)
    }
    
    var hourlyActivity: [Int: Int] {
        Dictionary(grouping: bites, by: { $0.hour })
            .mapValues { $0.count }
    }
    
    static let sessionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

enum SessionTag: String, Codable, CaseIterable {
    case morning = "Morning"
    case evening = "Evening"
    case windy = "Windy"
    case calm = "Calm"
    case sunny = "Sunny"
    case cloudy = "Cloudy"
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .evening: return "sunset.fill"
        case .windy: return "wind"
        case .calm: return "water.waves"
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        }
    }
}
