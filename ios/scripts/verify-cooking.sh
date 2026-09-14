#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
APP="$ROOT/KetoKasse"
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok  $*" ; }

test -f "$APP/Features/Cooking/Recipe.swift" || fail "missing Recipe.swift"
test -f "$APP/Features/Cooking/RecipeRegistry.swift" || fail "missing RecipeRegistry.swift"
test -f "$APP/Features/Cooking/CookingSession.swift" || fail "missing CookingSession.swift"
test -f "$APP/Features/Cooking/PointsStore.swift" || fail "missing PointsStore.swift"
test -f "$APP/Features/Cooking/CookingSessionView.swift" || fail "missing CookingSessionView.swift"
! grep -R --include='*.swift' -n "CookingStubView" "$APP" >/dev/null || fail "CookingStubView must be gone"
pass "files exist"

python3 - "$APP" <<'PY' || fail "cooking schema checks"
import pathlib, re, sys

app = pathlib.Path(sys.argv[1])

def read(rel):
    return (app / rel).read_text()

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

pool = read("Features/Week/DishPool.swift")
registry = read("Features/Cooking/RecipeRegistry.swift")
recipe = read("Features/Cooking/Recipe.swift")
session = read("Features/Cooking/CookingSession.swift")
points = read("Features/Cooking/PointsStore.swift")
cook_view = read("Features/Cooking/CookingSessionView.swift")
home = read("Features/Home/HomeView.swift")
content = read("ContentView.swift")
week = read("Features/Home/WeekPlannerView.swift")
store = read("Features/Week/WeekStore.swift")

pool_titles = re.findall(r'Dish\(title: "([^"]+)"', pool)
if pool_titles != EXPECTED_TITLES:
    raise SystemExit(f"DishPool titles {pool_titles}")

reg_titles = re.findall(r'dishTitle: "([^"]+)"', registry)
if reg_titles != EXPECTED_TITLES:
    raise SystemExit(f"RecipeRegistry titles {reg_titles}")
if len(set(reg_titles)) != 10:
    raise SystemExit("RecipeRegistry titles are not unique")

for title in EXPECTED_TITLES:
    if f'dishTitle: "{title}"' not in registry:
        raise SystemExit(f"registry missing {title}")

for kind in ["gatherItem", "prepTask", "cookTask", "serveNote"]:
    if f"case {kind}" not in recipe:
        raise SystemExit(f"RecipeStepKind missing {kind}")

for phase in ["gather", "prep", "cook", "serve", "score"]:
    if f"case {phase}" not in recipe:
        raise SystemExit(f"RecipePhase missing {phase}")

for field in ["gather", "prep", "cook", "serve", "points", "symbolName"]:
    if field not in recipe:
        raise SystemExit(f"Recipe schema missing {field}")

if "static func recipe(forDishTitle" not in registry:
    raise SystemExit("RecipeRegistry missing recipe(forDishTitle:)")
if "Step.gather" not in registry or "Step.prep" not in registry:
    raise SystemExit("RecipeRegistry missing gather/prep helpers")
if "Step.cook" not in registry or "Step.serve" not in registry:
    raise SystemExit("RecipeRegistry missing cook/serve helpers")

if '"kk.pointsStore"' not in points:
    raise SystemExit("PointsStore missing kk.pointsStore key")
if "JSONEncoder" not in points or "JSONDecoder" not in points:
    raise SystemExit("PointsStore missing JSON persist")
if "func add(" not in points:
    raise SystemExit("PointsStore missing add")
if "init(defaults:" not in points:
    raise SystemExit("PointsStore missing init(defaults:)")

if "skipRemainingGather" not in session:
    raise SystemExit("CookingSession missing skipRemainingGather")
if "commit(to" not in session:
    raise SystemExit("CookingSession missing commit(to:)")
if "toggleFound" not in session:
    raise SystemExit("CookingSession missing toggleFound")
if "didCommit" not in session:
    raise SystemExit("CookingSession missing didCommit guard")

if "CookingStubView" in home or "CookingStubView" in cook_view:
    raise SystemExit("CookingStubView still referenced")
if "fullScreenCover" not in home:
    raise SystemExit("Home missing fullScreenCover cooking session")
if "CookingSessionView" not in home:
    raise SystemExit("Home missing CookingSessionView")
if "star.fill" not in home:
    raise SystemExit("Home missing points badge")
if "points.total" not in home:
    raise SystemExit("Home does not read PointsStore.total")
if "Hopp over" not in cook_view:
    raise SystemExit("Gather phase missing Hopp over skip")
if "Bra jobba" not in cook_view:
    raise SystemExit("Scorecard missing Bra jobba")
if "Finn ingrediensene" not in cook_view:
    raise SystemExit("Gather phase missing Finn ingrediensene")

if "PointsStore()" not in content:
    raise SystemExit("ContentView missing PointsStore")
if ".environment(pointsStore)" not in content:
    raise SystemExit("ContentView does not inject PointsStore")

if "List" not in week or ".onMove" not in week or "editMode" not in week:
    raise SystemExit("native List.onMove was lost")
if "draggable" in week or "dropDestination" in week:
    raise SystemExit("custom drag returned")
if "moveSlots" not in store or "fromOffsets" not in store:
    raise SystemExit("WeekStore.moveSlots was lost")
if "moveDish" in store or "swapAt" in store:
    raise SystemExit("WeekStore swap path returned")

swift = list(app.rglob("*.swift"))
for path in swift:
    text = path.read_text()
    if "CookingStubView" in text:
        raise SystemExit(f"CookingStubView in {path}")
    if "StoreKit" in text or "import StoreKit" in text:
        raise SystemExit(f"StoreKit in {path}")

print("ok  10 recipes keyed to DishPool, points persist, stub gone, onMove kept")
PY
pass "cooking schema, registry, points, stub gone"
echo "cooking checks passed"
