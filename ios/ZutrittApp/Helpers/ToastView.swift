import UIKit

/// Zeigt kurze Statusbenachrichtigungen im Android-Toast-Stil an (ab iOS 12.0).
final class ToastView: UIView {
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(message: String) {
        super.init(frame: .zero)
        setupView(message: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(message: String) {
        backgroundColor = UIColor.black.withAlphaComponent(0.85)
        layer.cornerRadius = 20
        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        alpha = 0
        
        messageLabel.text = message
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
        ])
    }
    
    static func show(message: String, in view: UIView, duration: TimeInterval = 3.0) {
        let toast = ToastView(message: message)
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        
        UIView.animate(withDuration: 0.25, animations: {
            toast.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseOut, animations: {
                toast.alpha = 0.0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
