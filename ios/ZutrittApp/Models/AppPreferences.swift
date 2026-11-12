import Foundation

/// Verwaltet alle Benutzereinstellungen der Zutritt-App (äquivalent zu Prefs.kt in Android).
final class AppPreferences {
    static let shared = AppPreferences()
    
    // Standardwerte
    static let defaultUrl = "http://192.168.4.1"
    static let defaultKeyword = "wird geöffnet"
    static let defaultDurationSec = 4
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let deviceUrl = "device_url"
        static let autoLoginEnabled = "auto_login_enabled"
        static let autoLoginUser = "auto_login_user"
        static let autoLoginPass = "auto_login_pass"
        static let gifEnabled = "gif_enabled"
        static let gifDurationSec = "gif_duration_sec"
        static let successKeyword = "success_keyword"
        static let gifFileName = "gif_file_name"
    }
    
    private init() {
        // Registriere Standardwerte
        defaults.register(defaults: [
            Keys.deviceUrl: AppPreferences.defaultUrl,
            Keys.autoLoginEnabled: false,
            Keys.autoLoginUser: "",
            Keys.autoLoginPass: "",
            Keys.gifEnabled: true,
            Keys.gifDurationSec: AppPreferences.defaultDurationSec,
            Keys.successKeyword: AppPreferences.defaultKeyword
        ])
    }
    
    // MARK: - Properties
    
    var deviceUrl: String {
        get { defaults.string(forKey: Keys.deviceUrl) ?? AppPreferences.defaultUrl }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.deviceUrl) }
    }
    
    var isAutoLoginEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoLoginEnabled) }
        set { defaults.set(newValue, forKey: Keys.autoLoginEnabled) }
    }
    
    var autoLoginUser: String {
        get { defaults.string(forKey: Keys.autoLoginUser) ?? "" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.autoLoginUser) }
    }
    
    var autoLoginPass: String {
        get { defaults.string(forKey: Keys.autoLoginPass) ?? "" }
        set { defaults.set(newValue, forKey: Keys.autoLoginPass) }
    }
    
    var isGifEnabled: Bool {
        get { defaults.bool(forKey: Keys.gifEnabled) }
        set { defaults.set(newValue, forKey: Keys.gifEnabled) }
    }
    
    var gifDurationSeconds: Int {
        get {
            let val = defaults.integer(forKey: Keys.gifDurationSec)
            return val > 0 ? val : AppPreferences.defaultDurationSec
        }
        set {
            let clamped = max(1, min(60, newValue))
            defaults.set(clamped, forKey: Keys.gifDurationSec)
        }
    }
    
    var successKeyword: String {
        get { defaults.string(forKey: Keys.successKeyword) ?? AppPreferences.defaultKeyword }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.successKeyword) }
    }
    
    var gifFileName: String? {
        get { defaults.string(forKey: Keys.gifFileName) }
        set { defaults.set(newValue, forKey: Keys.gifFileName) }
    }
    
    func resetToDefaultUrl() {
        deviceUrl = AppPreferences.defaultUrl
    }
    
    // MARK: - GIF File Storage
    
    private var gifStorageURL: URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docs.appendingPathComponent("custom_overlay.gif")
    }
    
    func saveGifData(_ data: Data, fileName: String) -> Bool {
        guard let destination = gifStorageURL else { return false }
        do {
            try data.write(to: destination, options: .atomic)
            gifFileName = fileName
            return true
        } catch {
            print("Fehler beim Speichern der GIF: \(error)")
            return false
        }
    }
    
    func loadGifData() -> Data? {
        guard let url = gifStorageURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    func removeGif() {
        if let url = gifStorageURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        gifFileName = nil
    }
}
