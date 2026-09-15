from __future__ import annotations

import re
from dataclasses import dataclass
from itertools import combinations, permutations
from pathlib import Path

MASK = (1 << 64) - 1
PIZZA_TITLE = "Kyllingpizza med mozzarella og basilikum"
DAY_COUNT = 7
DINNER_COUNT = 5


@dataclass(frozen=True)
class Dish:
    title: str
    protein: str


class SplitMix64:
    def __init__(self, state: int) -> None:
        self.state = state & MASK

    def next(self) -> int:
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (z ^ (z >> 31)) & MASK


def shuffled(items: list, rng: SplitMix64) -> list:
    items = list(items)
    i = len(items)
    while i > 1:
        i -= 1
        j = rng.next() % (i + 1)
        items[i], items[j] = items[j], items[i]
    return items


def parse_pool(swift_text: str) -> list[Dish]:
    dishes = [
        Dish(title=title, protein=protein)
        for title, protein in re.findall(
            r'Dish\(title: "([^"]+)", protein: \.(\w+)\)',
            swift_text,
        )
    ]
    return dishes


def parse_pizza_title(swift_text: str) -> str:
    match = re.search(r'static let pizzaTitle = "([^"]+)"', swift_text)
    if not match:
        raise ValueError("pizzaTitle missing")
    return match.group(1)


def proteins_are_valid(slots: list[Dish | None]) -> bool:
    if len(slots) != DAY_COUNT:
        return False
    filled = [dish for dish in slots if dish is not None]
    if len(filled) != DINNER_COUNT:
        return False
    for index in range(DAY_COUNT - 1):
        left, right = slots[index], slots[index + 1]
        if left is not None and right is not None and left.protein == right.protein:
            return False
    return True


def empty_pairs() -> list[tuple[int, int]]:
    return list(combinations(range(DAY_COUNT), 2))


def build(dishes: list[Dish], empty: tuple[int, int]) -> list[Dish | None]:
    slots: list[Dish | None] = [None] * DAY_COUNT
    dish_index = 0
    for day in range(DAY_COUNT):
        if day in empty:
            continue
        slots[day] = dishes[dish_index]
        dish_index += 1
    return slots


def pick_dishes(pool: list[Dish], pizza_title: str, previous: set[str], rng: SplitMix64) -> list[Dish]:
    pizza = next(dish for dish in pool if dish.title == pizza_title)
    rest = [dish for dish in pool if dish.title != pizza.title]
    fresh = shuffled([dish for dish in rest if dish.title not in previous], rng)
    stale = shuffled([dish for dish in rest if dish.title in previous], rng)
    ranked = fresh + stale
    four: list[Dish] = []
    chicken_count = 1
    for dish in ranked:
        if len(four) == 4:
            break
        if dish.protein == pizza.protein and chicken_count >= 4:
            continue
        four.append(dish)
        if dish.protein == pizza.protein:
            chicken_count += 1
    for dish in ranked:
        if len(four) == 4:
            break
        if dish not in four:
            four.append(dish)
    return [pizza] + four


def place(dishes: list[Dish], rng: SplitMix64) -> list[Dish | None]:
    empties = shuffled(empty_pairs(), rng)
    for _ in range(200):
        perm = shuffled(dishes, rng)
        for empty in empties:
            slots = build(perm, empty)
            if proteins_are_valid(slots):
                return slots
    for perm in permutations(dishes):
        for empty in empty_pairs():
            slots = build(list(perm), empty)
            if proteins_are_valid(slots):
                return slots
    return build(dishes, (2, 5))


def generate(seed: int, previous: set[str], pool: list[Dish], pizza_title: str = PIZZA_TITLE) -> list[str | None]:
    rng = SplitMix64(seed)
    dishes = pick_dishes(pool, pizza_title, previous, rng)
    slots = place(dishes, rng)
    return [dish.title if dish else None for dish in slots]


def filled_titles(slots: list[str | None]) -> list[str]:
    return [title for title in slots if title]


def move_slot(slots: list[str | None], source: int, target: int) -> list[str | None]:
    if source == target:
        return list(slots)
    next_slots = list(slots)
    item = next_slots.pop(source)
    next_slots.insert(target, item)
    return next_slots


def assert_move_slot_behavior() -> None:
    if move_slot(["A", "B", "C", "D", "E", "F", "G"], 0, 3) != ["B", "C", "D", "A", "E", "F", "G"]:
        raise SystemExit("move down did not shift later days toward the source")
    if move_slot(["A", "B", "C", "D", "E", "F", "G"], 3, 0) != ["D", "A", "B", "C", "E", "F", "G"]:
        raise SystemExit("move up did not shift earlier days toward the source")
    if move_slot(["A", "B", None, "C", None, "D", "E"], 0, 2) != ["B", None, "A", "C", None, "D", "E"]:
        raise SystemExit("move onto Fri did not leave an empty source day")
    if move_slot(["A", "B", "C", "D", "E", "F", "G"], 2, 2) != ["A", "B", "C", "D", "E", "F", "G"]:
        raise SystemExit("same-slot move changed the plan")


def assert_week_pager_stays_free_until_drag(week_text: str) -> None:
    is_active = re.search(r"var isActive: Bool \{(?P<body>.*?)\n    \}", week_text, re.S)
    if is_active is None:
        raise SystemExit("WeekSlotDrag missing isActive")
    body = is_active.group("body")
    if "self != .inactive" in body or ".pressing, .dragging" in body or ".pressing,.dragging" in body:
        raise SystemExit("WeekSlotDrag.isActive treats press as a lift and locks the home pager")
    if ".dragging" not in body:
        raise SystemExit("WeekSlotDrag.isActive must be true only while dragging")
    if ".simultaneousGesture(slotGesture" not in week_text:
        raise SystemExit("slotGesture must be simultaneous so TabView can page")
    if re.search(r"\.gesture\(slotGesture", week_text):
        raise SystemExit("exclusive .gesture(slotGesture) blocks TabView paging")
    distance = re.search(r"DragGesture\(minimumDistance:\s*(\d+)", week_text)
    if distance is None:
        raise SystemExit("DragGesture must set minimumDistance")
    if int(distance.group(1)) < 10:
        raise SystemExit(
            f"DragGesture minimumDistance {distance.group(1)} is too low for page swipe"
        )


def assert_week_reorder_contract(week_text: str, store_text: str) -> None:
    banned_week = {
        "editMode": "WeekPlannerView still has editMode",
        ".onMove": "WeekPlannerView still has onMove",
        "draggable": "WeekPlannerView still has draggable",
        "dropDestination": "WeekPlannerView still has dropDestination",
        "draggableIfPresent": "WeekPlannerView still has draggableIfPresent",
        "Hold de tre strekene": "WeekPlannerView still has the three-bar copy",
        ".id(UUID())": "WeekPlannerView resets identity with UUID",
        "coordinateSpace: .local": "WeekPlannerView still drags in local tile space",
    }
    for needle, message in banned_week.items():
        if needle in week_text:
            raise SystemExit(message)
    if "List {" in week_text or "List(" in week_text:
        raise SystemExit("WeekPlannerView still has List")
    assert_week_pager_stays_free_until_drag(week_text)
    required_week = {
        "LongPressGesture": "WeekPlannerView missing LongPressGesture",
        "sequenced(before:": "WeekPlannerView missing sequenced drag",
        "DragGesture": "WeekPlannerView missing DragGesture",
        "@GestureState": "WeekPlannerView missing GestureState",
        "accessibilityReduceMotion": "WeekPlannerView missing Reduce Motion",
        "sensoryFeedback": "WeekPlannerView missing haptics",
        "coordinateSpace: .named": "WeekPlannerView must drag in a named board space",
        "WeekBoardDragActiveKey": "WeekPlannerView missing pager lock preference",
        "dropSettled": "WeekPlannerView must freeze the lift on drop",
    }
    for needle, message in required_week.items():
        if needle not in week_text:
            raise SystemExit(message)
    required_store = {
        "moveSlot": "WeekStore missing moveSlot",
        "remove(at:": "WeekStore missing remove(at:)",
        "insert(": "WeekStore missing insert",
    }
    for needle, message in required_store.items():
        if needle not in store_text:
            raise SystemExit(message)
    banned_store = {
        "fromOffsets": "WeekStore still has Array.move",
        "moveSlots": "WeekStore still has moveSlots",
        "swapAt": "WeekStore still has swapAt",
        "moveDish": "WeekStore still has moveDish",
    }
    for needle, message in banned_store.items():
        if needle in store_text:
            raise SystemExit(message)


def default_pool_path() -> Path:
    return Path(__file__).resolve().parent.parent / "KetoKasse" / "Features" / "Week" / "DishPool.swift"
