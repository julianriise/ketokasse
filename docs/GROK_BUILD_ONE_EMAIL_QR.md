# Grok Build Plan — One email per household + QR device pair + Netflix-style avatars

**Status:** Product direction change vs current “two emails join one household.”  
**Code owner:** local grok build (`ios/` + `web/`).  
**Cloud owner:** Oskar (Supabase schema/RPCs, Auth, Vercel/AASA).

## Answers up front

### Does Anna need the app installed before scanning?
**With today’s build:** yes. The QR is an invite into *her own* login. She needs the app (or the https join page → install → open deep link), then her magic link, then redeem.

**With this new plan:** she still needs the **app binary** on the phone to use an in-app camera / deep link. She does **not** need a second email. Flow:

1. Julian shows QR from Settings → Del.
2. Anna installs from App Store if needed (join web page can say «Last ned» then «Åpne kamera i appen»).
3. On AuthGate she taps **Skann QR** → camera → pairs into Julian’s household session/device access.
4. She picks her **avatar** (household profile), Netflix-style.

Universal Links / AASA make Camera/Safari open the app directly; without AASA, https join page → «Åpne i Ketokasse» is enough.

---

## Product goal

- **One email per household** (Julian’s). Less friction.
- Second phone joins via **QR**, not a second magic link.
- After pair (or after email login), show a **profile picker** (existing household members / avatars). Active profile is who “cooked” and whose face shows in UI.
- Shared week plan + points stay on the **household** (unchanged).

---

## Mental model (Netflix, not Slack)

| Concept | Meaning |
|--------|---------|
| Household account | One Supabase `auth.users` row (email magic link) |
| Device | Phone that may access that household after login or QR pair |
| Profile / avatar | Named member (mann/dame/barn/…) — **not** a separate login |
| Active profile | Local (+ synced) choice on this device |

Do **not** auto “sign her into Julian’s user” by stuffing a long-lived password into the QR. Use a **short-lived device pairing token** that grants this device access to the household.

---

## AuthGate UX (first screen)

**Layout:** hero mascot + bubble + sticky area.

Bubble: «Logg inn med e-post, eller skann husholdningens QR.»

**Primary path — E-post**
- Email field + sticky «SEND LENKE» (existing magic link).
- After link: celebrate → FORTSETT → **profile picker** (if ≥1 profile) → onboarding/home as today.

**Secondary path — Skann QR**
- Text button / secondary sticky: «SKANN QR».
- Opens in-app camera (`AVCaptureMetadataOutput` for QR).
- Accepts:
  - `ketokasse://pair/<token>`
  - `https://ketokasse-site.vercel.app/pair/<token>` (and legacy `/join/<token>` redirected to pair)
- On success → profile picker → home.
- On failure → bubble with real error (expired / used / offline).

No second email field on the scan path.

---

## Profile picker (Netflix rail)

**When:** after email session **or** successful QR pair; whenever `active_profile_id` is missing.

**Content:** household profiles as large tappable avatars (reuse mann/dame/barn/baby art).  
**CTA:** none until pick; tap avatar continues.  
**Settings later:** «Bytt profil» returns here without signing out.

Cook events / UI attribution use `active_profile_id` (and still store `cooked_by` device user id if useful for audit).

---

## Share QR (Julian’s phone)

Settings → Del med partner:

- QR encodes **pair** URL with one-time/short-lived token (7 days max, single-use preferred).
- Copy link + LAG NY KODE (same as now).
- Helper: «Partner trenger appen. Ingen ekstra e-post.»

Deprecate “second email redeem_invite” as the primary story; can keep RPC for a while for compat or replace with `create_device_pair` / `redeem_device_pair`.

---

## Backend shape (Oskar applies when you greenlight)

Suggested tables (names flexible):

```text
household_profiles
  id, household_id, display_name, role/avatar_kind, sort_index, created_at
  -- seed from existing onboarding family members

device_pairs
  id, household_id, token, created_by (auth user), expires_at, redeemed_at, redeemed_device_id

devices
  id, household_id, auth_user_id, label, last_active_at, active_profile_id
```

**Pairing strategy (pick one — recommend A):**

### A — Anonymous auth + attach (preferred)
1. QR redeem: app calls `signInAnonymously()` (or custom “device” user created by Edge Function).
2. RPC `redeem_device_pair(token)` inserts `household_members` (role `member`) for that auth id + `devices` row.
3. RLS unchanged: member of household can read week/points.
4. Profile picker sets `devices.active_profile_id`.

### B — Session handoff QR (avoid for v1)
QR contains a one-time refresh/session fragment. Higher risk if screenshot leaks; only if A is too heavy.

**Migrate from current two-email model**
- Julian stays owner email user.
- Anna’s separate email membership (if any) can be ignored or deleted after she re-pairs as device.
- Seed `household_profiles` from onboarding household answers already on device / in prefs.

RPCs for grok build to call:

- `create_device_pair()` → token, expires_at  
- `redeem_device_pair(token)` → household_id  
- `list_household_profiles()`  
- `set_active_profile(profile_id)`  

Oskar implements migrations + grants (authenticated / anon-as-needed carefully).

---

## Web

- `web/src/app/pair/[token]/page.tsx` (or evolve `/join`):
  - «Last ned appen» if needed  
  - «Åpne i Ketokasse» → `ketokasse://pair/<token>`  
- Redirect old `/join/[token]` → same pairing UX so existing QRs don’t die overnight.

---

## iOS implementation order (grok build)

1. AuthGate: add **Skann QR** + camera scanner (permission copy in Norwegian).  
2. Deep link `ketokasse://pair/...` + store pending token if camera used before install completes.  
3. Profile picker screen after auth/pair.  
4. Wire Settings Del QR to pair URL once Oskar ships `create_device_pair`.  
5. Attribute cook UI to active profile; keep household points.  
6. Settings: Bytt profil / Logg ut (email device) / fjern denne enheten later.  
7. Verify scripts for AuthGate having both paths + pair route.

Until Oskar’s migration lands, keep email path green; gate scan path behind pair RPC availability or feature flag.

---

## Out of scope for this plan

- Multiple household emails by design  
- Kids’ PIN / profile lock (nice later)  
- Buying ketokasse.no  
- AASA (Oskar on request)  
- Full leave-household UI  

---

## Definition of done

Anna with a fresh install: AuthGate → Skann QR → camera → Julian’s QR → profile picker → same week plan. No second magic link. Julian still uses email on his phone.

---

## Handoff line for chat

«Implement docs/GROK_BUILD_ONE_EMAIL_QR.md: AuthGate magic-link OR in-app QR scan; Netflix profile picker; pair tokens instead of second email. Coordinate with Oskar for `device_pairs` / `household_profiles` migration before enabling scan redeem.»
