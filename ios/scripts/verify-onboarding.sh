#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
APP="$ROOT/KetoKasse"
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok  $*" ; }

test -f "$APP/Features/Onboarding/OnboardingState.swift" || fail "missing OnboardingState.swift"
test -f "$APP/Features/Onboarding/OnboardingFlow.swift" || fail "missing OnboardingFlow.swift"
test -f "$APP/Features/Onboarding/OnboardingChrome.swift" || fail "missing OnboardingChrome.swift"
test -f "$APP/Features/Onboarding/CookingFunView.swift" || fail "missing CookingFunView.swift"
test -f "$APP/Features/Onboarding/AskViews.swift" || fail "missing AskViews.swift"
test -f "$APP/Features/Onboarding/PricingView.swift" || fail "missing PricingView.swift"
test -f "$APP/Features/Welcome/SpeechBubbleView.swift" || fail "missing SpeechBubbleView.swift"
test -f "$APP/Features/Home/HomeView.swift" || fail "missing HomeView.swift"
test -f "$APP/Features/Home/WeekPlannerView.swift" || fail "missing WeekPlannerView.swift"
! test -e "$APP/Features/Home/HomePlaceholderView.swift" || fail "HomePlaceholderView.swift must be gone"
! test -e "$APP/Features/Onboarding/MealPlanWeekView.swift" || fail "MealPlanWeekView.swift must be gone"
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
[ "$STEPS" = "cooking goal allergies address household pricing" ] || fail "step order is '$STEPS'"
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
    "SpeechBubbleView(text: copy.headline",
    "OnboardingStickyFooter",
    "tail: .bottom",
    "KKMotion.mascotHero",
]:
    if needle not in welcome:
        raise SystemExit(f"WelcomeView missing {needle!r}")
if "skyCircle" in welcome:
    raise SystemExit("WelcomeView still draws a sky circle")
if "KKFont.headline" in welcome:
    raise SystemExit("WelcomeView still uses headline outside the bubble")

flow = read("Features/Onboarding/OnboardingFlow.swift")
if "WelcomeView(onContinue:" not in flow:
    raise SystemExit("OnboardingFlow does not start at Welcome")
if "path.append" not in flow:
    raise SystemExit("OnboardingFlow does not push steps")
for dead in ["MealPlanWeekView", "NameAskView", "DeliveryDayAskView", ".mealPlan", ".deliveryDay", ".name"]:
    if dead in flow:
        raise SystemExit(f"OnboardingFlow still references {dead!r}")
for live in [
    "CookingFunView",
    "GoalAskView",
    "AllergiesAskView",
    "AddressAskView",
    "HouseholdAskView",
    "PricingView",
]:
    if live not in flow:
        raise SystemExit(f"OnboardingFlow missing {live}")
if "struct OnboardingChrome" in flow:
    raise SystemExit("OnboardingChrome must live in OnboardingChrome.swift")

content = read("ContentView.swift")
if '@AppStorage("onboardingComplete")' not in content:
    raise SystemExit("ContentView missing AppStorage onboardingComplete")
if "HomeShellView" not in content:
    raise SystemExit("ContentView missing home gate")
if "HomePlaceholderView" in content:
    raise SystemExit("ContentView still references HomePlaceholderView")
if "OnboardingFlow" not in content:
    raise SystemExit("ContentView missing OnboardingFlow")
if "restartOnboarding" not in content:
    raise SystemExit("ContentView missing restartOnboarding")
if "answers.reset()" not in content:
    raise SystemExit("ContentView restart does not call answers.reset()")
if "onboardingComplete = false" not in content:
    raise SystemExit("ContentView does not clear onboardingComplete on restart")
if "HomeShellView(answers:" not in content:
    raise SystemExit("ContentView must pass answers into HomeShellView")
if "answers.name" in content:
    raise SystemExit("ContentView still reads answers.name")

cooking = read("Features/Onboarding/CookingFunView.swift")
for needle in [
    "Matlaging skal være gøy",
    "Hakk, rør og stek.",
    "Hakk grønnsakene",
    "Rør sausen",
    "Stek kjøttet",
    "carrot.fill",
    "fork.knife",
    "flame.fill",
    'bubbleText: "Matlaging skal være gøy"',
    "step: .cooking",
]:
    if needle not in cooking:
        raise SystemExit(f"CookingFunView missing {needle!r}")
for fluff in ["Dette gjør matlaging gøy.", "Neste steg", "Maskoten følger deg", "skyCircle", "MascotView"]:
    if fluff in cooking:
        raise SystemExit(f"CookingFunView still has fluff {fluff!r}")

ask = read("Features/Onboarding/AskViews.swift")
for needle in [
    "Hva er viktigst?",
    "Allergier",
    "Ingen",
    "Hvor bor du?",
    "Etasje",
    "Hvem bor her?",
    "Navn",
    "Legg til",
    "Fjern",
    "FamilyRole.allCases",
    "FamilyRoleAvatar",
    "selectNoAllergies",
    "toggleAllergy",
    'bubbleText: "Hva er viktigst?"',
    'bubbleText: "Allergier"',
    'bubbleText: "Hvor bor du?"',
    'bubbleText: "Hvem bor her?"',
    "step: .goal",
    "step: .allergies",
    "step: .address",
    "step: .household",
]:
    if needle not in ask:
        raise SystemExit(f"AskViews missing {needle!r}")
if "ForEach(answers.family)" not in ask:
    raise SystemExit("household member ForEach missing")
if "MemberChip" not in ask:
    raise SystemExit("MemberChip missing")
if "ScrollView(.horizontal)" in ask:
    raise SystemExit("household member chips still scroll horizontally")
for dead in [
    "Hva skal vi kalle deg?",
    "Hva er viktigst for deg?",
    "Når vil du ha kassen?",
    "ettermiddagen",
    "Ola",
    "Legg til familie",
    "Personlighet",
    "Personality",
    "shippingbox",
    "Voksen",
]:
    if dead in ask:
        raise SystemExit(f"AskViews still has {dead!r}")

state = read("Features/Onboarding/OnboardingState.swift")
for needle in [
    "Gå ned i vekt",
    "Bli sterkere",
    "Overskudd i hverdagen",
    "Nøtter",
    "Sitrusfrukt",
    "Gluten",
    "Egg",
    "Meieri",
    "Skalldyr",
    "Soya",
    "Sesam",
    "Leilighet",
    "Tomannsbolig",
    "Rekkehus/enebolig",
    "Mann",
    "Dame",
    "Barn",
    "Baby",
    "primaryName",
    "Standard kvalitet",
    "Gårdskvalitet",
    "kr 1 490,–",
    "kr 2 290,–",
    "case noAllergies",
    "needsFloor",
    "var progress: Double",
]:
    if needle not in state:
        raise SystemExit(f"OnboardingState missing {needle!r}")
answer = re.search(r"enum AllergyAnswer.*?\n\}", state, re.S)
if not answer:
    raise SystemExit("AllergyAnswer missing")
if "case none" in answer.group(0):
    raise SystemExit("AllergyAnswer case none clashes with Optional.none")
if "case noAllergies" not in answer.group(0):
    raise SystemExit("AllergyAnswer missing case noAllergies")
for dead in ["DeliveryWeekday", "case mealPlan", "case deliveryDay", "case name", "enum Personality", "var personality", "Voksen", "case adult"]:
    if dead in state:
        raise SystemExit(f"OnboardingState still has {dead!r}")
if re.search(r"final class OnboardingState[^{]*\{[^}]*\bvar name\b", state, re.S):
    raise SystemExit("OnboardingState still has a name field")
if "addFamilyMember(name:" not in state:
    raise SystemExit("addFamilyMember must take a name")

can_continue = re.search(r"func canContinue.*", state, re.S)
if not can_continue:
    raise SystemExit("canContinue missing")
for step in ["cooking", "goal", "allergies", "address", "household", "pricing"]:
    if f"case .{step}" not in can_continue.group(0):
        raise SystemExit(f"canContinue missing .{step}")
household_gate = re.search(r"case \.household:\s*(.*?)case \.pricing", can_continue.group(0), re.S)
if not household_gate:
    raise SystemExit("canContinue household case missing")
if "family" not in household_gate.group(1):
    raise SystemExit("canContinue(.household) does not check family")
if "personality" in household_gate.group(1):
    raise SystemExit("canContinue(.household) still uses personality")

pricing = read("Features/Onboarding/PricingView.swift")
for needle in [
    "5 måltider for 2",
    "FERDIG",
    "Samme kutt",
    "ikke mer i lomma",
    'bubbleText: "Sånn! Velg kvalitet."',
    "step: .pricing",
]:
    if needle not in pricing:
        raise SystemExit(f"PricingView missing {needle!r}")

chrome = read("Features/Onboarding/OnboardingChrome.swift")
for needle in [
    "var bubbleText: String",
    "OnboardingProgressBar",
    "SpeechBubbleView",
    "OnboardingStickyFooter",
    "MascotView",
    "KKColor.line",
    "KKColor.forest",
    "chevron.left",
    "GetStartedButton",
    "step.progress",
    "tail: .leading",
    "KKMotion.mascotCoach",
    "frame(height: 1)",
]:
    if needle not in chrome:
        raise SystemExit(f"OnboardingChrome missing {needle!r}")
if "KKFont.headline" in chrome:
    raise SystemExit("OnboardingChrome still uses headline as the step title")
if "safeAreaInset" in chrome:
    raise SystemExit("OnboardingChrome still overlays the CTA with safeAreaInset")

bubble = read("Features/Welcome/SpeechBubbleView.swift")
for needle in [
    "struct SpeechBubbleView",
    "struct TypewriterText",
    "accessibilityReduceMotion",
    "split(whereSeparator:",
    "accessibilityLabel(text)",
    "Task.sleep",
    "KKColor.line",
    "case leading",
    "case bottom",
]:
    if needle not in bubble:
        raise SystemExit(f"SpeechBubbleView missing {needle!r}")
if "milliseconds(80)" not in bubble:
    raise SystemExit("TypewriterText is not revealing word by word")

motion = read("DesignSystem/Motion.swift")
if "mascotHero" not in motion or "mascotCoach" not in motion:
    raise SystemExit("KKMotion missing mascotHero/mascotCoach sizes")
if "skyCircle" in motion:
    raise SystemExit("KKMotion still has skyCircle")

home = read("Features/Home/HomeView.swift")
if "Uka di er klar." in home:
    raise SystemExit("HomeView still has placeholder copy")
if "Start på nytt" in home:
    raise SystemExit("HomeView must not contain Start på nytt")
if "onRestart" not in home:
    raise SystemExit("HomeShellView missing onRestart")
if "Start middag" not in home:
    raise SystemExit("HomeView missing dinner CTA")
if "Hei," not in home:
    raise SystemExit("HomeView missing named greeting")
if "answers.primaryName" not in home:
    raise SystemExit("HomeView does not greet with answers.primaryName")
if 'accessibilityLabel("Innstillinger")' not in home:
    raise SystemExit("Home missing Innstillinger accessibilityLabel")
if "gearshape" not in home:
    raise SystemExit("Home missing settings gear")
if "HomeShellView" not in home:
    raise SystemExit("HomeView missing HomeShellView")
week = read("Features/Home/WeekPlannerView.swift")
if "Simuler ny uke" not in week:
    raise SystemExit("WeekPlannerView missing Simuler ny uke")

early = [
    "Features/Welcome/WelcomeView.swift",
    "Features/Onboarding/CookingFunView.swift",
    "Features/Onboarding/AskViews.swift",
    "Features/Home/HomeView.swift",
    "Features/Home/WeekPlannerView.swift",
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
    if "MealPlanWeekView" in text:
        raise SystemExit(f"MealPlanWeekView still referenced in {path}")
PY
pass "copy, wiring, prices last, no StoreKit"

echo "onboarding checks passed"
