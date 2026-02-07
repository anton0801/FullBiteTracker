import Foundation

struct AppSettings: Codable {
    var timeFormat: TimeFormat
    var biteStrengthScale: Int
    var defaultSessionLength: Int
    
    init(
        timeFormat: TimeFormat = .twentyFourHour,
        biteStrengthScale: Int = 3,
        defaultSessionLength: Int = 4
    ) {
        self.timeFormat = timeFormat
        self.biteStrengthScale = biteStrengthScale
        self.defaultSessionLength = defaultSessionLength
    }
    
    enum TimeFormat: String, Codable {
        case twelveHour = "12h"
        case twentyFourHour = "24h"
    }
}
