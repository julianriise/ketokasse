# KetoKasse implementation notes

Base package is candidate B. The page is one client island over a branded `SignupDraft`. Next delivery is derived. Checkout only accepts `ReadySignup`.

## Files touched

- `web/src/app/layout.tsx`
- `web/src/app/page.tsx`
- `web/src/app/globals.css`
- `web/src/features/signup/domain.ts`
- `web/src/features/signup/copy.no.ts`
- `web/src/features/signup/mock-stripe-checkout.client.ts`
- `web/src/features/signup/signup-page.tsx`
- `web/src/features/signup/domain.test.ts`
- `web/package.json` (`test:domain` script)
- `web/tsconfig.json` (excludes `*.test.ts` from the Next typecheck)

Hero image was already at `web/public/ketokasse-hero.png`.

## Deviations from design B

- Photo path is `/ketokasse-hero.png`, as specified for this build. B named `public/images/ketokasse-overhead.webp`.
- Same-day cutoff is 12:00 Europe/Oslo, exclusive. An order at 12:00:00 goes to next week. B left the cutoff open.
- Demo scarcity marks `wed` and `sat` taken. B left the snapshot open.
- Weekly price is `649 kr per uke`. B left the figure open.
- No App Store URL, so the last section shows `Kommer snart i App Store`.
- `globals.css` is in the requested module map. B did not list it.
- Domain tests use `node:test` with `--experimental-strip-types`. They import `./domain.ts`, so the Next tsconfig excludes test files.

## Checks run

- `npm run test:domain` (17 passed)
- `npm run build` (0)
- `npm run lint` (0)
- Chrome against `next start`. Heading order, taken days, live next-delivery sentence, Norwegian validation, and inline mock success all matched.
