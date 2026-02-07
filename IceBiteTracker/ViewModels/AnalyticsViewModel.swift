import Foundation
import Combine

class AnalyticsViewModel: ObservableObject {
    @Published var dataManager = DataManager.shared
    @Published var selectedTimeRange: TimeRange = .allTime
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }
    
    var filteredSessions: [Session] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return dataManager.sessions.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return dataManager.sessions.filter { $0.date >= monthAgo }
        case .allTime:
            return dataManager.sessions
        }
    }
    
    var hourlyActivity: [(hour: Int, count: Int)] {
        var hourlyData: [Int: Int] = [:]
        
        for session in filteredSessions {
            for (hour, count) in session.hourlyActivity {
                hourlyData[hour, default: 0] += count
            }
        }
        
        return hourlyData.map { (hour: $0.key, count: $0.value) }
            .sorted { $0.hour < $1.hour }
    }
    
    var resultBreakdown: [(result: BiteResult, count: Int)] {
        var breakdown: [BiteResult: Int] = [:]
        
        for session in filteredSessions {
            for bite in session.bites {
                breakdown[bite.result, default: 0] += 1
            }
        }
        
        return breakdown.map { (result: $0.key, count: $0.value) }
    }
    
    var averageStrength: Double {
        let allBites = filteredSessions.flatMap { $0.bites }
        guard !allBites.isEmpty else { return 0 }
        
        let sum = allBites.reduce(0.0) { $0 + Double($1.strength.rawValue) }
        return sum / Double(allBites.count)
    }
    
    var totalBites: Int {
        filteredSessions.reduce(0) { $0 + $1.totalBites }
    }
}
