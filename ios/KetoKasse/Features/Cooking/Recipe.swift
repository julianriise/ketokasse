import Foundation

enum RecipePhase: String, Hashable, CaseIterable, Sendable {
    case gather
    case prep
    case cook
    case serve
    case score

    var title: String {
        switch self {
        case .gather: "Samle"
        case .prep: "Forbered"
        case .cook: "Stek"
        case .serve: "Server"
        case .score: "Poeng"
        }
    }
}

enum RecipeStepKind: String, Hashable, Sendable {
    case gatherItem
    case prepTask
    case cookTask
    case serveNote
}

struct RecipeStep: Identifiable, Hashable, Sendable {
    let id: String
    let kind: RecipeStepKind
    let title: String
    let body: String
    let points: Int
    let symbolName: String
}

struct Recipe: Identifiable, Hashable, Sendable {
    var id: String { dishTitle }
    let dishTitle: String
    let gather: [RecipeStep]
    let prep: [RecipeStep]
    let cook: [RecipeStep]
    let serve: [RecipeStep]

    var steps: [RecipeStep] {
        gather + prep + cook + serve
    }

    func steps(in phase: RecipePhase) -> [RecipeStep] {
        switch phase {
        case .gather: gather
        case .prep: prep
        case .cook: cook
        case .serve: serve
        case .score: []
        }
    }
}
