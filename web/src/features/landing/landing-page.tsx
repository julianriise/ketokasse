import Image from 'next/image'
import type { JSX } from 'react'

import { AppStoreLink } from './app-store-link'
import type { AppStoreCta, Landing, LandingBand, Visual } from './model'

export function LandingPage({ landing }: { landing: Landing }): JSX.Element {
  return (
    <div className="kk-page">
      <a className="kk-skip" href="#anywhere">
        Hopp til nedlasting
      </a>
      <header className="kk-header">
        <div className="kk-header-inner">
          <a className="kk-wordmark" href="#hero">
            <Image
              src={landing.brand.logo.src}
              alt=""
              width={landing.brand.logo.width}
              height={landing.brand.logo.height}
              className="kk-logo"
              priority
            />
            <span>{landing.brand.name}</span>
          </a>
          <AppStoreLink cta={landing.appStore} variant="pill" />
        </div>
      </header>
      <main>
        {landing.bands.map((band) => (
          <Band key={band.id} band={band} cta={landing.appStore} />
        ))}
      </main>
      <footer className="kk-footer">
        <p className="kk-footer-brand">{landing.brand.name}</p>
        <AppStoreLink cta={landing.appStore} variant="pill" />
      </footer>
    </div>
  )
}

function Band({
  band,
  cta,
}: {
  band: LandingBand
  cta: AppStoreCta
}): JSX.Element {
  switch (band.kind) {
    case 'hero':
      return <HeroBand band={band} cta={cta} />
    case 'story':
      return <StoryBand band={band} />
    case 'anywhere':
      return <AnywhereBand band={band} cta={cta} />
    default: {
      const _exhaustive: never = band
      return _exhaustive
    }
  }
}

function HeroBand({
  band,
  cta,
}: {
  band: Extract<LandingBand, { kind: 'hero' }>
  cta: AppStoreCta
}): JSX.Element {
  return (
    <section className="kk-hero" id={band.id}>
      <div className="kk-hero-inner">
        <div className="kk-hero-visual">
          <BandVisual visual={band.visual} className="kk-visual-img" priority />
        </div>
        <div className="kk-hero-copy">
          <h1 className="kk-hero-heading">{band.heading}</h1>
          <AppStoreLink cta={cta} variant="pill" />
        </div>
      </div>
    </section>
  )
}

function StoryBand({
  band,
}: {
  band: Extract<LandingBand, { kind: 'story' }>
}): JSX.Element {
  return (
    <section
      className={`kk-story kk-tone-${band.tone} kk-visual-${band.visualSide}`}
      id={band.id}
    >
      <div className="kk-story-inner">
        <div className="kk-story-copy">
          <h2 className="kk-story-heading">{band.heading}</h2>
          <p className="kk-story-body">{band.body}</p>
        </div>
        <div className="kk-story-visual">
          <BandVisual visual={band.visual} className="kk-visual-img" />
        </div>
      </div>
    </section>
  )
}

function AnywhereBand({
  band,
  cta,
}: {
  band: Extract<LandingBand, { kind: 'anywhere' }>
  cta: AppStoreCta
}): JSX.Element {
  return (
    <section className="kk-anywhere" id={band.id}>
      <div className="kk-anywhere-inner">
        <h2 className="kk-anywhere-heading">{band.heading}</h2>
        <AppStoreLink cta={cta} variant="badge" />
        <div className="kk-anywhere-visual">
          <BandVisual visual={band.visual} className="kk-visual-img" />
        </div>
      </div>
    </section>
  )
}

function BandVisual({
  visual,
  className,
  priority = false,
}: {
  visual: Visual
  className: string
  priority?: boolean
}): JSX.Element {
  const svg = visual.src.endsWith('.svg')
  const mascot = visual.src.includes('mascot-')
  return (
    <Image
      src={visual.src}
      alt={visual.alt}
      width={visual.width}
      height={visual.height}
      className={mascot ? `${className} kk-mascot-img` : className}
      unoptimized={svg}
      priority={priority}
      sizes="(max-width: 800px) 92vw, 480px"
    />
  )
}
