import SwiftUI

struct WeekBoardDragActiveKey: PreferenceKey {
    static var defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct WeekPlannerView: View {
    private static let boardSpace = "weekBoard"

    @Environment(WeekStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @GestureState(resetTransaction: Transaction(animation: nil)) private var drag = WeekSlotDrag.inactive
    @State private var items: [WeekSlotItem] = []
    @State private var hoverIndex: Int?
    @State private var dropSettled = false
    @State private var liftCount = 0
    @State private var hoverTick = 0
    @State private var dropCount = 0

    private var displayedItems: [WeekSlotItem] {
        items.isEmpty ? WeekSlotItem.make(from: store.plan.slots) : items
    }

    private var dropWellVisible: Bool {
        guard !dropSettled, drag.isActive, let hoverIndex, let source = drag.source else { return false }
        return hoverIndex != source
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ukeplan")
                .font(KKFont.headline)
                .tracking(KKFont.headlineTracking)
                .foregroundStyle(KKColor.ink)
                .padding(.top, 8)
            Text("Hold en middag og dra den til en annen dag.")
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
                .padding(.top, 8)
            ScrollView {
                board
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            }
            .scrollDisabled(drag.isActive)
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            GetStartedButton(title: "Simuler ny uke", action: {
                withAnimation(KKMotion.snappy(reduceMotion)) {
                    store.simulateNewWeek()
                }
            })
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .preference(key: WeekBoardDragActiveKey.self, value: drag.isActive)
        .sensoryFeedback(.impact(weight: .light), trigger: liftCount)
        .sensoryFeedback(.selection, trigger: hoverTick)
        .sensoryFeedback(.impact(weight: .medium), trigger: dropCount)
        .onChange(of: store.plan.slots, initial: true) { _, slots in
            guard !drag.isActive else { return }
            items = WeekSlotItem.make(from: slots)
        }
        .onChange(of: drag.isActive) { _, active in
            if active {
                liftCount += 1
            } else {
                hoverIndex = nil
                dropSettled = false
            }
        }
        .onChange(of: hoverIndex) { _, new in
            guard let new, let source = drag.source, new != source else { return }
            hoverTick += 1
        }
    }

    private var board: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: KKMotion.weekRowSpacing) {
                ForEach(Array(PlanWeekday.allCases.enumerated()), id: \.element.id) { index, day in
                    WeekDayChip(day: day, highlighted: isTarget(index))
                        .frame(height: KKMotion.weekRowHeight)
                }
            }
            ZStack(alignment: .top) {
                WeekDropWell()
                    .frame(maxWidth: .infinity)
                    .frame(height: KKMotion.weekRowHeight)
                    .offset(y: CGFloat(hoverIndex ?? 0) * KKMotion.weekRowStride)
                    .opacity(dropWellVisible ? 1 : 0)
                    .animation(KKMotion.snappy(reduceMotion), value: hoverIndex)
                    .animation(KKMotion.snappy(reduceMotion), value: dropWellVisible)
                    .allowsHitTesting(false)
                VStack(spacing: KKMotion.weekRowSpacing) {
                    ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                        dishTile(item, index: index)
                    }
                }
            }
        }
        .coordinateSpace(.named(Self.boardSpace))
    }

    private func dishTile(_ item: WeekSlotItem, index: Int) -> some View {
        let lifted = drag.id == item.id && drag.isActive
        let followsFinger = lifted && !dropSettled
        return WeekDishTile(
            title: item.title,
            isSource: lifted,
            isTarget: isTarget(index),
            reduceMotion: reduceMotion
        )
        .offset(followsFinger ? drag.translation : .zero)
        .rotationEffect(tilt(for: followsFinger))
        .animation(KKMotion.snappy(reduceMotion)) { content in
            content.offset(y: followsFinger ? 0 : gapOffset(for: index))
        }
        .zIndex(followsFinger ? 10 : 0)
        .gesture(slotGesture(for: item, index: index))
        .accessibilityLabel(accessibilityLabel(for: index, title: item.title))
        .accessibilityHint("Hold inne og dra for å flytte")
        .accessibilityAction(named: "Flytt opp") {
            moveSlot(from: index, to: index - 1, animated: true)
        }
        .accessibilityAction(named: "Flytt ned") {
            moveSlot(from: index, to: index + 1, animated: true)
        }
    }

    private func slotGesture(for item: WeekSlotItem, index: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.28, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.boardSpace)))
            .updating($drag) { value, state, _ in
                switch value {
                case .first(true):
                    state = .pressing(id: item.id, index: index)
                case .second(true, let dragValue):
                    state = .dragging(id: item.id, index: index, translation: dragValue?.translation ?? .zero)
                default:
                    break
                }
            }
            .onChanged { value in
                guard case .second(true, let dragValue) = value else { return }
                hoverIndex = WeekSlotDrag.targetIndex(
                    source: index,
                    translation: dragValue?.translation ?? .zero
                )
            }
            .onEnded { value in
                let translation: CGSize
                if case .second(true, let dragValue) = value {
                    translation = dragValue?.translation ?? .zero
                } else {
                    translation = .zero
                }
                let target = WeekSlotDrag.targetIndex(source: index, translation: translation)
                commitDrag(from: index, to: target)
            }
    }

    private func isTarget(_ index: Int) -> Bool {
        guard !dropSettled, let hoverIndex, let source = drag.source else { return false }
        return hoverIndex == index && source != index && drag.isActive
    }

    private func gapOffset(for index: Int) -> CGFloat {
        guard !dropSettled, let source = drag.source, let hoverIndex, source != index else { return 0 }
        let stride = KKMotion.weekRowStride
        if source < hoverIndex, index > source, index <= hoverIndex { return -stride }
        if hoverIndex < source, index >= hoverIndex, index < source { return stride }
        return 0
    }

    private func tilt(for followsFinger: Bool) -> Angle {
        guard followsFinger, !reduceMotion else { return .zero }
        let clamped = min(max(drag.translation.width / 28, -8), 8)
        return .degrees(Double(clamped))
    }

    private func commitDrag(from source: Int, to target: Int) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dropSettled = true
            hoverIndex = nil
            moveSlot(from: source, to: target, animated: false)
        }
    }

    private func moveSlot(from source: Int, to target: Int, animated: Bool) {
        guard source != target,
              items.indices.contains(source),
              items.indices.contains(target) else { return }
        let apply = {
            var next = items
            let item = next.remove(at: source)
            next.insert(item, at: target)
            items = next
            store.moveSlot(from: source, to: target)
        }
        if animated {
            withAnimation(KKMotion.snappy(reduceMotion), apply)
        } else {
            apply()
        }
        dropCount += 1
    }

    private func accessibilityLabel(for index: Int, title: String?) -> String {
        let day = PlanWeekday.allCases[index].shortLabel
        return "\(day), \(title ?? "Fri")"
    }
}

private enum WeekSlotDrag: Equatable {
    case inactive
    case pressing(id: String, index: Int)
    case dragging(id: String, index: Int, translation: CGSize)

    var id: String? {
        switch self {
        case .inactive: nil
        case .pressing(let id, _), .dragging(let id, _, _): id
        }
    }

    var source: Int? {
        switch self {
        case .inactive: nil
        case .pressing(_, let index), .dragging(_, let index, _): index
        }
    }

    var translation: CGSize {
        switch self {
        case .dragging(_, _, let translation): translation
        case .inactive, .pressing: .zero
        }
    }

    var isActive: Bool {
        self != .inactive
    }

    static func targetIndex(source: Int, translation: CGSize) -> Int {
        let delta = Int((translation.height / KKMotion.weekRowStride).rounded())
        return min(max(source + delta, 0), PlanWeekday.allCases.count - 1)
    }
}

private struct WeekSlotItem: Identifiable, Equatable {
    let id: String
    var title: String?

    static func make(from slots: [String?]) -> [WeekSlotItem] {
        var empties = 0
        return slots.map { title in
            if let title {
                return WeekSlotItem(id: title, title: title)
            }
            empties += 1
            return WeekSlotItem(id: "fri-\(empties)", title: nil)
        }
    }
}

private struct WeekDayChip: View {
    var day: PlanWeekday
    var highlighted: Bool

    var body: some View {
        Text(day.shortLabel)
            .font(KKFont.cta)
            .foregroundStyle(highlighted ? KKColor.lime : KKColor.forest)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(highlighted ? KKColor.forest : KKColor.mint)
            )
            .accessibilityHidden(true)
    }
}

private struct WeekDropWell: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(KKColor.lime.opacity(0.38))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(KKColor.forest, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            )
    }
}

private struct WeekDishTile: View {
    var title: String?
    var isSource: Bool
    var isTarget: Bool
    var reduceMotion: Bool

    var body: some View {
        Text(title ?? "Fri")
            .font(KKFont.body)
            .foregroundStyle(title == nil ? KKColor.muted : KKColor.ink)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 14)
            .frame(
                maxWidth: .infinity,
                minHeight: KKMotion.weekRowHeight,
                maxHeight: KKMotion.weekRowHeight,
                alignment: .leading
            )
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isTarget ? KKColor.mint : KKColor.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isTarget || isSource ? KKColor.forest : KKColor.line,
                        lineWidth: isTarget || isSource ? 2 : 1
                    )
            )
            .shadow(
                color: KKColor.forest.opacity(isSource ? 0.22 : 0),
                radius: isSource ? 14 : 0,
                y: isSource ? 8 : 0
            )
            .scaleEffect(isSource ? KKMotion.dragLiftScale : 1)
            .animation(KKMotion.bouncy(reduceMotion), value: isSource)
            .animation(KKMotion.snappy(reduceMotion), value: isTarget)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    WeekPlannerView()
        .environment(WeekStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.week")!))
}
