import UIKit
import MobileCoreServices

protocol SettingsViewControllerDelegate: AnyObject {
    func didUpdateSettings(urlChanged: Bool)
}

/// Einstellungs-Bildschirm der Zutritt-App (äquivalent zu SettingsActivity).
final class SettingsViewController: UIViewController, UIDocumentPickerDelegate {
    
    weak var delegate: SettingsViewControllerDelegate?
    
    private let prefs = AppPreferences.shared
    private var initialUrl: String = ""
    private var pendingGifData: Data?
    private var pendingGifFileName: String?
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()
    
    private let contentView: UIView = {
        let cv = UIView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // Sektion 1: Geräte-Adresse
    private let sectionDeviceLabel: UILabel = {
        let l = UILabel()
        l.text = "GERÄTE-ADRESSE"
        l.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        l.textColor = .appSecondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let editDeviceUrl: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "z. B. http://192.168.4.1"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.keyboardType = .URL
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let buttonResetUrl: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Auf Standard-AP-Adresse zurücksetzen", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // Sektion 2: Auto-Login
    private let sectionAutoLoginLabel: UILabel = {
        let l = UILabel()
        l.text = "AUTOMATISCHER LOGIN"
        l.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        l.textColor = .appSecondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let autoLoginRow: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let autoLoginLabel: UILabel = {
        let l = UILabel()
        l.text = "Auto-Login aktivieren"
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = .appLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let switchAutoLogin: UISwitch = {
        let s = UISwitch()
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private let editAutoUser: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "Gespeicherter Benutzername"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let editAutoPass: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "Gespeichertes Passwort"
        tf.isSecureTextEntry = true
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let togglePasswordButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Passwort anzeigen", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // Sektion 3: GIF-Overlay
    private let sectionGifLabel: UILabel = {
        let l = UILabel()
        l.text = "GIF NACH ERFOLGREICHEM TOR-ÖFFNEN"
        l.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        l.textColor = .appSecondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let gifRow: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let gifEnableLabel: UILabel = {
        let l = UILabel()
        l.text = "GIF-Anzeige aktiviert"
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = .appLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let switchGifEnabled: UISwitch = {
        let s = UISwitch()
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private let buttonPickGif: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("GIF auswählen…", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        b.backgroundColor = .appSecondaryBackground
        b.layer.cornerRadius = 8
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.appSeparator.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let textGifFileName: UILabel = {
        let l = UILabel()
        l.text = "Keine GIF-Datei ausgewählt"
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .appSecondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let imageGifPreview: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .appSecondaryBackground
        iv.layer.cornerRadius = 8
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.appSeparator.cgColor
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let durationLabel: UILabel = {
        let l = UILabel()
        l.text = "Anzeigedauer der GIF (Sekunden):"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .appLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let editDuration: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "4"
        tf.keyboardType = .numberPad
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let keywordLabel: UILabel = {
        let l = UILabel()
        l.text = "Erfolgs-Schlüsselwort im Text:"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .appLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let editKeyword: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "Standard: wird geöffnet"
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let buttonSaveSettings: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Einstellungen speichern", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        b.backgroundColor = .appPrimaryTint
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Einstellungen"
        view.backgroundColor = .appBackground
        
        setupNavigation()
        setupLayout()
        setupActions()
        loadCurrentSettings()
    }
    
    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Abbrechen",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Speichern",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // AutoLogin row
        autoLoginRow.addSubview(autoLoginLabel)
        autoLoginRow.addSubview(switchAutoLogin)
        NSLayoutConstraint.activate([
            autoLoginLabel.leadingAnchor.constraint(equalTo: autoLoginRow.leadingAnchor),
            autoLoginLabel.centerYAnchor.constraint(equalTo: autoLoginRow.centerYAnchor),
            switchAutoLogin.trailingAnchor.constraint(equalTo: autoLoginRow.trailingAnchor),
            switchAutoLogin.centerYAnchor.constraint(equalTo: autoLoginRow.centerYAnchor),
            switchAutoLogin.leadingAnchor.constraint(greaterThanOrEqualTo: autoLoginLabel.trailingAnchor, constant: 8),
            autoLoginRow.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // GIF row
        gifRow.addSubview(gifEnableLabel)
        gifRow.addSubview(switchGifEnabled)
        NSLayoutConstraint.activate([
            gifEnableLabel.leadingAnchor.constraint(equalTo: gifRow.leadingAnchor),
            gifEnableLabel.centerYAnchor.constraint(equalTo: gifRow.centerYAnchor),
            switchGifEnabled.trailingAnchor.constraint(equalTo: gifRow.trailingAnchor),
            switchGifEnabled.centerYAnchor.constraint(equalTo: gifRow.centerYAnchor),
            switchGifEnabled.leadingAnchor.constraint(greaterThanOrEqualTo: gifEnableLabel.trailingAnchor, constant: 8),
            gifRow.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let subviews = [
            sectionDeviceLabel, editDeviceUrl, buttonResetUrl,
            sectionAutoLoginLabel, autoLoginRow, editAutoUser, editAutoPass, togglePasswordButton,
            sectionGifLabel, gifRow, buttonPickGif, textGifFileName, imageGifPreview,
            durationLabel, editDuration, keywordLabel, editKeyword, buttonSaveSettings
        ]
        
        for sv in subviews {
            contentView.addSubview(sv)
        }
        
        let pad: CGFloat = 20
        NSLayoutConstraint.activate([
            // Device URL
            sectionDeviceLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            sectionDeviceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            sectionDeviceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            editDeviceUrl.topAnchor.constraint(equalTo: sectionDeviceLabel.bottomAnchor, constant: 8),
            editDeviceUrl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            editDeviceUrl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            editDeviceUrl.heightAnchor.constraint(equalToConstant: 42),
            
            buttonResetUrl.topAnchor.constraint(equalTo: editDeviceUrl.bottomAnchor, constant: 4),
            buttonResetUrl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            
            // Auto-Login
            sectionAutoLoginLabel.topAnchor.constraint(equalTo: buttonResetUrl.bottomAnchor, constant: 24),
            sectionAutoLoginLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            sectionAutoLoginLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            autoLoginRow.topAnchor.constraint(equalTo: sectionAutoLoginLabel.bottomAnchor, constant: 6),
            autoLoginRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            autoLoginRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            editAutoUser.topAnchor.constraint(equalTo: autoLoginRow.bottomAnchor, constant: 8),
            editAutoUser.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            editAutoUser.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            editAutoUser.heightAnchor.constraint(equalToConstant: 42),
            
            editAutoPass.topAnchor.constraint(equalTo: editAutoUser.bottomAnchor, constant: 10),
            editAutoPass.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            editAutoPass.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            editAutoPass.heightAnchor.constraint(equalToConstant: 42),
            
            togglePasswordButton.topAnchor.constraint(equalTo: editAutoPass.bottomAnchor, constant: 4),
            togglePasswordButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            // GIF Overlay
            sectionGifLabel.topAnchor.constraint(equalTo: togglePasswordButton.bottomAnchor, constant: 24),
            sectionGifLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            sectionGifLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            gifRow.topAnchor.constraint(equalTo: sectionGifLabel.bottomAnchor, constant: 6),
            gifRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            gifRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            buttonPickGif.topAnchor.constraint(equalTo: gifRow.bottomAnchor, constant: 10),
            buttonPickGif.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            buttonPickGif.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            buttonPickGif.heightAnchor.constraint(equalToConstant: 44),
            
            textGifFileName.topAnchor.constraint(equalTo: buttonPickGif.bottomAnchor, constant: 6),
            textGifFileName.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            textGifFileName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            imageGifPreview.topAnchor.constraint(equalTo: textGifFileName.bottomAnchor, constant: 8),
            imageGifPreview.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageGifPreview.widthAnchor.constraint(equalToConstant: 160),
            imageGifPreview.heightAnchor.constraint(equalToConstant: 120),
            
            durationLabel.topAnchor.constraint(equalTo: imageGifPreview.bottomAnchor, constant: 16),
            durationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            editDuration.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 6),
            editDuration.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            editDuration.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            editDuration.heightAnchor.constraint(equalToConstant: 42),
            
            keywordLabel.topAnchor.constraint(equalTo: editDuration.bottomAnchor, constant: 12),
            keywordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            keywordLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            editKeyword.topAnchor.constraint(equalTo: keywordLabel.bottomAnchor, constant: 6),
            editKeyword.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            editKeyword.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            editKeyword.heightAnchor.constraint(equalToConstant: 42),
            
            // Save Button
            buttonSaveSettings.topAnchor.constraint(equalTo: editKeyword.bottomAnchor, constant: 28),
            buttonSaveSettings.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            buttonSaveSettings.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            buttonSaveSettings.heightAnchor.constraint(equalToConstant: 48),
            buttonSaveSettings.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        buttonResetUrl.addTarget(self, action: #selector(resetUrlTapped), for: .touchUpInside)
        togglePasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        buttonPickGif.addTarget(self, action: #selector(pickGifTapped), for: .touchUpInside)
        buttonSaveSettings.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }
    
    private func loadCurrentSettings() {
        initialUrl = prefs.deviceUrl
        editDeviceUrl.text = prefs.deviceUrl
        switchAutoLogin.isOn = prefs.isAutoLoginEnabled
        editAutoUser.text = prefs.autoLoginUser
        editAutoPass.text = prefs.autoLoginPass
        switchGifEnabled.isOn = prefs.isGifEnabled
        editDuration.text = "\(prefs.gifDurationSeconds)"
        editKeyword.text = prefs.successKeyword
        
        if let name = prefs.gifFileName, !name.isEmpty, let data = prefs.loadGifData() {
            textGifFileName.text = name
            imageGifPreview.image = GifImageHelper.animatedImage(with: data)
        } else {
            textGifFileName.text = "Keine GIF-Datei ausgewählt"
            imageGifPreview.image = nil
        }
    }
    
    // MARK: - Actions
    
    @objc private func resetUrlTapped() {
        editDeviceUrl.text = AppPreferences.defaultUrl
    }
    
    @objc private func togglePasswordVisibility() {
        editAutoPass.isSecureTextEntry.toggle()
        let title = editAutoPass.isSecureTextEntry ? "Passwort anzeigen" : "Passwort verbergen"
        togglePasswordButton.setTitle(title, for: .normal)
    }
    
    @objc private func pickGifTapped() {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.gif], asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: [kUTTypeGIF as String], in: .import)
        }
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedUrl = urls.first else { return }
        
        let shouldStopAccessing = selectedUrl.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                selectedUrl.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let data = try? Data(contentsOf: selectedUrl) else {
            ToastView.show(message: "Fehler beim Laden der GIF-Datei", in: view)
            return
        }
        
        pendingGifData = data
        pendingGifFileName = selectedUrl.lastPathComponent
        textGifFileName.text = selectedUrl.lastPathComponent
        imageGifPreview.image = GifImageHelper.animatedImage(with: data)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func saveTapped() {
        var rawUrl = editDeviceUrl.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if rawUrl.isEmpty {
            rawUrl = AppPreferences.defaultUrl
        }
        if !rawUrl.lowercased().hasPrefix("http://") && !rawUrl.lowercased().hasPrefix("https://") {
            rawUrl = "http://" + rawUrl
        }
        
        let urlChanged = (rawUrl != initialUrl)
        prefs.deviceUrl = rawUrl
        prefs.isAutoLoginEnabled = switchAutoLogin.isOn
        prefs.autoLoginUser = editAutoUser.text ?? ""
        prefs.autoLoginPass = editAutoPass.text ?? ""
        prefs.isGifEnabled = switchGifEnabled.isOn
        
        if let durationText = editDuration.text, let duration = Int(durationText) {
            prefs.gifDurationSeconds = duration
        }
        
        let keyword = editKeyword.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        prefs.successKeyword = keyword.isEmpty ? AppPreferences.defaultKeyword : keyword
        
        if let data = pendingGifData, let name = pendingGifFileName {
            _ = prefs.saveGifData(data, fileName: name)
        }
        
        delegate?.didUpdateSettings(urlChanged: urlChanged)
        
        dismiss(animated: true) {
            if let window = UIApplication.shared.keyWindow {
                ToastView.show(message: "Einstellungen gespeichert", in: window)
            }
        }
    }
}
