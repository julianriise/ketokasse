#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
APP="$ROOT/KetoKasse"
WEB="$(CDPATH= cd -- "$(dirname "$0")/../../web" && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok  $*" ; }

test -f "$APP/Features/Auth/AuthGateView.swift" || fail "missing AuthGateView.swift"
test -f "$APP/Features/Auth/JoinHouseholdView.swift" || fail "missing JoinHouseholdView.swift"
test -f "$APP/Features/Settings/ShareHouseholdView.swift" || fail "missing ShareHouseholdView.swift"
test -f "$APP/Services/AuthService.swift" || fail "missing AuthService.swift"
test -f "$APP/Services/HouseholdRepository.swift" || fail "missing HouseholdRepository.swift"
test -f "$APP/Services/SupabaseClient+App.swift" || fail "missing SupabaseClient+App.swift"
test -f "$WEB/src/app/join/[token]/page.tsx" || fail "missing web join/[token] page"
pass "files exist"

python3 - "$APP" "$WEB" <<'PY' || fail "auth wiring checks"
import pathlib, sys

app = pathlib.Path(sys.argv[1])
web = pathlib.Path(sys.argv[2])

def read(path):
    return path.read_text()

content = read(app / "ContentView.swift")
info = read(app / "Info.plist")
auth = read(app / "Features/Auth/AuthGateView.swift")
settings = read(app / "Features/Settings/SettingsView.swift")
share = read(app / "Features/Settings/ShareHouseholdView.swift")
repo = read(app / "Services/HouseholdRepository.swift")
week = read(app / "Features/Week/WeekStore.swift")
points = read(app / "Features/Cooking/PointsStore.swift")
session = read(app / "Features/Cooking/CookingSession.swift")
app_entry = read(app / "KetoKasseApp.swift")
join_web = read(web / "src/app/join/[token]/page.tsx")

if "AuthGateView" not in content:
    raise SystemExit("ContentView missing AuthGateView")
if "ensure_own_household" not in repo:
    raise SystemExit("HouseholdRepository missing ensure_own_household")
if "create_invite" not in repo:
    raise SystemExit("HouseholdRepository missing create_invite")
if "redeem_invite" not in repo:
    raise SystemExit("HouseholdRepository missing redeem_invite")
if "ketokasse" not in info:
    raise SystemExit("Info.plist missing ketokasse URL scheme")
if "SUPABASE_URL" not in info or "SUPABASE_ANON_KEY" not in info:
    raise SystemExit("Info.plist missing Supabase keys")
if "onOpenURL" not in app_entry:
    raise SystemExit("App missing onOpenURL")
if "Del med partner" not in settings:
    raise SystemExit("Settings missing Del med partner")
if "ShareHouseholdView" not in settings:
    raise SystemExit("Settings missing ShareHouseholdView")
if "CIFilter.qrCodeGenerator" not in read(app / "Services/QRCodeImage.swift"):
    raise SystemExit("QR generator missing")
if "ketokasse-site.vercel.app/join" not in share and "InviteURL.webJoin" not in share:
    raise SystemExit("Share view missing invite URL")
if "syncRemote" not in week or "syncRemote" not in points:
    raise SystemExit("stores missing syncRemote")
if "cook_events" not in repo:
    raise SystemExit("repository missing cook_events")
if "commit(to" not in session:
    raise SystemExit("CookingSession missing commit(to")
auth_service = read(app / "Services/AuthService.swift")
if "signInWithOTP" not in auth_service:
    raise SystemExit("AuthService missing signInWithOTP")
send = auth_service.split("func sendMagicLink", 1)[-1].split("func ", 1)[0]
if "emailLockRemaining" not in send.split("signInWithOTP")[0]:
    raise SystemExit("sendMagicLink must refuse OTP while the email lock is active")
if "ketokasse://join/" not in join_web:
    raise SystemExit("join page missing app deep link")
if "Åpne i Ketokasse" not in join_web:
    raise SystemExit("join page missing CTA copy")
if "delete_own_account" not in repo:
    raise SystemExit("HouseholdRepository missing delete_own_account")
if "Slett konto" not in settings:
    raise SystemExit("Settings missing Slett konto")
if "Er du sikker?" not in settings:
    raise SystemExit("Settings missing delete confirmation")
print("ok  auth gate, RPCs, QR share, stores, web join")
PY
pass "auth wiring"

echo "auth checks passed"
