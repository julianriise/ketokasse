import Foundation

enum ProteinFamily: String, Codable, CaseIterable, Sendable {
    case beef
    case chicken
    case pork
    case fish
    case seafood
    case egg
    case cheese
    case turkey
    case duck
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
        Dish(title: "Laksefilet med smør og asparges", protein: .fish),
        Dish(title: "Ovnsbakt laks med dill og fløte", protein: .fish),
        Dish(title: "Torsk i ovn med ost og spinat", protein: .fish),
        Dish(title: "Stekt sei med blomkålris", protein: .fish),
        Dish(title: "Reker i hvitløkssmør", protein: .seafood),
        Dish(title: "Kyllinglår med bacon", protein: .chicken),
        Dish(title: "Ostegratinert kyllingfilet", protein: .chicken),
        Dish(title: "Kylling i fløtesaus med brokkoli", protein: .chicken),
        Dish(title: "Kyllingcurry med kokosmelk", protein: .chicken),
        Dish(title: "Biff med smør og grønnsaker", protein: .beef),
        Dish(title: "Entrecôte med bearnaise", protein: .beef),
        Dish(title: "Kjøttkaker med brun saus (keto)", protein: .beef),
        Dish(title: "Kjøttdeiggryte med paprika", protein: .beef),
        Dish(title: "Chili con carne uten bønner", protein: .beef),
        Dish(title: "Svinesteik med fløtesaus", protein: .pork),
        Dish(title: "Ribbe uten sukkerglasur", protein: .pork),
        Dish(title: "Baconpakket asparges med egg", protein: .pork),
        Dish(title: "Omelett med spinat og feta", protein: .egg),
        Dish(title: "Frittata med paprika og ost", protein: .egg),
        Dish(title: "Blomkålgrateng med bacon", protein: .pork),
        Dish(title: "Brokkoligrateng med cheddar", protein: .cheese),
        Dish(title: "Zucchini-båter med kjøttdeig", protein: .beef),
        Dish(title: "Aubergine-lasagne", protein: .beef),
        Dish(title: "Halloumi med salat og avokado", protein: .cheese),
        Dish(title: "Ostebakt blomkål", protein: .cheese),
        Dish(title: "Pølsegryte med kremfløte", protein: .pork),
        Dish(title: "Chorizo med paprika og egg", protein: .pork),
        Dish(title: "Kyllingsalat med avokado og majones", protein: .chicken),
        Dish(title: "Tunfisksalat med egg og oliven", protein: .fish),
        Dish(title: "Caesar-salat med kylling (uten krutonger)", protein: .chicken),
        Dish(title: "Gresk salat med feta og oliven", protein: .cheese),
        Dish(title: "Stekt blomkålris med egg og bacon", protein: .egg),
        Dish(title: "Keto burger uten brød", protein: .beef),
        Dish(title: "Smashburger med ost og bacon", protein: .beef),
        Dish(title: "Pulled pork med coleslaw", protein: .pork),
        Dish(title: "Andebryst med rødkål", protein: .duck),
        Dish(title: "Kalkunfilet med fløtesaus", protein: .turkey),
        Dish(title: "Makrell i tomat med egg (enkel)", protein: .fish),
        Dish(title: "Kamskjell med smør", protein: .seafood),
        Dish(title: "Hummerhaler med aioli", protein: .seafood),
    ]

    static let pizza: Dish = all.first { $0.title == pizzaTitle }!

    static func dish(titled title: String) -> Dish? {
        all.first { $0.title == title }
    }
}
