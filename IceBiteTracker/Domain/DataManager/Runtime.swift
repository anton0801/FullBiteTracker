import Foundation
import UIKit
import UserNotifications
import Network
import AppsFlyerLib
import FirebaseDatabase
import FirebaseCore
import FirebaseMessaging
import WebKit

@MainActor
final class Runtime {
    
    private let persistence: Persistence
    private let network: NetworkService
    
    private var timeoutTask: Task<Void, Never>?
    private let networkMonitor = NWPathMonitor()
    
    // Callback to send messages
    var sendMsg: ((Msg) -> Void)?
    
    init(persistence: Persistence = DiskPersistence(),
         network: NetworkService = HTTPNetwork()) {
        self.persistence = persistence
        self.network = network
    }
    
    // UNIQUE: Execute command
    func execute(_ cmd: Cmd) {
        switch cmd {
        case .none:
            break
            
        case .batch(let cmds):
            cmds.forEach { execute($0) }
            
        case .scheduleTimeout:
            scheduleTimeout()
            
        case .loadConfig:
            loadConfig()
            
        case .saveTracking(let data):
            persistence.saveTracking(data)
            
        case .saveLinking(let data):
            persistence.saveLinking(data)
            
        case .saveResource(let url):
            persistence.saveResource(url)
            
        case .saveMode(let mode):
            persistence.saveMode(mode)
            
        case .markFirstRunDone:
            persistence.markFirstRunDone()
            
        case .saveAlerts(let info):
            persistence.saveAlerts(info)
            
        case .validateFirebase:
            Task { await validateFirebase() }
            
        case .fetchTracking(let deviceID):
            Task { await fetchTracking(deviceID: deviceID) }
            
        case .fetchResource(let tracking):
            Task { await fetchResource(tracking: tracking) }
            
        case .requestPermission:
            requestPermission()
            
        case .registerForNotifications:
            UIApplication.shared.registerForRemoteNotifications()
            
        case .monitorNetwork:
            monitorNetwork()
            
        case .lockRuntime:
            lock()
        }
    }
    
    // MARK: - Command Implementations
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            await MainActor.run {
                self.sendMsg?(.timeout)
            }
        }
    }
    
    private func loadConfig() {
        let loaded = persistence.loadAll()
        
        let config = Msg.LoadedConfig(
            resource: loaded.resource,
            mode: loaded.mode,
            firstRun: loaded.firstRun,
            tracking: loaded.tracking,
            linking: loaded.linking,
            alerts: Msg.LoadedConfig.AlertConfig(
                accepted: loaded.alerts.accepted,
                rejected: loaded.alerts.rejected,
                requestedAt: loaded.alerts.requestedAt
            )
        )
        
        sendMsg?(.configLoaded(config))
    }
    
    private var isLocked = false
    
    func lock() {
        isLocked = true
        timeoutTask?.cancel()
    }
    
    private func validateFirebase() async {
        guard !isLocked else { return }
        
        sendMsg?(.validateRequested)
        
        do {
            let isValid = try await network.validateFirebase()
            
            if isValid {
                sendMsg?(.validateSucceeded)
            } else {
                sendMsg?(.validateFailed)
            }
        } catch {
            sendMsg?(.validateFailed)
        }
    }
    
    private func fetchTracking(deviceID: String) async {
        sendMsg?(.fetchTrackingRequested)
        
        // Wait 5 seconds for organic flow
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        do {
            let data = try await network.fetchTracking(deviceID: deviceID)
            sendMsg?(.fetchTrackingSucceeded(data))
        } catch {
            sendMsg?(.fetchTrackingFailed)
        }
    }
    
    private func fetchResource(tracking: [String: Any]) async {
        sendMsg?(.fetchResourceRequested)
        
        do {
            let resource = try await network.fetchResource(tracking: tracking)
            sendMsg?(.fetchResourceSucceeded(resource))
        } catch {
            sendMsg?(.fetchResourceFailed)
        }
    }
    
    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                if granted {
                    self?.sendMsg?(.alertPermissionGranted)
                } else {
                    self?.sendMsg?(.alertPermissionDenied)
                }
            }
        }
    }
    
    private func monitorNetwork() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                if path.status == .satisfied {
                    self?.sendMsg?(.networkConnected)
                } else {
                    self?.sendMsg?(.networkDisconnected)
                }
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
}

// MARK: - Persistence

protocol Persistence {
    func saveTracking(_ data: [String: String])
    func saveLinking(_ data: [String: String])
    func saveResource(_ url: String)
    func saveMode(_ mode: String)
    func markFirstRunDone()
    func saveAlerts(_ info: Model.AlertInfo)
    func loadAll() -> LoadedData
}

struct LoadedData {
    var resource: String?
    var mode: String?
    var firstRun: Bool
    var tracking: [String: String]
    var linking: [String: String]
    var alerts: AlertData
    
    struct AlertData {
        var accepted: Bool
        var rejected: Bool
        var requestedAt: Date?
    }
}

final class DiskPersistence: Persistence {
    
    private let disk = UserDefaults(suiteName: "group.bite.storage")!
    private let backup = UserDefaults.standard
    private var cache: [String: Any] = [:]
    
    // UNIQUE: fb_ prefix
    private enum Keys {
        static let tracking = "fb_tracking_info"
        static let linking = "fb_linking_info"
        static let resource = "fb_resource_url"
        static let mode = "fb_mode_setting"
        static let firstRun = "fb_first_run_done"
        static let alertAccepted = "fb_alert_accepted"
        static let alertRejected = "fb_alert_rejected"
        static let alertDate = "fb_alert_date"
    }
    
    init() {
        warmCache()
    }
    
    func saveTracking(_ data: [String: String]) {
        if let json = toJSON(data) {
            disk.set(json, forKey: Keys.tracking)
            cache[Keys.tracking] = json
        }
    }
    
    func saveLinking(_ data: [String: String]) {
        if let json = toJSON(data) {
            let encoded = encode(json)
            disk.set(encoded, forKey: Keys.linking)
        }
    }
    
    func saveResource(_ url: String) {
        disk.set(url, forKey: Keys.resource)
        backup.set(url, forKey: Keys.resource)
        cache[Keys.resource] = url
    }
    
    func saveMode(_ mode: String) {
        disk.set(mode, forKey: Keys.mode)
    }
    
    func markFirstRunDone() {
        disk.set(true, forKey: Keys.firstRun)
    }
    
    func saveAlerts(_ info: Model.AlertInfo) {
        disk.set(info.accepted, forKey: Keys.alertAccepted)
        disk.set(info.rejected, forKey: Keys.alertRejected)
        
        if let date = info.requestedAt {
            disk.set(date.timeIntervalSince1970 * 1000, forKey: Keys.alertDate)
        }
    }
    
    func loadAll() -> LoadedData {
        var tracking: [String: String] = [:]
        if let json = cache[Keys.tracking] as? String ?? disk.string(forKey: Keys.tracking),
           let data = fromJSON(json) {
            tracking = data
        }
        
        var linking: [String: String] = [:]
        if let encoded = disk.string(forKey: Keys.linking),
           let json = decode(encoded),
           let data = fromJSON(json) {
            linking = data
        }
        
        let resource = cache[Keys.resource] as? String 
                    ?? disk.string(forKey: Keys.resource) 
                    ?? backup.string(forKey: Keys.resource)
        
        let mode = disk.string(forKey: Keys.mode)
        let firstRun = !disk.bool(forKey: Keys.firstRun)
        
        let accepted = disk.bool(forKey: Keys.alertAccepted)
        let rejected = disk.bool(forKey: Keys.alertRejected)
        let ts = disk.double(forKey: Keys.alertDate)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        return LoadedData(
            resource: resource,
            mode: mode,
            firstRun: firstRun,
            tracking: tracking,
            linking: linking,
            alerts: LoadedData.AlertData(
                accepted: accepted,
                rejected: rejected,
                requestedAt: date
            )
        )
    }
    
    private func warmCache() {
        if let resource = disk.string(forKey: Keys.resource) {
            cache[Keys.resource] = resource
        }
    }
    
    private func toJSON(_ data: [String: String]) -> String? {
        let anyDict = data.mapValues { $0 as Any }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: anyDict),
              let string = String(data: jsonData, encoding: .utf8) else { return nil }
        return string
    }
    
    private func fromJSON(_ string: String) -> [String: String]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        
        var result: [String: String] = [:]
        for (key, value) in dict {
            result[key] = "\(value)"
        }
        return result
    }
    
    private func encode(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "[")
            .replacingOccurrences(of: "+", with: "]")
    }
    
    private func decode(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: "[", with: "=")
            .replacingOccurrences(of: "]", with: "+")
        
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}

// MARK: - Network Service

protocol NetworkService {
    func validateFirebase() async throws -> Bool
    func fetchTracking(deviceID: String) async throws -> [String: Any]
    func fetchResource(tracking: [String: Any]) async throws -> String
}

enum NetworkError: Error {
    case badURL
    case failed
    case decode
}

struct AppConfig {
    static let appID = "6758890855"
    static let devKey = "n4yKUrUw2c7gg6vyDY6o85"
    static let e = "https://fullbitetracker.com/config.php"
}
