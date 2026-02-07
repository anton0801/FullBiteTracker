import Foundation

struct Goal: Codable {
    var bitesPerSession: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastSessionDate: Date?
    
    init(
        bitesPerSession: Int = 10,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastSessionDate: Date? = nil
    ) {
        self.bitesPerSession = bitesPerSession
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastSessionDate = lastSessionDate
    }
    
    mutating func updateStreak(for date: Date) {
        if let lastDate = lastSessionDate {
            let calendar = Calendar.current
            let daysBetween = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0
            
            if daysBetween == 1 {
                currentStreak += 1
            } else if daysBetween > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        lastSessionDate = date
    }
}
