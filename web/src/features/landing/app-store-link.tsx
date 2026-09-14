import type { JSX } from 'react'

import { appStoreAnchorProps, type AppStoreCta } from './model'

export function AppStoreLink({
  cta,
  variant,
}: {
  cta: AppStoreCta
  variant: 'pill' | 'badge'
}): JSX.Element {
  const anchorProps = appStoreAnchorProps(cta)

  if (variant === 'pill') {
    return (
      <a className="kk-cta-pill" {...anchorProps}>
        {cta.pillLabel}
      </a>
    )
  }

  return (
    <a
      className="kk-store"
      {...anchorProps}
      aria-label={`${cta.storeKicker} ${cta.storeName}`}
    >
      <AppleMark />
      <span className="kk-store-copy">
        <span className="kk-store-kicker">{cta.storeKicker}</span>
        <span className="kk-store-name">{cta.storeName}</span>
      </span>
    </a>
  )
}

function AppleMark(): JSX.Element {
  return (
    <svg className="kk-store-mark" viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="currentColor"
        d="M16.365 1.43c0 1.14-.42 2.07-1.26 2.79-.9.78-1.92 1.23-3.06 1.14-.12-1.08.39-2.19 1.2-2.94.84-.78 2.07-1.35 3.12-1.38zm4.395 15.67c-.54 1.26-1.2 2.4-2.16 3.42-1.32 1.38-2.4 2.16-3.24 2.16-.84 0-1.68-.54-2.52-.54-.9 0-1.86.57-2.58.57-1.02 0-2.1-.84-3.24-2.52-1.56-2.28-2.64-6.42-1.1-9.24.78-1.44 2.16-2.34 3.72-2.37.9 0 1.86.57 2.52.57.66 0 1.8-.72 3.06-.6.51.02 1.98.21 2.92 1.59-.07.05-1.74 1.02-1.72 3.03.03 2.4 2.1 3.21 2.13 3.22-.02.06-.33 1.14-1.11 2.25z"
      />
    </svg>
  )
}
