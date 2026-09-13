# Arena synthesis: KetoKasse

## Cross-judge (parent)

| Criterion | A (FSM + reveal) | B (scroll + draft) |
| --- | --- | --- |
| Day exclusivity in a structure | DayRegistry record | DaySlotTable discriminant |
| Derived next delivery | Stored on choose (weaker) | Pure deriveNextDelivery (stronger) |
| Prescribed vertical stack visible | Partial until phases advance | Always visible |
| Small public surface | Larger event/reducer API | Five domain ops |
| Norwegian copy coverage | Outline only | Full table |
| Farmer/keto tokens named | Not in package | Deferred to impl (neutral) |

## Pick

**Base: B.** Matches the landing brief (full stack visible, no gating). Next delivery stays derived. Smaller API. Complete Norwegian copy.

## Graft from A

- Keep exclusivity language sharp in UI copy ("Én kunde per dag") already in B.
- Reject progressive reveal and stored nextDelivery.
- Reject DayRegistry Map with holderId for v1 (no auth); keep B's taken boolean snapshot.

## Dropouts

First candidate A runner produced nothing. Parent wrote a lean FSM package so comparison stayed two-shaped.

## Verification of synthesis

Design package at `/tmp/arena-ketokasse/candidate-b/` plus this note. Implementation follows B's module map under `/agent/web`.
