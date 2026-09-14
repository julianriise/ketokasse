#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
APP="$ROOT/KetoKasse"
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok  $*" ; }

test -f "$APP/Features/Onboarding/OnboardingState.swift" || fail "missing OnboardingState.swift"
test -f "$APP/Features/Onboarding/OnboardingFlow.swift" || fail "missing OnboardingFlow.swift"
test -f "$APP/Features/Onboarding/CookingFunView.swift" || fail "missing CookingFunView.swift"
test -f "$APP/Features/Onboarding/MealPlanWeekView.swift" || fail "missing MealPlanWeekView.swift"
test -f "$APP/Features/Onboarding/AskViews.swift" || fail "missing AskViews.swift"
test -f "$APP/Features/Onboarding/PricingView.swift" || fail "missing PricingView.swift"
test -f "$APP/Features/Home/HomePlaceholderView.swift" || fail "missing HomePlaceholderView.swift"
pass "files exist"

STEPS="$(python3 - "$APP/Features/Onboarding/OnboardingState.swift" <<'PY'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
block = re.search(r"enum OnboardingStep.*?\n\}", text, re.S)
if not block:
    raise SystemExit("OnboardingStep enum not found")
cases = re.findall(r"case (\w+)", block.group(0))
print(" ".join(cases))
PY
)"
[ "$STEPS" = "cooking mealPlan name goal deliveryDay pricing" ] || fail "step order is '$STEPS'"
pass "step order $STEPS"

python3 - "$APP" <<'PY' || fail "copy or wiring check"
import pathlib, re, sys
app = pathlib.Path(sys.argv[1])

def read(rel):
    return (app / rel).read_text()

welcome = read("Features/Welcome/WelcomeView.swift")
for needle in [
    "Den gøyeste måten å spise keto på",
    "KOM I GANG",
    "Ingen binding · Avslutt når som helst",
    "onContinue()",
]:
    if needle not in welcome:
        raise SystemExit(f"WelcomeView missing {needle!r}")

flow = read("Features/Onboarding/OnboardingFlow.swift")
if "WelcomeView(onContinue:" not in flow:
    raise SystemExit("OnboardingFlow does not start at Welcome")
if "path.append" not in flow:
    raise SystemExit("OnboardingFlow does not push steps")

content = read("ContentView.swift")
if '@AppStorage("onboardingComplete")' not in content:
    raise SystemExit("ContentView missing AppStorage onboardingComplete")
if "HomePlaceholderView" not in content:
    raise SystemExit("ContentView missing home gate")
if "OnboardingFlow" not in content:
    raise SystemExit("ContentView missing OnboardingFlow")

cooking = read("Features/Onboarding/CookingFunView.swift")
for needle in [
    "Matlaging skal være gøy",
    "Hakk grønnsakene",
    "Rør sausen",
    "Stek kjøttet",
    "Dette gjør matlaging gøy.",
    "carrot.fill",
    "fork.knife",
    "flame.fill",
]:
    if needle not in cooking:
        raise SystemExit(f"CookingFunView missing {needle!r}")

meals = read("Features/Onboarding/MealPlanWeekView.swift")
for needle in [
    "Fem middager på sju dager",
    "frossent kjøtt",
    "Laks og brokkoli",
    "Kylling i ovn",
    "Biff og asparges",
    "Torsk med smør",
    "Egg og bacon",
    "Fri",
    "swapMeals",
]:
    if needle not in meals:
        raise SystemExit(f"MealPlanWeekView missing {needle!r}")

ask = read("Features/Onboarding/AskViews.swift")
for needle in [
    "Hva skal vi kalle deg?",
    "Ola",
    "Hva er viktigst for deg?",
    "Når vil du ha kassen?",
    "ettermiddagen",
]:
    if needle not in ask:
        raise SystemExit(f"AskViews missing {needle!r}")

state = read("Features/Onboarding/OnboardingState.swift")
for needle in [
    "Gå ned i vekt",
    "Bli sterkere",
    "Overskudd i hverdagen",
    "Standard kvalitet",
    "Gårdskvalitet",
    "kr 1 490,–",
    "kr 2 290,–",
    "Man",
    "Søn",
]:
    if needle not in state:
        raise SystemExit(f"OnboardingState missing {needle!r}")

pricing = read("Features/Onboarding/PricingView.swift")
for needle in ["5 måltider for 2 personer", "FERDIG", "Samme kutt", "ikke mer i lomma"]:
    if needle not in pricing:
        raise SystemExit(f"PricingView missing {needle!r}")

home = read("Features/Home/HomePlaceholderView.swift")
if "Uka di er klar." not in home:
    raise SystemExit("HomePlaceholderView missing copy")

early = [
    "Features/Welcome/WelcomeView.swift",
    "Features/Onboarding/CookingFunView.swift",
    "Features/Onboarding/MealPlanWeekView.swift",
    "Features/Onboarding/AskViews.swift",
    "Features/Home/HomePlaceholderView.swift",
]
for rel in early:
    text = read(rel)
    if "1 490" in text or "2 290" in text or "1490" in text or "2290" in text:
        raise SystemExit(f"price leaked into {rel}")

root_swift = list(app.rglob("*.swift"))
for path in root_swift:
    text = path.read_text()
    if "StoreKit" in text or "import StoreKit" in text:
        raise SystemExit(f"StoreKit in {path}")
PY
pass "copy, wiring, prices last, no StoreKit"

echo "onboarding checks passed"
