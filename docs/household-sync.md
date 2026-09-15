# Household sync (planning)

Sync unit is the **household**, not the device or the person. Julian and Anna both sign in as users, then share one household. Meal plan, points, and cook completions live on that household.

## Auth (simple)

1. Email magic link (Supabase Auth) — no password to share.
2. On first login: `ensure_own_household()` creates a household and makes you `owner`.
3. Settings → Share → `create_invite()` → show QR for  
   `https://ketokasse.app/join/<token>` (or `ketokasse://join/<token>`).
4. Anna installs app → signs in with her email → scans QR → `redeem_invite(token)` moves her into Julian’s household.

Do not sync raw `UserDefaults` between phones. Treat local stores as a cache of household rows.

## Points (simplified)

- `households.points_total` only.
- Completing a cook inserts `cook_events` and increments household points in one write.
- UI can still show who cooked (`cooked_by`) without per-person leaderboards for v1.

## iOS shape

- `AuthClient` (Supabase Swift)
- `HouseholdRepository` (week plan, points, invites)
- Replace `WeekStore` / `PointsStore` persistence with remote + offline cache
- Deep link / universal link handler for `/join/:token`
- QR: `CoreImage` CIQRCodeGenerator from the invite URL

## Realtime

Subscribe to `week_plans` and `households` for the current `household_id` so Anna’s cook shows on Julian’s phone without pull-to-refresh.

## Out of v1

Separate accounts with “friend” sharing, multi-household, password auth, Stripe, web parity.
