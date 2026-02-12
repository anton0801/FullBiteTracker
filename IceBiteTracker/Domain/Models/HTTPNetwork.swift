import AppsFlyerLib
import Foundation
import Firebase
import FirebaseMessaging
import WebKit

final class HTTPNetwork: NetworkService {
    
    private let client: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        
        self.client = URLSession(configuration: config)
    }
    
    func validateFirebase() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child("users/log/data")
                .observeSingleEvent(of: .value) { snapshot in
                    if let url = snapshot.value as? String,
                       !url.isEmpty,
                       URL(string: url) != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func fetchTracking(deviceID: String) async throws -> [String: Any] {
        let base = "https://gcdsdk.appsflyer.com/install_data/v4.0"
        let app = "id\(AppConfig.appID)"
        
        var builder = URLComponents(string: "\(base)/\(app)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: AppConfig.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = builder?.url else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await client.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.failed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkError.decode
        }
        
        return json
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchResource(tracking: [String: Any]) async throws -> String {
        guard let url = URL(string: AppConfig.e) else {
            throw NetworkError.badURL
        }
        
        var payload: [String: Any] = tracking
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(AppConfig.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        let retries: [Double] = [7.0, 14.0, 28.0]
        
        for (index, delay) in retries.enumerated() {
            do {
                let (data, response) = try await client.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.failed
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let success = json["ok"] as? Bool,
                          success,
                          let resource = json["url"] as? String else {
                        throw NetworkError.decode
                    }
                    
                    return resource
                } else if httpResponse.statusCode == 429 {
                    let backoff = delay * Double(index + 1)
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    throw NetworkError.failed
                }
            } catch {
                lastError = error
                if index < retries.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.failed
    }
}
