import SwiftUI

enum KKMotion {
    static let bobY: CGFloat = -6
    static let bob = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)
    static let pillEdge: CGFloat = 4
    static let pillRadius: CGFloat = 16
    static let pillMinHeight: CGFloat = 50
    static let mascotSize: CGFloat = 240
    static let pressScale: CGFloat = 0.98
    static let hopLift: CGFloat = -18
    static let skyCircle: CGFloat = 280

    static func snappy(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .snappy(duration: 0.28, extraBounce: 0.12)
    }

    static func press(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.08)
    }
}
