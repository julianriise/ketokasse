import Image from 'next/image'
import type { Metadata } from 'next'
import type { JSX } from 'react'

import { landingNo } from '@/features/landing/landing'
import { AppStoreLink } from '@/features/landing/app-store-link'

type JoinPageProps = {
  params: Promise<{ token: string }>
}

export const metadata: Metadata = {
  title: 'Bli med i husholdningen · KetoKasse',
  description: 'Åpne Ketokasse for å bli med i husholdningen og dele ukeplan.',
}

export default async function JoinPage({
  params,
}: JoinPageProps): Promise<JSX.Element> {
  const { token: raw } = await params
  const token = raw.trim()
  const valid = isInviteToken(token)
  const deepLink = valid ? `ketokasse://join/${token}` : null
  const brand = landingNo.brand

  return (
    <div className="kk-page kk-join-page">
      <header className="kk-header">
        <div className="kk-header-inner">
          <a className="kk-wordmark" href="/">
            <Image
              src={brand.logo.src}
              alt=""
              width={brand.logo.width}
              height={brand.logo.height}
              className="kk-logo"
              priority
            />
            <span>{brand.name}</span>
          </a>
        </div>
      </header>
      <main className="kk-join">
        <section className="kk-join-card">
          <Image
            src="/visuals/mascot-hello.png"
            alt=""
            width={1024}
            height={1024}
            className="kk-join-mascot"
            priority
          />
          <h1 className="kk-join-heading">Bli med i husholdningen</h1>
          <p className="kk-join-body">
            {valid
              ? 'Åpne Ketokasse for å dele ukeplan og poeng med partneren din.'
              : 'Denne invitasjonen er ugyldig. Be om en ny QR i appen.'}
          </p>
          {deepLink ? (
            <a className="kk-cta-pill kk-join-cta" href={deepLink}>
              Åpne i Ketokasse
            </a>
          ) : null}
          <p className="kk-join-hint">
            Har du ikke appen ennå? Installer den, logg inn med din e-post, og
            åpne denne siden på nytt.
          </p>
          <AppStoreLink cta={landingNo.appStore} variant="badge" />
        </section>
      </main>
    </div>
  )
}

function isInviteToken(value: string): boolean {
  return /^[a-f0-9]{16,64}$/i.test(value)
}
