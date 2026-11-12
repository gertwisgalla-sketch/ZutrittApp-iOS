import UIKit

/// Vollbild-Overlay zur Anzeige einer animierten GIF nach erfolgreichem Tor-Öffnen (äquivalent zu GifOverlayActivity).
final class GifOverlayViewController: UIViewController {
    
    private let gifData: Data
    private let durationSeconds: Int
    private var dismissTimer: Timer?
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "Tippen zum Schließen"
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(gifData: Data, durationSeconds: Int) {
        self.gifData = gifData
        self.durationSeconds = durationSeconds
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.88)
        
        setupViews()
        setupGesture()
        loadGif()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Automatisches Schließen nach konfigurierter Anzeigedauer
        dismissTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(durationSeconds), repeats: false) { [weak self] _ in
            self?.dismissOverlay()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
    
    private func setupViews() {
        view.addSubview(imageView)
        view.addSubview(hintLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.88),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.70),
            
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func handleTap() {
        dismissOverlay()
    }
    
    private func loadGif() {
        if let animatedImg = GifImageHelper.animatedImage(with: gifData) {
            imageView.image = animatedImg
        }
    }
    
    private func dismissOverlay() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        dismiss(animated: true, completion: nil)
    }
}
