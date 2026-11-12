import UIKit
import WebKit

/// Haupt-Bildschirm mit WebView zur Steuerung des Zutrittssystems (äquivalent zu MainActivity).
final class MainViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, SettingsViewControllerDelegate {
    
    private let prefs = AppPreferences.shared
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var errorContainer: UIView!
    private var tvErrorMessage: UILabel!
    private var awaitingOpenResult: Bool = false
    
    // MARK: - Scripts
    
    private let hookScript = """
    (function() {
        var f = document.querySelector("form[action='/open']");
        if (f && !f.__zutrittHooked) {
            f.__zutrittHooked = true;
            f.addEventListener('submit', function() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ZutrittBridge) {
                    window.webkit.messageHandlers.ZutrittBridge.postMessage({action: 'onOpenSubmitted'});
                }
            });
        }
    })();
    """
    
    private let autofillScript = """
    (function() {
        var u = document.querySelector("input[name='username']");
        var p = document.querySelector("input[name='password']");
        var f = (u && u.form) || (p && p.form) || document.querySelector("form[action='/login']");
        if (u) {
            u.setAttribute('autocomplete', 'username');
            u.setAttribute('autofill', 'username');
            if (!u.id) u.id = 'username';
        }
        if (p) {
            p.setAttribute('autocomplete', 'current-password');
            p.setAttribute('autofill', 'current-password');
            if (!p.id) p.id = 'password';
        }
        if (f && !f.__autofillHooked) {
            f.__autofillHooked = true;
            f.addEventListener('submit', function() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ZutrittBridge) {
                    window.webkit.messageHandlers.ZutrittBridge.postMessage({action: 'onLoginSubmitted'});
                }
            });
        }
    })();
    """
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Zutritt"
        view.backgroundColor = .appBackground
        
        setupNavigationBar()
        setupWebView()
        setupProgressBar()
        setupErrorView()
        
        loadDeviceUrl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // KVO für Ladebalken
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    // MARK: - Navigation Bar
    
    private func setupNavigationBar() {
        let reloadItem: UIBarButtonItem
        let settingsItem: UIBarButtonItem
        
        if #available(iOS 13.0, *) {
            reloadItem = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(reloadTapped)
            )
            settingsItem = UIBarButtonItem(
                image: UIImage(systemName: "gearshape"),
                style: .plain,
                target: self,
                action: #selector(settingsTapped)
            )
        } else {
            reloadItem = UIBarButtonItem(
                title: "Neu laden",
                style: .plain,
                target: self,
                action: #selector(reloadTapped)
            )
            settingsItem = UIBarButtonItem(
                title: "⚙",
                style: .plain,
                target: self,
                action: #selector(settingsTapped)
            )
        }
        
        navigationItem.leftBarButtonItem = reloadItem
        navigationItem.rightBarButtonItem = settingsItem
    }
    
    // MARK: - UI Setup
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        // Registriere JavaScript-Bridge "ZutrittBridge"
        contentController.add(self, name: "ZutrittBridge")
        
        // Injiziere Scripts bei Dokumentende
        let openScriptObj = WKUserScript(source: hookScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        let autoFillScriptObj = WKUserScript(source: autofillScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        contentController.addUserScript(openScriptObj)
        contentController.addUserScript(autoFillScriptObj)
        
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupProgressBar() {
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .appPrimaryTint
        progressView.trackTintColor = .clear
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.5)
        ])
    }
    
    private func setupErrorView() {
        errorContainer = UIView()
        errorContainer.backgroundColor = .appBackground
        errorContainer.translatesAutoresizingMaskIntoConstraints = false
        errorContainer.isHidden = true
        view.addSubview(errorContainer)
        
        NSLayoutConstraint.activate([
            errorContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            errorContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let iconLabel = UILabel()
        iconLabel.text = "⚠️"
        iconLabel.font = UIFont.systemFont(ofSize: 56)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Keine Verbindung zum Zutrittssystem"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .appLabel
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tvErrorMessage = UILabel()
        tvErrorMessage.font = UIFont.systemFont(ofSize: 15)
        tvErrorMessage.textColor = .appSecondaryLabel
        tvErrorMessage.textAlignment = .center
        tvErrorMessage.numberOfLines = 0
        tvErrorMessage.translatesAutoresizingMaskIntoConstraints = false
        
        let btnRetry = UIButton(type: .system)
        btnRetry.setTitle("Erneut versuchen", for: .normal)
        btnRetry.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btnRetry.backgroundColor = .appPrimaryTint
        btnRetry.setTitleColor(.white, for: .normal)
        btnRetry.layer.cornerRadius = 8
        btnRetry.translatesAutoresizingMaskIntoConstraints = false
        btnRetry.addTarget(self, action: #selector(reloadTapped), for: .touchUpInside)
        
        let btnOpenWifi = UIButton(type: .system)
        btnOpenWifi.setTitle("WLAN-Einstellungen öffnen", for: .normal)
        btnOpenWifi.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btnOpenWifi.backgroundColor = .appSecondaryBackground
        btnOpenWifi.layer.cornerRadius = 8
        btnOpenWifi.layer.borderWidth = 1
        btnOpenWifi.layer.borderColor = UIColor.appSeparator.cgColor
        btnOpenWifi.translatesAutoresizingMaskIntoConstraints = false
        btnOpenWifi.addTarget(self, action: #selector(openWifiSettings), for: .touchUpInside)
        
        let btnSettings = UIButton(type: .system)
        btnSettings.setTitle("Einstellungen anpassen", for: .normal)
        btnSettings.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btnSettings.translatesAutoresizingMaskIntoConstraints = false
        btnSettings.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [iconLabel, titleLabel, tvErrorMessage, btnRetry, btnOpenWifi, btnSettings])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        stack.setCustomSpacing(24, after: tvErrorMessage)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        errorContainer.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: errorContainer.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor, constant: -28),
            btnRetry.heightAnchor.constraint(equalToConstant: 46),
            btnOpenWifi.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Logic & Actions
    
    func loadDeviceUrl() {
        hideErrorScreen()
        let urlStr = prefs.deviceUrl
        guard let url = URL(string: urlStr) else {
            showErrorScreen()
            return
        }
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        webView.load(request)
    }
    
    private func showErrorScreen() {
        let msg = "Das Zutrittssystem kann unter der Adresse\n\(prefs.deviceUrl)\nnicht erreicht werden.\n\nBitte stelle sicher, dass dein Smartphone mit dem WLAN „AP-ESP32“ oder deinem Heimnetzwerk verbunden ist."
        tvErrorMessage.text = msg
        webView.isHidden = true
        errorContainer.isHidden = false
    }
    
    private func hideErrorScreen() {
        errorContainer.isHidden = true
        webView.isHidden = false
    }
    
    @objc private func reloadTapped() {
        loadDeviceUrl()
    }
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        settingsVC.delegate = self
        let nav = UINavigationController(rootViewController: settingsVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
    
    @objc private func openWifiSettings() {
        // Versuche WLAN-Einstellungen bzw. App-Einstellungen zu öffnen
        if let wifiUrl = URL(string: "App-Prefs:root=WIFI"), UIApplication.shared.canOpenURL(wifiUrl) {
            UIApplication.shared.open(wifiUrl, options: [:], completionHandler: nil)
        } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }
    
    func didUpdateSettings(urlChanged: Bool) {
        if urlChanged {
            loadDeviceUrl()
        }
    }
    
    // MARK: - KVO Progress
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1.0
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.isHidden = true
        hideErrorScreen()
        
        // Auto-Login prüfen
        checkAndPerformAutoLogin()
        
        // Prüfe ob Tor geöffnet wurde
        checkForGifTrigger()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        showErrorScreen()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        showErrorScreen()
    }
    
    // Download handling für Log-Dateien (z. B. CSV)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        let pathLower = url.path.lowercased()
        if pathLower.hasSuffix(".csv") || pathLower.contains("/log") {
            decisionHandler(.cancel)
            downloadFile(from: url)
            return
        }
        
        decisionHandler(.allow)
    }
    
    private func downloadFile(from url: URL) {
        ToastView.show(message: "Log-Datei wird heruntergeladen…", in: view)
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    ToastView.show(message: "Fehler beim Herunterladen: \(error.localizedDescription)", in: self.view)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode), let data = data else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    ToastView.show(message: "Fehler beim Herunterladen (HTTP \(code))", in: self.view)
                    return
                }
                
                // Speichere in temporäre Datei und zeige Share/Save Sheet
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                do {
                    try data.write(to: tempURL)
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = self.view
                        popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    }
                    self.present(activityVC, animated: true) {
                        ToastView.show(message: "Log-Datei erfolgreich gespeichert!", in: self.view)
                    }
                } catch {
                    ToastView.show(message: "Fehler beim Speichern: \(error.localizedDescription)", in: self.view)
                }
            }
        }.resume()
    }
    
    // MARK: - Auto-Login & Trigger Detection
    
    private func checkAndPerformAutoLogin() {
        guard prefs.isAutoLoginEnabled else { return }
        guard let currentUrl = webView.url?.absoluteString, currentUrl.contains("/login") else { return }
        
        let escapedUser = prefs.autoLoginUser.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
        let escapedPass = prefs.autoLoginPass.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
        
        let script = """
        (function() {
            var u = document.querySelector("input[name='username']");
            var p = document.querySelector("input[name='password']");
            var f = (u && u.form) || (p && p.form) || document.querySelector("form[action='/login']");
            if (u && p && f && !f.__autoSubmitted) {
                f.__autoSubmitted = true;
                u.value = '\(escapedUser)';
                p.value = '\(escapedPass)';
                f.submit();
            }
        })();
        """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func checkForGifTrigger() {
        let script = "(function(){ return document.body ? document.body.innerText : ''; })();"
        webView.evaluateJavaScript(script) { [weak self] (result, _) in
            guard let self = self, let text = result as? String else { return }
            
            let keyword = self.prefs.successKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !keyword.isEmpty else { return }
            
            if text.localizedCaseInsensitiveContains(keyword) {
                self.showGifOverlay()
            }
        }
    }
    
    private func showGifOverlay() {
        guard prefs.isGifEnabled else { return }
        
        guard let gifData = prefs.loadGifData() else {
            ToastView.show(message: "Tor geöffnet - aber es ist noch keine GIF-Datei in den Einstellungen hinterlegt.", in: view)
            return
        }
        
        let overlayVC = GifOverlayViewController(gifData: gifData, durationSeconds: prefs.gifDurationSeconds)
        present(overlayVC, animated: true, completion: nil)
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "ZutrittBridge", let dict = message.body as? [String: Any], let action = dict["action"] as? String else {
            return
        }
        
        if action == "onOpenSubmitted" {
            awaitingOpenResult = true
            // Prüfe nach kurzer Verzögerung nochmals auf Erfolgsmeldung
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.checkForGifTrigger()
            }
        } else if action == "onLoginSubmitted" {
            // Login-Formular abgeschickt
        }
    }
}
