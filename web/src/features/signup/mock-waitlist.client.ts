import type { ReadyInterest } from './domain'

const waitlistReferenceBrand: unique symbol = Symbol('WaitlistReference')

export type WaitlistReference = string & {
	readonly [waitlistReferenceBrand]: true
}

export type WaitlistOutcome =
	| Readonly<{
			kind: 'confirmed'
			reference: WaitlistReference
	  }>
	| Readonly<{
			kind: 'failed'
			code: 'mock-unavailable'
	  }>

export async function startMockWaitlist(
	interest: ReadyInterest,
): Promise<WaitlistOutcome> {
	await new Promise<void>((resolve) => {
		setTimeout(resolve, 400)
	})

	const reference =
		`KK-INTRESSE-${interest.address.postalCode}` as WaitlistReference

	return { kind: 'confirmed', reference }
}
