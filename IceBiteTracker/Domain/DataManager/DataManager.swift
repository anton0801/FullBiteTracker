import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var sessions: [Session] = []
    @Published var currentSession: Session?
    @Published var goal: Goal = Goal()
    @Published var settings: AppSettings = AppSettings()
    
    private let sessionsKey = "sessions"
    private let goalKey = "goal"
    private let settingsKey = "settings"
    
    private init() {
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
        var csv = "Session,Date,Time,Strength,Result,Notes\n"
        
        for session in sessions {
            for bite in session.bites {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                
                csv += "\"\(session.name)\","
                csv += "\"\(formatter.string(from: session.date))\","
                csv += "\"\(bite.timeString)\","
                csv += "\"\(bite.strength.displayName)\","
                csv += "\"\(bite.result.displayName)\","
                csv += "\"\(bite.notes)\"\n"
            }
        }
        
        return csv
    }
    
    func exportToJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(sessions),
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
        
        saveSessions()
        saveGoal()
        
        setupCurrentSession()
    }
}
