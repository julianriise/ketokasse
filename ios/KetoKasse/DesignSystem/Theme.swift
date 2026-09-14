import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum KKColor {
    static let forest = Color(hex: "00473C")
    static let ink = Color(hex: "0E150E")
    static let muted = Color(hex: "8C8C82")
    static let lime = Color(hex: "E6FF55")
    static let limeEdge = Color(hex: "0E150E")
    static let limeLid = Color(hex: "2D6B52")
    static let limeSprout = Color(hex: "E6FF55")
    static let sky = Color(hex: "D6E9E9")
    static let mint = Color(hex: "D8E5D6")
    static let peach = Color(hex: "F9DFCE")
    static let gold = Color(hex: "E59700")
    static let berry = Color(hex: "A61846")
    static let blue = Color(hex: "00473C")
    static let line = Color(hex: "DEDED6")
    static let white = Color(hex: "FFFFFF")
    static let blush = Color(hex: "F9DFCE")
}
