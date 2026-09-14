import Foundation

enum ProteinFamily: String, Codable, CaseIterable, Sendable {
    case beef
    case chicken
    case pork
    case fish
    case seafood
    case egg
}

struct Dish: Identifiable, Hashable, Codable, Sendable {
    var id: String { title }
    let title: String
    let protein: ProteinFamily
}

enum DishPool {
    static let pizzaTitle = "Kyllingpizza med mozzarella og basilikum"

    static let all: [Dish] = [
        Dish(title: "Squash-lasagne", protein: .beef),
        Dish(title: "Chilistekte tigerreker med brokkolimos", protein: .seafood),
        Dish(title: "Cheeseburgerform", protein: .beef),
        Dish(title: "Koteletter med blomkålmos", protein: .pork),
        Dish(title: "Kyllingpizza med mozzarella og basilikum", protein: .chicken),
        Dish(title: "Meksikansk form med kylling", protein: .chicken),
        Dish(title: "Tigerreke-taco", protein: .seafood),
        Dish(title: "Fiskegrateng keto", protein: .fish),
        Dish(title: "Kremet lakseform", protein: .fish),
        Dish(title: "Eggeform med bacon og ost", protein: .egg),
    ]

    static let pizza: Dish = all.first { $0.title == pizzaTitle }!

    static func dish(titled title: String) -> Dish? {
        all.first { $0.title == title }
    }
}
