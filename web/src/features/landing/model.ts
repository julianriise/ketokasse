export type Visual = Readonly<{
  src: string
  alt: string
  width: number
  height: number
}>

export type AppStoreCta =
  | Readonly<{
      kind: 'pending'
      pillLabel: string
      storeKicker: string
      storeName: string
    }>
  | Readonly<{
      kind: 'ready'
      href: string
      pillLabel: string
      storeKicker: string
      storeName: string
    }>

export type BandTone = 'white' | 'mint' | 'sky' | 'peach'

export type LandingBand =
  | Readonly<{
      kind: 'hero'
      id: 'hero'
      heading: string
      visual: Visual
    }>
  | Readonly<{
      kind: 'story'
      id: 'dinners' | 'monday' | 'recipes'
      heading: string
      body: string
      visual: Visual
      tone: BandTone
      visualSide: 'start' | 'end'
    }>
  | Readonly<{
      kind: 'anywhere'
      id: 'anywhere'
      heading: string
      visual: Visual
    }>

export type Landing = Readonly<{
  metadata: Readonly<{ title: string; description: string }>
  brand: Readonly<{ name: string; logo: Visual }>
  appStore: AppStoreCta
  bands: readonly LandingBand[]
}>

export function appStoreAnchorProps(
  cta: AppStoreCta,
): { href: string } | { 'aria-disabled': true } {
  switch (cta.kind) {
    case 'pending':
      return { 'aria-disabled': true }
    case 'ready':
      return { href: cta.href }
    default: {
      const _exhaustive: never = cta
      return _exhaustive
    }
  }
}
