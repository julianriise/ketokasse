import assert from 'node:assert/strict'
import { describe, it } from 'node:test'

import { appStoreAnchorProps } from './model.ts'

describe('appStoreAnchorProps', () => {
  it('returns aria-disabled for a pending CTA', () => {
    assert.deepEqual(
      appStoreAnchorProps({
        kind: 'pending',
        pillLabel: 'Last ned',
        storeKicker: 'Last ned i',
        storeName: 'App Store',
      }),
      { 'aria-disabled': true },
    )
  })

  it('returns href for a ready CTA', () => {
    assert.deepEqual(
      appStoreAnchorProps({
        kind: 'ready',
        href: 'https://apps.apple.com/no/app/ketokasse/id000',
        pillLabel: 'Last ned',
        storeKicker: 'Last ned i',
        storeName: 'App Store',
      }),
      { href: 'https://apps.apple.com/no/app/ketokasse/id000' },
    )
  })
})
