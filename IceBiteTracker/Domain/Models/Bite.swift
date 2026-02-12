import Foundation

struct Bite: Codable, Identifiable {
    let id: UUID
    var timestamp: Date
    var strength: BiteStrength
    var result: BiteResult
    var notes: String
    var gearId: UUID?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        strength: BiteStrength,
        result: BiteResult,
        notes: String = "",
        gearId: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.strength = strength
        self.result = result
        self.notes = notes
        self.gearId = gearId
    }
    
    var hour: Int {
        Calendar.current.component(.hour, from: timestamp)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

enum BiteStrength: Int, Codable, CaseIterable {
    case weak = 1
    case medium = 2
    case strong = 3
    
    var displayName: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
    
    var color: String {
        switch self {
        case .weak: return "FF8A8A"
        case .medium: return "4FC3F7"
        case .strong: return "6FE3C1"
        }
    }
}

enum BiteResult: String, Codable, CaseIterable {
    case miss = "miss"
    case hooked = "hooked"
    case caught = "caught"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .miss: return "xmark.circle"
        case .hooked: return "circle.dotted"
        case .caught: return "checkmark.circle.fill"
        }
    }
}
