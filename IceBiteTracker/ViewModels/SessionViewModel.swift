import Foundation
import Combine

class SessionViewModel: ObservableObject {
    @Published var dataManager = DataManager()
    @Published var selectedSession: Session?
    @Published var showingAddBite = false
    @Published var editingBite: Bite?
    
    var currentSessionBites: [Bite] {
        dataManager.currentSession?.bites.sorted { $0.timestamp < $1.timestamp } ?? []
    }
    
    func addBite(strength: BiteStrength, result: BiteResult, notes: String, timestamp: Date = Date(), gearId: UUID? = nil) {
        let bite = Bite(timestamp: timestamp, strength: strength, result: result, notes: notes, gearId: gearId)
        dataManager.addBite(bite)
    }
    
    func updateBite(_ bite: Bite) {
        dataManager.updateBite(bite)
    }
    
    func deleteBite(_ bite: Bite) {
        dataManager.deleteBite(bite)
    }
    
    func getBiteTimelineData() -> [(hour: Int, bites: [Bite])] {
        let grouped = Dictionary(grouping: currentSessionBites, by: { $0.hour })
        return grouped.map { (hour: $0.key, bites: $0.value) }
            .sorted { $0.hour < $1.hour }
    }
}
