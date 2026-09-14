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
    static let forest = Color(hex: "1B4332")
    static let ink = Color(hex: "3C3C3C")
    static let muted = Color(hex: "777777")
    static let lime = Color(hex: "58CC02")
    static let limeEdge = Color(hex: "46A302")
    static let limeLid = Color(hex: "7AC70C")
    static let limeSprout = Color(hex: "89E219")
    static let sky = Color(hex: "DDF4FF")
    static let mint = Color(hex: "E8F8D8")
    static let peach = Color(hex: "FFF0E5")
    static let gold = Color(hex: "FFC800")
    static let berry = Color(hex: "CE82FF")
    static let blue = Color(hex: "1CB0F6")
    static let line = Color(hex: "E5E5E5")
    static let white = Color(hex: "FFFFFF")
    static let blush = Color(hex: "FF8AA0")
}
