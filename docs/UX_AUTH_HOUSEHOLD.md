# UX: Magic link, household, QR share

Norwegian UI copy. Duolingo chrome: progress where it helps, mascot + speech bubble, sticky CTA, typewriter on coach lines.

Mental model: you sign in as a **person**; the app syncs a **household**.

---

## A. First open — no session

**Screen: Velkommen tilbake / Kom i gang (AuthGate)**  
Layout: hero (celebrate or hello mascot) + bubble + sticky CTA.

1. Bubble (word-by-word): «Hei! Logg inn med e-post — vi sender en magisk lenke.»
2. Content: single email field (prefill keyboard email).
3. Sticky CTA: «SEND LENKE» (disabled until valid email).
4. Footer muted: «Ingen passord. Åpne lenken på denne telefonen.»

**On send**
- Call Supabase `signInWithOTP(email)`.
- Advance to **Sjekk inboksen**.

**Error**
- Invalid email → inline under field.
- Rate limit → bubble: «Vent litt og prøv igjen.»

---

## B. Check inbox

**Screen: Sjekk e-post**  
Coach or hero layout; no progress bar.

1. Bubble: «Vi sendte en lenke til {email}. Trykk den for å fortsette.»
2. Content: illustration / mail glyph; secondary text button «Åpne Mail» (`message://` / mailto optional).
3. Sticky: «SEND PÅ NYTT» (cooldown 30–60s) + text «Bytt e-post» → back to A.
4. Listening: app resumes session when user returns via magic link (universal link / `ketokasse://`).

**Deep link open**
- Cold start or warm: parse session from URL.
- Success → C.
- Failure → bubble «Lenken er utløpt.» + CTA back to A.

---

## C. Session start — ensure household (invisible or one beat)

After valid session, **before** existing onboarding/home:

1. Call `ensure_own_household()` once.
2. If new user: profile trigger already ran; RPC creates household + owner membership.
3. If returning member: RPC returns existing `household_id`.
4. Optional flash screen (≤1s): mascot coach «Setter opp familien…» — skip if RPC <300ms.

Then gate as today:
- Onboarding incomplete → existing Duolingo onboarding.
- Else → HomeShell.

Do **not** ask “create household?” — one person = one household in v1.

---

## D. Partner join — scan / open invite

**Entry paths**
- Scan QR from partner’s phone (Camera / in-app scanner later; iOS Camera on QR is enough if URL is https).
- Open `https://ketokasse-site.vercel.app/join/<token>` → button «Åpne i Ketokasse» → `ketokasse://join/<token>`.
- Already in app: Settings isn’t required; link opens app.

**If no session**
1. AuthGate (A→B) with return intent `pendingInviteToken`.
2. After C, auto-run redeem (E).

**If session already**
- Go straight to E.

---

## E. Redeem invite

**Screen: Bli med i husholdningen** (modal or full)

1. Bubble: «Du blir med i {name / «familien»}. Ukeplan og poeng synces.»
2. Content: short bullets — same plan, shared points, who cooked stays visible.
3. Sticky primary: «BLI MED» → `redeem_invite(token)`.
4. Sticky secondary / text: «Avbryt» (discard token).

**On success**
- Refresh week + points from server.
- Toast / bubble: «Dere er synket!»
- Home.

**On failure** (expired / used)
- Bubble: «Invitasjonen er brukt eller utløpt. Be om en ny QR.»
- CTA: «OK» → Home (own household unchanged if redeem failed before leave — match RPC behavior).

---

## F. Share household (owner or any member)

**Entry:** Settings → «Del med partner» (forest row, QR glyph).

**Screen: Del husholdningen**

1. Top: coach mascot + bubble «La partneren skanne — da får dere samme ukeplan.»
2. Center: large QR (invite URL). Under QR: truncated link + «Kopier lenke».
3. Meta: «Gyldig i 7 dager» (from `expires_at`).
4. Sticky: «LAG NY KODE» → new `create_invite()` (invalidates old only if you choose single-active later; v1 allows multiple live invites).
5. Helper: «Partneren må ha appen og logge inn med sin e-post.»

**First visit**
- Auto `create_invite()` on appear.
- Loading state on QR placeholder.

**Privacy**
- QR is a **token**, not household UUID.
- No need to show member emails on this screen in v1 (optional list «Dere to» later).

---

## G. Happy path storyboard (Julian → Anna)

| Step | Julian | Anna |
|------|--------|------|
| 1 | Install → email magic link → household auto-created | — |
| 2 | Finishes onboarding, uses week planner | — |
| 3 | Settings → Del → shows QR | Installs app |
| 4 | — | Magic link with her email |
| 5 | Holds QR | Scans → Bli med → redeem |
| 6 | Same week + points live | Same week + points live |
| 7 | Cooks Monday → points | Sees points / cook without re-plan |

---

## H. Edge cases (UX copy only)

| Case | Behavior |
|------|----------|
| Second phone, same email | Same user; same household; no second membership. |
| Already in household, scans again | Redeem no-op success; «Du er allerede med.» |
| Wants to leave household | v1: hide or Settings «Kontakt support» — no leave UI yet. |
| Offline at redeem | «Koble til nett og prøv igjen.» keep token. |
| Reduce Motion | Full bubble text; no typewriter. |

---

## I. What grok build implements vs Oskar

- **Grok build:** screens A–F, deep links, QR image, RPCs, store sync.
- **Oskar:** Supabase Auth redirects, email templates if needed, Vercel `/join` host + AASA when asked.
