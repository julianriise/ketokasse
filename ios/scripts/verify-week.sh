#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
APP="$ROOT/KetoKasse"
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok  $*" ; }

test -f "$APP/Features/Week/DishPool.swift" || fail "missing DishPool.swift"
test -f "$APP/Features/Week/WeekPlanner.swift" || fail "missing WeekPlanner.swift"
test -f "$APP/Features/Week/WeekStore.swift" || fail "missing WeekStore.swift"
test -f "$APP/Features/Home/HomeView.swift" || fail "missing HomeView.swift"
test -f "$APP/Features/Home/WeekPlannerView.swift" || fail "missing WeekPlannerView.swift"
! test -e "$APP/Features/Home/HomePlaceholderView.swift" || fail "HomePlaceholderView.swift must be gone"
pass "files exist"

python3 - "$ROOT" <<'PY' || fail "week planner checks"
import pathlib, sys

root = pathlib.Path(sys.argv[1])
sys.path.insert(0, str(root / "scripts"))
from week_planner import (
    DINNER_COUNT,
    PIZZA_TITLE,
    assert_move_slot_behavior,
    assert_week_reorder_contract,
    filled_titles,
    generate,
    parse_pizza_title,
    parse_pool,
    proteins_are_valid,
)

pool_text = (root / "KetoKasse/Features/Week/DishPool.swift").read_text()
planner_text = (root / "KetoKasse/Features/Week/WeekPlanner.swift").read_text()
store_text = (root / "KetoKasse/Features/Week/WeekStore.swift").read_text()
home_text = (root / "KetoKasse/Features/Home/HomeView.swift").read_text()
week_text = (root / "KetoKasse/Features/Home/WeekPlannerView.swift").read_text()
content = (root / "KetoKasse/ContentView.swift").read_text()

EXPECTED_TITLES = [
    "Squash-lasagne",
    "Chilistekte tigerreker med brokkolimos",
    "Cheeseburgerform",
    "Koteletter med blomkålmos",
    "Kyllingpizza med mozzarella og basilikum",
    "Meksikansk form med kylling",
    "Tigerreke-taco",
    "Fiskegrateng keto",
    "Kremet lakseform",
    "Eggeform med bacon og ost",
]
pool = parse_pool(pool_text)
if len(pool) != 10:
    raise SystemExit(f"pool size {len(pool)}, expected 10")
titles = [dish.title for dish in pool]
if titles != EXPECTED_TITLES:
    raise SystemExit(f"pool titles {titles}")
if len(set(titles)) != 10:
    raise SystemExit("pool titles are not unique")
pizza_title = parse_pizza_title(pool_text)
if pizza_title != PIZZA_TITLE:
    raise SystemExit(f"pizzaTitle {pizza_title!r}")
if pizza_title not in titles:
    raise SystemExit("pizza missing from pool")
if "Kyllingpizza med mozzarella og basilikum" not in planner_text and "DishPool.pizzaTitle" not in planner_text:
    raise SystemExit("WeekPlanner does not pin pizza")
if "simulateNewWeek" not in store_text:
    raise SystemExit("WeekStore missing simulateNewWeek")
if "Simuler ny uke" not in week_text:
    raise SystemExit("WeekPlannerView missing Simuler ny uke")
if "Start middag" not in home_text:
    raise SystemExit("HomeView missing Start middag")
if "HomeShellView" not in content:
    raise SystemExit("ContentView missing HomeShellView")
assert_week_reorder_contract(week_text, store_text)
assert_move_slot_behavior()

by_title = {dish.title: dish for dish in pool}

def as_dishes(slots):
    return [None if title is None else by_title[title] for title in slots]

first = generate(1, set(), pool)
if PIZZA_TITLE not in filled_titles(first):
    raise SystemExit("seed 1 omitted pizza")
if filled_titles(first).count(PIZZA_TITLE) != 1:
    raise SystemExit("pizza appeared more than once")
if len(filled_titles(first)) != DINNER_COUNT:
    raise SystemExit("seed 1 filled count")
if first.count(None) != 2:
    raise SystemExit("seed 1 empty count")
if not proteins_are_valid(as_dishes(first)):
    raise SystemExit("seed 1 adjacent protein")
if generate(1, set(), pool) != first:
    raise SystemExit("seed 1 is not deterministic")

second = generate(2, set(filled_titles(first)), pool)
if PIZZA_TITLE not in filled_titles(second):
    raise SystemExit("simulated week omitted pizza")
if len(filled_titles(second)) != DINNER_COUNT or second.count(None) != 2:
    raise SystemExit("simulated week slot counts")
if not proteins_are_valid(as_dishes(second)):
    raise SystemExit("simulated week adjacent protein")
if second == first:
    raise SystemExit("Simuler ny uke did not change the plan")

overlap = set(filled_titles(first)) & set(filled_titles(second))
if overlap != {PIZZA_TITLE}:
    raise SystemExit(f"variation failed, overlap={overlap}")

for seed in range(3, 41):
    slots = generate(seed, set(), pool)
    if PIZZA_TITLE not in filled_titles(slots):
        raise SystemExit(f"seed {seed} omitted pizza")
    if len(filled_titles(slots)) != DINNER_COUNT or slots.count(None) != 2:
        raise SystemExit(f"seed {seed} slot counts")
    if not proteins_are_valid(as_dishes(slots)):
        raise SystemExit(f"seed {seed} adjacent protein")

print("ok  pool 10, pizza pinned, 5/2 slots, proteins, simulate changes")
PY
