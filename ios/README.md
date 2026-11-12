# ZutrittApp – Native iOS Version (ab iOS 12.0)

Dieses Projekt ist die vollständige, native iOS-Portierung der Android-App **`ZutrittApp-release.apk`**.

---

## 🔍 Hintergrund: Warum keine direkte Konvertierung einer APK möglich ist

Eine Android-APK (`.apk`) enthält kompilierten Dalvik/ART-Bytecode (`classes.dex`), der auf dem Android-Framework (`android.*`, `androidx.*`) und dem Linux-basierten Android-Betriebssystem läuft. 

Apple iOS nutzt hingegen das XNU/Darwin-Betriebssystem, ARM64 Mach-O Maschinencode und Apples eigene Frameworks (`UIKit`, `WebKit`, etc.). Es existiert daher kein automatisiertes 1-Klick-Tool, das eine fertige `.apk` binär in eine `.ipa` umwandeln kann.

**Die Lösung:**
Die Datei `ZutrittApp-release.apk` wurde vollständig dekompiliert und analysiert. Alle Funktionen, JavaScript-Injections, Netzwerk-Hooks, UI-Strukturen und Einstellungen wurden 1:1 in modernem, nativem **Swift 5** mit **UIKit** und **WebKit** für **iOS 12.0 und neuer** nachgebaut.

---

## 📱 Enthaltene Funktionen (100 % Parität zur Android-Version)

1. **Hauptansicht (`MainViewController` / `WKWebView`)**:
   - Lädt die konfigurierte ESP32-Adresse (Standard: `http://192.168.4.1`).
   - Ladebalken (`UIProgressView`) synchronisiert mit dem Ladestatus der Seite.
   - **Form-Hooking (`/open`)**: Überwacht Absenden des Tor-Öffnen-Formulars (`form[action='/open']`) über eine native JavaScript-Bridge (`window.webkit.messageHandlers.ZutrittBridge`).
   - **Auto-Login**: Erkennt Login-Seiten (`/login`), füllt gespeicherte Zugangsdaten automatisch ein und sendet das Formular ab.
   - **Schlüsselwort-Erkennung**: Prüft nach dem Öffnen automatisch den Seiteninhalt auf das konfigurierte Schlüsselwort (Standard: *„wird geöffnet“*).
   - **Download von Logs**: Erkennt Klicks auf Log-Dateien (`.csv`) vom ESP32, lädt sie herunter und öffnet den iOS Share/Save-Dialog.
   - **Fehler-Bildschirm bei Verbindungsabbruch**:
     - Informiert den Nutzer, falls der ESP32 nicht erreichbar ist.
     - Buttons: *„Erneut versuchen“*, *„WLAN-Einstellungen öffnen“* und *„Einstellungen anpassen“*.

2. **GIF-Overlay (`GifOverlayViewController`)**:
   - Vollbild-Overlay mit abgedunkeltem Hintergrund nach erfolgreichem Öffnen.
   - Spielt die vom Nutzer ausgewählte animierte GIF flüssig ab.
   - Einstellbare Anzeigedauer (Standard: 4 Sekunden).
   - Vorzeitiges Beenden durch Antippen an beliebiger Stelle.

3. **Einstellungen (`SettingsViewController`)**:
   - **Geräte-Adresse**: Eingabefeld für URL + Button *„Auf Standard-AP-Adresse zurücksetzen“*.
   - **Automatischer Login**: Ein-/Ausschalter, Benutzername und Passwort (mit *„Passwort anzeigen“*-Umschalter).
   - **GIF-Overlay**: Ein-/Ausschalter, Dateiauswahl (`UIDocumentPicker`), Live-Vorschau, Anzeigedauer in Sekunden und Erfolgs-Schlüsselwort.
   - Gespeichert über `UserDefaults` und lokale Dateiablage im Sandbox-Dokumentenverzeichnis.

4. **Kompatibilität & Sicherheit**:
   - **iOS 12.0+**: Kompatibel von iOS 12 bis zum aktuellsten iOS 17 / 18.
   - **Klares HTTP erlaubt (`NSAppTransportSecurity`)**: Notwendig, da der ESP32 im Access-Point-Modus (`http://192.168.4.1`) ohne SSL-Zertifikate arbeitet.

---

## 🛠 Projektstruktur

```
ios/
├── ZutrittApp.xcodeproj/              # Xcode Projektdatei
│   ├── project.pbxproj
│   └── project.xcworkspace/
├── ZutrittApp/
│   ├── App/
│   │   ├── AppDelegate.swift          # App-Start & Window-Setup (iOS 12)
│   │   └── SceneDelegate.swift        # Scene-Management (iOS 13+)
│   ├── Controllers/
│   │   ├── MainViewController.swift   # WebView & Bridge
│   │   ├── SettingsViewController.swift# Einstellungen & GIF-Picker
│   │   └── GifOverlayViewController.swift# Vollbild-GIF Overlay
│   ├── Models/
│   │   └── AppPreferences.swift       # Preferences-Verwaltung
│   ├── Helpers/
│   │   ├── GifImageHelper.swift       # Nativer ImageIO GIF-Player & iOS 12 Colors
│   │   └── ToastView.swift            # Toast-Benachrichtigungen
│   ├── Resources/
│   │   ├── Info.plist                 # Berechtigungen & HTTP-Freigabe
│   │   └── LaunchScreen.storyboard    # Startbildschirm
│   └── Assets.xcassets/               # App-Icon Katalog
└── README.md
```

---

## 🚀 Bauen und Installieren

### Option A: In Xcode (auf einem Mac)
1. Ordner `ios/` auf einen Mac kopieren.
2. `ZutrittApp.xcodeproj` mit **Xcode** öffnen.
3. Apple-Entwickler-Account unter *Signing & Capabilities* auswählen.
4. iPhone per USB anschließen oder Simulator auswählen und auf **Play (Run)** drücken.

### Option B: Automatisch via GitHub Actions (ohne eigenen Mac)
Im Repository liegt bereits die Datei `.github/workflows/build-ios.yml`:
1. Repository zu GitHub pushen.
2. Unter **Actions** wird der Workflow *„Build iOS App“* automatisch auf einer macOS-Cloud-VM ausgeführt.
3. Nach Abschluss steht die fertige `.ipa`-Datei als Download-Artefakt bereit.

### Option C: Sideloading der `.ipa` auf das iPhone
Eine erstellte `.ipa` kann ohne Jailbreak über gängige Sideloading-Tools installiert werden:
- **AltStore** (Windows / Mac)
- **Sideloadly** (Windows / Mac)
- **TrollStore** (für kompatible iOS 14.0 – 16.6.1 / 17.0 Geräte)
