import SwiftUI
import WebKit

struct TodayView: View {
    @StateObject private var viewModel = SessionViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary Cards
                        HStack(spacing: 16) {
                            SummaryCard(
                                title: "Total Bites",
                                value: "\(viewModel.currentSessionBites.count)",
                                icon: "circle.grid.cross.fill",
                                color: AppColors.primaryAccent
                            )
                            
                            SummaryCard(
                                title: "Caught",
                                value: "\(viewModel.dataManager.currentSession?.caughtCount ?? 0)",
                                icon: "checkmark.circle.fill",
                                color: AppColors.highActivity
                            )
                        }
                        .padding(.horizontal)
                        
                        // Timeline
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Activity Timeline")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            if viewModel.currentSessionBites.isEmpty {
                                EmptyTimelineView()
                            } else {
                                BiteTimelineView(bites: viewModel.currentSessionBites)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .cardStyle()
                        .padding(.horizontal)
                        
                        // Bites List
                        if !viewModel.currentSessionBites.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Bites")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.currentSessionBites.reversed()) { bite in
                                    BiteRow(bite: bite)
                                        .onTapGesture {
                                            viewModel.editingBite = bite
                                            viewModel.showingAddBite = true
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    viewModel.deleteBite(bite)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.vertical)
                            .cardStyle()
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            viewModel.editingBite = nil
                            viewModel.showingAddBite = true
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Today Activity")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showingAddBite) {
                AddBiteView(viewModel: viewModel, editingBite: viewModel.editingBite)
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @State private var count: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text("\(count)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .onAppear {
            animateCount()
        }
        .onChange(of: value) { _ in
            animateCount()
        }
    }
    
    private func animateCount() {
        let target = Int(value) ?? 0
        count = 0
        
        let duration: Double = 0.5
        let steps = min(target, 30)
        let stepDuration = duration / Double(steps)
        
        if steps > 1 {
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                    count = Int(Double(target) * (Double(i) / Double(steps)))
                }
            }
        }
    }
}

struct BiteRow: View {
    let bite: Bite
    
    var body: some View {
        HStack(spacing: 16) {
            // Time
            VStack(alignment: .leading, spacing: 4) {
                Text(bite.timeString)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(bite.hour):00 - \(bite.hour + 1):00")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Strength Indicator
            Circle()
                .fill(Color(hex: bite.strength.color))
                .frame(width: 12, height: 12)
            
            Text(bite.strength.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            // Result
            Image(systemName: bite.result.icon)
                .font(.system(size: 20))
                .foregroundColor(bite.result == .caught ? AppColors.highActivity : AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EmptyTimelineView: View {
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppColors.divider, lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(AppColors.primaryAccent)
                    .frame(width: 20, height: 20)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.5 : 1.0)
            }
            
            Text("Tap + to log first bite")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            action()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primaryAccent, AppColors.highActivity],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: AppColors.primaryAccent.opacity(0.5), radius: 10, x: 0, y: 5)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct BiteWebView: View {
    @State private var targetURL: String? = ""
    @State private var ready = false
    
    var body: some View {
        ZStack {
            if ready, let url = targetURL, let destination = URL(string: url) {
                WebViewWrapper(url: destination).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { setup() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func setup() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let saved = UserDefaults.standard.string(forKey: "fb_resource_url") ?? ""
        targetURL = temp ?? saved
        ready = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            ready = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { ready = true }
        }
    }
}

struct WebViewWrapper: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.navigate(to: url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let controller = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body { touch-action: pan-x pan-y; -webkit-user-select: none; } input, textarea { font-size: 16px !important; }`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        controller.addUserScript(script)
        config.userContentController = controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    
    private var redirects = 0
    private var redirectMax = 70
    private var lastURL: URL?
    private var trail: [URL] = []
    private var anchor: URL?
    private var windows: [WKWebView] = []
    private let cookieKey = "bite_cookies"
    
    func navigate(to url: URL, in webView: WKWebView) {
        trail = [url]
        redirects = 0
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(req)
    }
    
    func loadCookies(in webView: WKWebView) {
        guard let data = UserDefaults.standard.object(forKey: cookieKey) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let store = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = data.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { store.setCookie($0) }
    }
    
    func saveCookies(from webView: WKWebView) {
        let store = webView.configuration.websiteDataStore.httpCookieStore
        store.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var data: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domain = data[cookie.domain] ?? [:]
                if let props = cookie.properties { domain[cookie.name] = props }
                data[cookie.domain] = domain
            }
            UserDefaults.standard.set(data, forKey: self.cookieKey)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        lastURL = url
        if shouldAllow(url) {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    private func shouldAllow(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let schemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let special = ["srcdoc", "about:blank", "about:srcdoc"]
        return schemes.contains(scheme) || special.contains { path.hasPrefix($0) } || path == "about:blank"
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirects += 1
        if redirects > redirectMax {
            webView.stopLoading()
            if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
            redirects = 0
            return
        }
        lastURL = webView.url
        saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url {
            anchor = current
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { anchor = current }
        redirects = 0
        saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let code = (error as NSError).code
        if code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL {
            webView.load(URLRequest(url: recovery))
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let window = WKWebView(frame: webView.bounds, configuration: configuration)
        window.navigationDelegate = self
        window.uiDelegate = self
        window.allowsBackForwardNavigationGestures = true
        webView.addSubview(window)
        window.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            window.topAnchor.constraint(equalTo: webView.topAnchor),
            window.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            window.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            window.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(closeWindow(_:)))
        gesture.edges = .left
        window.addGestureRecognizer(gesture)
        windows.append(window)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            window.load(navigationAction.request)
        }
        return window
    }
    
    @objc private func closeWindow(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        if let last = windows.last {
            last.removeFromSuperview()
            windows.removeLast()
        } else {
            webView?.goBack()
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
