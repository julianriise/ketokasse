# KetoKasse grounding (greenfield)

No existing codebase. Product is a Norwegian keto food-box landing page with signup.

## Product intent

Homestead / homemaker vibe. Web fun. Fresh from the farm. Limited capacity: seven delivery days, one customer per day.

## Prescribed page stack (no overlapping elements)

1. Big title / brand
2. Food box image (overhead, vegetables + packed meat)
3. Pick delivery day (Mon–Sun, one customer per day)
4. Address and delivery instructions
5. Pay with Stripe/Shop, weekly recurring until cancelled
6. Your next delivery is `<date>`
7. Download the app (iOS only)

## Domain shape (working hypothesis)

```ts
type Weekday = 'mon' | 'tue' | 'wed' | 'thu' | 'fri' | 'sat' | 'sun'

type DaySlot = {
  day: Weekday
  taken: boolean
}

type Address = {
  line1: string
  postalCode: string
  city: string
  instructions: string
}

type SignupDraft = {
  day: Weekday | null
  address: Address
}

// Derived: next calendar date matching selected weekday, not today if already past cutoff
type NextDelivery = { date: Date } // computed from day + "now"
```

Invariant: at most one open subscription per `Weekday`.

## Visual direction

Keto + farmer: deep forest green, moss, warm wood, linen. Avoid purple gradients, cream+terracotta serif cliché, dark-mode glow. Expressive type, not Inter/Roboto. Atmosphere via texture/gradient, real food photo as visual anchor.

## Out of scope for v1

Real Stripe keys, real Shop backend, real iOS app binary, auth, admin. Mock checkout that still completes the UX loop.
