import SwiftUI

enum KKFont {
    static func nunito(_ size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle) -> Font {
        Font.custom("Nunito", size: size, relativeTo: style).weight(weight)
    }

    static let wordmark = nunito(34, weight: .heavy, relativeTo: .largeTitle)
    static let headline = nunito(32, weight: .heavy, relativeTo: .title)
    static let body = nunito(17, weight: .regular, relativeTo: .body)
    static let cta = nunito(15, weight: .bold, relativeTo: .headline)

    static let wordmarkTracking: CGFloat = 34 * -0.03
    static let headlineTracking: CGFloat = 32 * -0.03
    static let ctaTracking: CGFloat = 0.8
}
