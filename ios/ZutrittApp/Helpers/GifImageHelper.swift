import UIKit
import ImageIO
import MobileCoreServices

/// Hilfsklasse zur Decodierung und Darstellung von animierten GIFs (kompatibel ab iOS 12.0).
enum GifImageHelper {
    
    /// Erzeugt ein animiertes `UIImage` aus Bilddaten eines GIFs.
    static func animatedImage(with data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }
        
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0
        
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                continue
            }
            let frameDuration = delayForImageAtIndex(i, source: source)
            totalDuration += frameDuration
            images.append(UIImage(cgImage: cgImage))
        }
        
        if images.isEmpty {
            return nil
        }
        
        if images.count == 1 {
            return images.first
        }
        
        return UIImage.animatedImage(with: images, duration: totalDuration > 0 ? totalDuration : 1.0)
    }
    
    private static func delayForImageAtIndex(_ index: Int, source: CGImageSource) -> Double {
        var delay = 0.1
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return delay
        }
        
        if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclampedDelay > 0 {
            delay = unclampedDelay
        } else if let standardDelay = gifProperties[kCGImagePropertyGIFDelayTime] as? Double, standardDelay > 0 {
            delay = standardDelay
        }
        
        // Browser/Systeme behandeln Delays < 0.02 s als 0.1 s
        if delay < 0.02 {
            delay = 0.1
        }
        
        return delay
    }
}

// MARK: - iOS 12 Backwards Compatibility Colors
extension UIColor {
    static var appBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
    
    static var appSecondaryBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemBackground
        } else {
            return UIColor(white: 0.96, alpha: 1.0)
        }
    }
    
    static var appLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }
    
    static var appSecondaryLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .darkGray
        }
    }
    
    static var appSeparator: UIColor {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return UIColor(white: 0.85, alpha: 1.0)
        }
    }
    
    static var appPrimaryTint: UIColor {
        return UIColor(red: 0.08, green: 0.45, blue: 0.85, alpha: 1.0) // Material Blue
    }
}
