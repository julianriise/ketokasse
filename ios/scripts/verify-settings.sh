#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
APP="$ROOT/KetoKasse"
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok  $*" ; }

test -f "$APP/Features/Settings/SettingsView.swift" || fail "missing SettingsView.swift"
test -f "$APP/Features/Onboarding/OnboardingState.swift" || fail "missing OnboardingState.swift"
test -f "$APP/Features/Home/HomeView.swift" || fail "missing HomeView.swift"
test -f "$APP/ContentView.swift" || fail "missing ContentView.swift"
pass "files exist"

python3 - "$APP" <<'PY' || fail "settings checks"
import pathlib, re, sys

app = pathlib.Path(sys.argv[1])

def read(rel):
    return (app / rel).read_text()

settings = read("Features/Settings/SettingsView.swift")
state = read("Features/Onboarding/OnboardingState.swift")
home = read("Features/Home/HomeView.swift")
content = read("ContentView.swift")
week = read("Features/Home/WeekPlannerView.swift")

if "struct Snapshot" not in state:
    raise SystemExit("OnboardingState missing nested Snapshot")
if '"kk.onboardingAnswers"' not in state:
    raise SystemExit("OnboardingState missing kk.onboardingAnswers key")
if "JSONEncoder" not in state:
    raise SystemExit("OnboardingState missing JSONEncoder")
if "JSONDecoder" not in state:
    raise SystemExit("OnboardingState missing JSONDecoder")
if "func reset(" not in state:
    raise SystemExit("OnboardingState missing reset()")
if "init(defaults:" not in state:
    raise SystemExit("OnboardingState missing init(defaults:)")
if "UserDefaults" not in state:
    raise SystemExit("OnboardingState missing UserDefaults")

for needle in [
    r"enum OnboardingGoal:[^\n]*Codable",
    r"enum AllergyCategory:[^\n]*Codable",
    r"enum AllergyAnswer:[^\n]*Codable",
    r"enum HousingKind:[^\n]*Codable",
    r"enum FamilyRole:[^\n]*Codable",
    r"struct FamilyMember:[^\n]*Codable",
    r"enum MealPlan:[^\n]*Codable",
]:
    if not re.search(needle, state):
        raise SystemExit(f"missing Codable: {needle}")

snapshot = re.search(r"struct Snapshot:[^\n]*\{.*?\n    \}", state, re.S)
if not snapshot:
    raise SystemExit("Snapshot struct body not found")
snap = snapshot.group(0)
if "Codable" not in snap.split("{", 1)[0] or "Equatable" not in snap.split("{", 1)[0]:
    raise SystemExit("Snapshot must be Codable, Equatable")
for field in ["goal", "allergies", "housing", "floor", "family", "plan"]:
    if field not in snap:
        raise SystemExit(f"Snapshot missing {field}")
if "onboardingComplete" in snap:
    raise SystemExit("Snapshot must not persist onboardingComplete")

if "DeliveryWeekday" in state or "DeliveryWeekday" in settings:
    raise SystemExit("DeliveryWeekday resurrected")

for section in ["Husstand", "Mål", "Allergier", "Bolig", "Start på nytt"]:
    if section not in settings:
        raise SystemExit(f"SettingsView missing {section!r}")
if "Plan" not in settings and "kvalitet" not in settings and "Kvalitet" not in settings:
    raise SystemExit("SettingsView missing Plan/kvalitet section")
if "addFamilyMember" not in settings:
    raise SystemExit("SettingsView must use addFamilyMember")
if "removeFamilyMember" not in settings:
    raise SystemExit("SettingsView must use removeFamilyMember")
if "selectNoAllergies" not in settings:
    raise SystemExit("SettingsView must use selectNoAllergies")
if "toggleAllergy" not in settings:
    raise SystemExit("SettingsView must use toggleAllergy")
if "confirmationDialog" not in settings:
    raise SystemExit("SettingsView missing confirmationDialog")
if "NavigationStack" not in settings:
    raise SystemExit("SettingsView missing NavigationStack")
if 'navigationTitle("Innstillinger")' not in settings:
    raise SystemExit("SettingsView missing navigationTitle Innstillinger")
if "StoreKit" in settings:
    raise SystemExit("StoreKit in SettingsView")

for dead in ["draggableIfPresent", "dropDestination", "WeekPlannerView", "WeekStore", "moveDish"]:
    if dead in settings:
        raise SystemExit(f"SettingsView must not use week drag API {dead}")

if "Start på nytt" in home:
    raise SystemExit("HomeView still has Start på nytt")
if 'accessibilityLabel("Innstillinger")' not in home:
    raise SystemExit("Home missing Innstillinger accessibilityLabel")
if "gearshape" not in home:
    raise SystemExit("Home missing settings gear")
if "answers.primaryName" not in home:
    raise SystemExit("HomeView does not greet with answers.primaryName")
if "@Bindable var answers" not in home:
    raise SystemExit("Home must take Bindable answers")
if "SettingsView" not in home:
    raise SystemExit("Home must present SettingsView")
if "NavigationStack" not in home:
    raise SystemExit("Home entry must use NavigationStack")

if "WeekPlannerView()" not in home:
    raise SystemExit("HomeShellView must still host WeekPlannerView")
if re.search(r"NavigationStack\s*\{[^}]*WeekPlannerView", home, re.S):
    raise SystemExit("WeekPlannerView must not be wrapped in new NavigationStack chrome")

if "HomeShellView(answers:" not in content:
    raise SystemExit("ContentView must pass answers into HomeShellView")
if "answers.reset()" not in content:
    raise SystemExit("ContentView restart must call answers.reset()")
if "onboardingComplete = false" not in content:
    raise SystemExit("ContentView restart must clear onboardingComplete")
if "restartOnboarding" not in content:
    raise SystemExit("ContentView missing restartOnboarding")

if "List" not in week or ".onMove" not in week or "editMode" not in week:
    raise SystemExit("WeekPlannerView native onMove was broken")
if "draggable" in week or "dropDestination" in week or "draggableIfPresent" in week:
    raise SystemExit("WeekPlannerView still has custom drag")

root_swift = list(app.rglob("*.swift"))
for path in root_swift:
    text = path.read_text()
    if "StoreKit" in text or "import StoreKit" in text:
        raise SystemExit(f"StoreKit in {path}")
    if "DeliveryWeekday" in text:
        raise SystemExit(f"DeliveryWeekday in {path}")
PY
pass "settings persistence, chrome, and wiring"

echo "settings checks passed"
