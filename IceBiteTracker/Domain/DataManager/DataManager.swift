import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var sessions: [Session] = []
    @Published var currentSession: Session?
    @Published var goal: Goal = Goal()
    @Published var settings: AppSettings = AppSettings()
    @Published var fishingGear: [FishingGear] = [] // NEW
    
    private let sessionsKey = "sessions"
    private let goalKey = "goal"
    private let settingsKey = "settings"
    private let gearKey = "fishingGear" // NEW
    
    init() {
        loadData()
        setupCurrentSession()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        // Load sessions
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([Session].self, from: data) {
            sessions = decoded.sorted { $0.date > $1.date }
        }
        
        // Load goal
        if let data = UserDefaults.standard.data(forKey: goalKey),
           let decoded = try? JSONDecoder().decode(Goal.self, from: data) {
            goal = decoded
        }
        
        // Load settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
        
        // Load fishing gear (NEW)
        if let data = UserDefaults.standard.data(forKey: gearKey),
           let decoded = try? JSONDecoder().decode([FishingGear].self, from: data) {
            fishingGear = decoded.sorted { $0.dateAdded > $1.dateAdded }
        }
    }
    
    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    func saveGoal() {
        if let encoded = try? JSONEncoder().encode(goal) {
            UserDefaults.standard.set(encoded, forKey: goalKey)
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    // NEW - Save fishing gear
    func saveGear() {
        if let encoded = try? JSONEncoder().encode(fishingGear) {
            UserDefaults.standard.set(encoded, forKey: gearKey)
        }
    }
    
    // MARK: - Current Session
    
    private func setupCurrentSession() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existing = sessions.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            currentSession = existing
        } else {
            let newSession = Session(date: today)
            currentSession = newSession
            sessions.insert(newSession, at: 0)
            saveSessions()
        }
    }
    
    // MARK: - Session Management
    
    func addBite(_ bite: Bite) {
        guard var session = currentSession else { return }
        session.bites.append(bite)
        updateSession(session)
        
        goal.updateStreak(for: session.date)
        saveGoal()
    }
    
    func updateBite(_ bite: Bite) {
        guard var session = currentSession,
              let index = session.bites.firstIndex(where: { $0.id == bite.id }) else { return }
        session.bites[index] = bite
        updateSession(session)
    }
    
    func deleteBite(_ bite: Bite) {
        guard var session = currentSession,
              let index = session.bites.firstIndex(where: { $0.id == bite.id }) else { return }
        session.bites.remove(at: index)
        updateSession(session)
    }
    
    func updateSession(_ session: Session) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            if session.id == currentSession?.id {
                currentSession = session
            }
            saveSessions()
        }
    }
    
    func deleteSession(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
        if session.id == currentSession?.id {
            setupCurrentSession()
        }
        saveSessions()
    }
    
    func createNewSession(name: String = "", date: Date = Date()) -> Session {
        let session = Session(name: name, date: date)
        sessions.insert(session, at: 0)
        sessions.sort { $0.date > $1.date }
        saveSessions()
        return session
    }
    
    // MARK: - Fishing Gear Management (NEW)
    
    func addGear(_ gear: FishingGear) {
        fishingGear.append(gear)
        fishingGear.sort { $0.dateAdded > $1.dateAdded }
        saveGear()
    }
    
    func updateGear(_ gear: FishingGear) {
        if let index = fishingGear.firstIndex(where: { $0.id == gear.id }) {
            fishingGear[index] = gear
            saveGear()
        }
    }
    
    func deleteGear(_ gear: FishingGear) {
        fishingGear.removeAll { $0.id == gear.id }
        
        // Удаляем привязку из всех поклёвок
        for i in 0..<sessions.count {
            for j in 0..<sessions[i].bites.count {
                if sessions[i].bites[j].gearId == gear.id {
                    sessions[i].bites[j].gearId = nil
                }
            }
        }
        
        saveGear()
        saveSessions()
    }
    
    func toggleFavoriteGear(_ gear: FishingGear) {
        var updatedGear = gear
        updatedGear.isFavorite.toggle()
        updateGear(updatedGear)
    }
    
    func getGear(by id: UUID) -> FishingGear? {
        fishingGear.first { $0.id == id }
    }
    
    // MARK: - Gear Statistics (NEW)
    
    func getGearStatistics(for gear: FishingGear) -> GearStatistics {
        var totalBites = 0
        var caughtCount = 0
        var missCount = 0
        var hookedCount = 0
        var strengthSum = 0.0
        var lastUsed: Date?
        var hourCounts: [Int: Int] = [:]
        
        for session in sessions {
            for bite in session.bites where bite.gearId == gear.id {
                totalBites += 1
                strengthSum += Double(bite.strength.rawValue)
                
                switch bite.result {
                case .caught: caughtCount += 1
                case .hooked: hookedCount += 1
                case .miss: missCount += 1
                }
                
                if lastUsed == nil || bite.timestamp > lastUsed! {
                    lastUsed = bite.timestamp
                }
                
                hourCounts[bite.hour, default: 0] += 1
            }
        }
        
        let successRate = totalBites > 0 ? Double(caughtCount) / Double(totalBites) * 100 : 0
        let averageStrength = totalBites > 0 ? strengthSum / Double(totalBites) : 0
        let bestHour = hourCounts.max(by: { $0.value < $1.value })?.key
        
        return GearStatistics(
            gear: gear,
            totalBites: totalBites,
            caughtCount: caughtCount,
            missCount: missCount,
            hookedCount: hookedCount,
            successRate: successRate,
            averageStrength: averageStrength,
            lastUsed: lastUsed,
            bestHour: bestHour
        )
    }
    
    func getAllGearStatistics() -> [GearStatistics] {
        fishingGear.map { getGearStatistics(for: $0) }
            .sorted { $0.efficiencyScore > $1.efficiencyScore }
    }
    
    // MARK: - Analytics
    
    func getHourlyActivity() -> [Int: Int] {
        var hourlyData: [Int: Int] = [:]
        
        for session in sessions {
            for (hour, count) in session.hourlyActivity {
                hourlyData[hour, default: 0] += count
            }
        }
        
        return hourlyData
    }
    
    func getResultBreakdown() -> [BiteResult: Int] {
        var breakdown: [BiteResult: Int] = [:]
        
        for session in sessions {
            for bite in session.bites {
                breakdown[bite.result, default: 0] += 1
            }
        }
        
        return breakdown
    }
    
    func getAverageBitesPerHour() -> Double {
        let totalBites = sessions.reduce(0) { $0 + $1.totalBites }
        let totalSessions = sessions.count
        guard totalSessions > 0 else { return 0 }
        
        return Double(totalBites) / Double(totalSessions * settings.defaultSessionLength)
    }
    
    func getBestHourRange() -> (Int, Int)? {
        let hourlyActivity = getHourlyActivity()
        guard !hourlyActivity.isEmpty else { return nil }
        
        let sortedHours = hourlyActivity.sorted { $0.value > $1.value }
        if let bestHour = sortedHours.first?.key {
            return (bestHour, bestHour + 1)
        }
        
        return nil
    }
    
    // MARK: - Export
    
    func exportToCSV() -> String {
        var csv = "Session,Date,Time,Strength,Result,Gear,Notes\n"
        
        for session in sessions {
            for bite in session.bites {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                
                let gearName = bite.gearId.flatMap { getGear(by: $0)?.name } ?? "None"
                
                csv += "\"\(session.name)\","
                csv += "\"\(formatter.string(from: session.date))\","
                csv += "\"\(bite.timeString)\","
                csv += "\"\(bite.strength.displayName)\","
                csv += "\"\(bite.result.displayName)\","
                csv += "\"\(gearName)\","
                csv += "\"\(bite.notes)\"\n"
            }
        }
        
        return csv
    }
    
    func exportToJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData: [String: Any] = [
            "sessions": sessions,
            "gear": fishingGear
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: exportData),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        
        return nil
    }
    
    // MARK: - Reset
    
    func resetAllData() {
        sessions = []
        currentSession = nil
        goal = Goal()
        fishingGear = [] // NEW
        
        saveSessions()
        saveGoal()
        saveGear() // NEW
        
        setupCurrentSession()
    }
}
