# Grok Build Handoff — Household sync (iOS + web)

**Owner of this doc’s code work:** Julian’s local grok build agent (`ios/` + `web/` only).  
**Owner of cloud/browser setup:** Oskar (Supabase, Vercel, domains, connectors). Do not recreate the Supabase project.

## Already done (do not redo)

| Item | Value |
|------|--------|
| Supabase project | `ketokasse` |
| Project id / ref | `wtcdyfcqtajzpuwpeekf` |
| Region | `eu-central-1` (Frankfurt) |
| API URL | `https://wtcdyfcqtajzpuwpeekf.supabase.co` |
| Anon key | in `supabase/.env.local` on Julian’s Mac (gitignored). Also in dashboard → Settings → API |
| Schema | Applied: `profiles`, `households`, `household_members`, `household_invites`, `week_plans`, `cook_events` |
| RPCs | `ensure_own_household()`, `create_invite()`, `redeem_invite(token)` — **authenticated only** |
| Trigger | `handle_new_user` → inserts `profiles` on `auth.users` insert |
| Docs | `docs/household-sync.md`, `supabase/migrations/001_household.sql`, `002_household_rpc_grants.sql` |

**Product rule:** sync a **household**, not two phones. Meal plan + points + cook completions live on the household. Julian and Anna each have an auth user; both are members of one household.

---

## Goal for this handoff

Ship the minimum that makes household sync real in the **iOS app** (primary). Touch **web** only where needed for invite deep links / join page.

### Success criteria

1. User can magic-link sign in with email.
2. First login creates profile + household (via RPC).
3. Settings shows a **Share** QR for `create_invite()` → URL `https://ketokasse-site.vercel.app/join/<token>` and/or `ketokasse://join/<token>`.
4. Second device signs in, opens join URL / scans QR, calls `redeem_invite`, then sees the **same** week plan and household points.
5. Completing cook on one phone bumps `households.points_total` and inserts `cook_events`; the other phone updates (Realtime or refresh).
6. Local `UserDefaults` is cache only — not source of truth after login.

Out of scope for this pass: Stripe, multi-household, passwords, leaderboards, CloudAgents, buying `ketokasse.no`.

---

## Config / secrets (iOS)

1. Add SPM: `https://github.com/supabase/supabase-swift` (use current stable).
2. Read URL + anon key from a local xcconfig / Info.plist keys **not committed**, e.g. mirror `supabase/.env.local`:
   - `SUPABASE_URL=https://wtcdyfcqtajzpuwpeekf.supabase.co`
   - `SUPABASE_ANON_KEY=<from supabase/.env.local>`
3. Register URL scheme `ketokasse` in `Info.plist` (`CFBundleURLTypes`) for `ketokasse://join/...`.
4. Optional later: Associated Domains for `ketokasse-site.vercel.app` (Oskar can add AASA on Vercel when you ask).

---

## iOS architecture to produce

### New types (suggested paths)

```
ios/KetoKasse/Services/SupabaseClient+App.swift   // shared client
ios/KetoKasse/Services/AuthService.swift          // magic link, session, sign out
ios/KetoKasse/Services/HouseholdRepository.swift  // RPCs + week_plans + points + cook
ios/KetoKasse/Features/Auth/AuthGateView.swift    // email → send magic link → wait
ios/KetoKasse/Features/Settings/ShareHouseholdView.swift  // QR + copy link
```

### Wire into existing stores (prefer adapter, not rewrite UI)

- **`WeekStore`**: after auth, load/upsert `week_plans` for current household + `week_start` (Monday of current week). Keep rearrange / simulate UX; persist via repository instead of (or in addition to) UserDefaults.
  - DB: `slots text[7]` — map `PlanWeekday` order consistently with existing planner.
- **`PointsStore`**: read/write `households.points_total`. On cook finish, insert `cook_events` then increment points in one path (RPC or two statements; prefer single SQL function later if racey — for v1: insert event + update household where member).
- **`ContentView` / app root**: if no session → `AuthGateView`; else existing onboarding/home. Call `ensure_own_household()` once after session established.
- **Deep link**: handle `ketokasse://join/<token>` and universal `…/join/<token>` → after session, `redeem_invite(token)` → refresh stores.
- **Settings**: entry “Share with partner” → QR from invite URL. Use CoreImage `CIQRCodeGenerator`.
- **Realtime (recommended):** subscribe to `week_plans` and `households` filtered by `household_id`.

### Auth UX (keep Duolingo chrome style if easy)

- Email field + “Send magic link”.
- Copy: Norwegian UI strings still OK (app is NO).
- First user: `julian.riise@gmail.com`. Partner: Anna’s email when she installs.

### Cooking → points

In `CookingSession` / scorecard commit path: after local success, call repository:

```
cook_events: household_id, cooked_by, dish_title, day_index, points_awarded
households.points_total += points_awarded
```

Idempotency nice-to-have: unique (household_id, day_index, week_start) or skip if already cooked that day — not required for first merge.

### Verify scripts

Extend `ios/scripts/verify-*.sh` only lightly (files exist, AuthGate referenced). Do not require live network in CI scripts unless already the pattern.

---

## Web changes (`web/`)

Minimal:

1. **Route** `app/join/[token]/page.tsx` (or equivalent App Router path):
   - Explains “Open in Ketokasse app” / deep link button `ketokasse://join/<token>`.
   - If app not installed, show App Store placeholder or “install then scan again”.
2. Optional: set Vercel env `NEXT_PUBLIC_SUPABASE_URL` + `NEXT_PUBLIC_SUPABASE_ANON_KEY` only if the join page needs server/client Supabase (not required if page is static deep-link only).
3. Do **not** rebuild the whole marketing site for this.

Oskar will add Vercel env / AASA in the browser when you say the join route is live.

---

## DB contracts (call exactly)

```sql
-- after sign-in
select public.ensure_own_household();  -- returns uuid

select * from public.create_invite();  -- token, expires_at

select public.redeem_invite('<token>');  -- returns household uuid
```

Tables (RLS: member of household only):

- `week_plans(household_id, week_start, slots[7], updated_at, updated_by)`
- `households(id, name, points_total, …)`
- `cook_events(…)`
- `household_members`, `household_invites`, `profiles`

---

## Suggested implementation order

1. SPM + client + AuthGate magic link + session restore  
2. `ensure_own_household` on login  
3. Share QR + deep link redeem  
4. Point `WeekStore` / `PointsStore` at remote  
5. Cook → `cook_events` + points  
6. Realtime  
7. Web `/join/[token]` stub  

---

## Ask Oskar (browser) if blocked

- Auth redirect URLs / email templates  
- Invite user from dashboard  
- Vercel env vars or `apple-app-site-association`  
- Domain cutover to `app.ketokasse.no` later  

Do **not** create a second Supabase project.

---

## Definition of done (for Julian to demo)

Anna and Julian on two phones: same week board, same points, QR invite works once, cook on one updates the other.
