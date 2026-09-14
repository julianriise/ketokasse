import Foundation
import Observation

@MainActor
@Observable
final class CookingSession {
    let recipe: Recipe
    private(set) var phase: RecipePhase = .gather
    private(set) var stepIndex = 0
    private(set) var foundIDs: Set<String> = []
    private(set) var awardedIDs: Set<String> = []
    private(set) var sessionPoints = 0
    private(set) var skippedGather = false
    private(set) var didCommit = false

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    var currentStep: RecipeStep? {
        let steps = recipe.steps(in: phase)
        guard steps.indices.contains(stepIndex) else { return nil }
        return steps[stepIndex]
    }

    var gatherComplete: Bool {
        recipe.gather.allSatisfy { foundIDs.contains($0.id) }
    }

    var canAdvanceGather: Bool {
        gatherComplete || skippedGather
    }

    func isFound(_ id: String) -> Bool {
        foundIDs.contains(id)
    }

    func toggleFound(_ id: String) {
        guard phase == .gather, !skippedGather else { return }
        guard let step = recipe.gather.first(where: { $0.id == id }) else { return }
        if foundIDs.contains(id) {
            foundIDs.remove(id)
            if awardedIDs.remove(id) != nil {
                sessionPoints -= step.points
            }
        } else {
            foundIDs.insert(id)
            award(step)
        }
    }

    func skipRemainingGather() {
        guard phase == .gather, !gatherComplete, !skippedGather else { return }
        skippedGather = true
        advance()
    }

    func advance() {
        switch phase {
        case .gather:
            guard canAdvanceGather else { return }
            move(to: .prep)
        case .prep, .cook, .serve:
            guard let step = currentStep else { return }
            award(step)
            let steps = recipe.steps(in: phase)
            if stepIndex + 1 < steps.count {
                stepIndex += 1
            } else if let next = nextPhase(after: phase) {
                move(to: next)
            }
        case .score:
            break
        }
    }

    func commit(to store: PointsStore) {
        guard phase == .score, !didCommit else { return }
        didCommit = true
        store.add(sessionPoints)
    }

    func points(in phase: RecipePhase) -> Int {
        recipe.steps(in: phase)
            .filter { awardedIDs.contains($0.id) }
            .reduce(0) { $0 + $1.points }
    }

    private func move(to phase: RecipePhase) {
        var next = phase
        while recipe.steps(in: next).isEmpty {
            guard let after = nextPhase(after: next) else {
                self.phase = .score
                stepIndex = 0
                return
            }
            next = after
        }
        self.phase = next
        stepIndex = 0
    }

    private func nextPhase(after phase: RecipePhase) -> RecipePhase? {
        switch phase {
        case .gather: .prep
        case .prep: .cook
        case .cook: .serve
        case .serve: .score
        case .score: nil
        }
    }

    private func award(_ step: RecipeStep) {
        guard awardedIDs.insert(step.id).inserted else { return }
        sessionPoints += step.points
    }
}
