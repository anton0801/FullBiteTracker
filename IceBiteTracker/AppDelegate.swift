import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

class TrackingHandler: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    private var handler: AttributionHandler
    
    init(handler: AttributionHandler) {
        self.handler = handler
    }
    
    func configure() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = AppConfig.devKey
        sdk.appleAppID = AppConfig.appID
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }
    
    func activate() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_value")
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "att_date")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        handler.receiveTracking(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        var data: [AnyHashable: Any] = [:]
        data["error"] = true
        data["error_detail"] = error.localizedDescription
        handler.receiveTracking(data)
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let deepLink = result.deepLink else { return }
        handler.receiveLinking(deepLink.clickEvent)
    }
}


class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    private let attribution = AttributionHandler()
    private let notification = NotificationHandler()
    private var tracking: TrackingHandler?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        attribution.onTracking = { [weak self] in self?.sendTracking($0) }
        attribution.onLinking = { [weak self] in self?.sendLinking($0) }
        tracking = TrackingHandler(handler: attribution)
        
        initFirebase()
        initNotifications()
        initTracking()
        
        if let push = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            notification.process(push: push)
        }
        
        setupObserver()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func initFirebase() {
        FirebaseApp.configure()
    }
    
    private func initNotifications() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func initTracking() {
        tracking?.configure()
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didActivate), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        notification.process(push: userInfo)
        completionHandler(.newData)
    }
    
    @objc private func didActivate() {
        tracking?.activate()
    }
    
    private func sendTracking(_ data: [AnyHashable: Any]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": data])
        }
    }
    
    private func sendLinking(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": data])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard error == nil, let token = token else { return }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            UserDefaults(suiteName: "group.bite.storage")?.set(token, forKey: "shared_fcm")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "fcm_date")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        self.notification.process(push: notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        notification.process(push: response.notification.request.content.userInfo)
        completionHandler()
    }
}

class NotificationHandler: NSObject {
    func process(push: [AnyHashable: Any]) {
        guard let url = extract(from: push) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "temp_url_date")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: Notification.Name("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extract(from payload: [AnyHashable: Any]) -> String? {
        if let url = payload["url"] as? String { return url }
        if let data = payload["data"] as? [String: Any], let url = data["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any], let data = aps["data"] as? [String: Any], let url = data["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any], let url = custom["url"] as? String { return url }
        return nil
    }
}
