import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var dataManager = DataManager.shared
    @Published var showingResetConfirmation = false
    
    var settings: AppSettings {
        dataManager.settings
    }
    
    func updateTimeFormat(_ format: AppSettings.TimeFormat) {
        dataManager.settings.timeFormat = format
        dataManager.saveSettings()
    }
    
    func updateStrengthScale(_ scale: Int) {
        dataManager.settings.biteStrengthScale = scale
        dataManager.saveSettings()
    }
    
    func updateDefaultSessionLength(_ length: Int) {
        dataManager.settings.defaultSessionLength = length
        dataManager.saveSettings()
    }
    
    func resetData() {
        dataManager.resetAllData()
    }
}
