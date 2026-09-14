# App download landing

## Problem

The site is a Norwegian waitlist form. The visitor should download the iOS app. Duolingo's public site is the visual brief: short copy, illustration-led bands, a sticky Last ned control, an App Store badge whose URL is empty for now.

## Usage (caller's view)

`page.tsx` imports `landingNo` and renders `<LandingPage landing={landingNo} />`. Copy and visuals live in that value. Filling the App Store URL is one field change from `kind: 'pending'` to `kind: 'ready'` with an `https://apps.apple.com/...` href.

Call sites:

- `LandingPage` maps `landing.bands` and draws header, footer, and CTAs from `landing.appStore`.
- `AppStoreLink` reads `appStoreAnchorProps(cta)` so a pending CTA is an `<a>` with no `href`.
- Playwright drives the running page and checks the Last ned control has no `href`.

## Shape

`AppStoreCta` is a discriminated union. Pending cannot carry an href. Ready cannot omit one.

`LandingBand` is a table of hero, story, and anywhere rows. The page is a renderer over that table, not a stack of unrelated sections.

Waitlist types, the interest form, and mock submit go away. Delivery-date math belonged to signup, not to a download landing.

## Synthesis decision

Base is the band table (candidate A). Candidate B was a hardcoded JSX page that kept the waitlist form under the fold. It lost because the new job is download, and story bands share one shape. Graft from B: keep the existing food photo as one visual, not a CSS illustration.

## Tradeoffs accepted

- We accept Nunito instead of Duolingo Sans. Duolingo Sans is proprietary. Nunito is the closest rounded geometric Google font `next/font` can self-host.
- We accept SVG stand-ins for mascot and scenes until the requested PNGs replace them. The `Visual.src` field is the swap point.
- We accept no web signup. The iOS app owns that loop.

## Alternatives considered

- Keep the waitlist and restyle it. That keeps a long form as the primary action and fights the download brief.
- Hardcoded sections with copy in JSX. Callers would edit layout to change a sentence. The table hides that.

## Open questions and risks

- Which mascot should the logo be, once original art exists?
- What is the App Store URL when the listing is live?

## Next implementation step

Replace `web/src/app/page.tsx` with `LandingPage` over `landingNo`, and delete `web/src/features/signup`.
