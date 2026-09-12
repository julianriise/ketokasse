import type { ReadySignup } from './domain'

const checkoutReferenceBrand: unique symbol = Symbol('CheckoutReference')

export type CheckoutReference = string & {
	readonly [checkoutReferenceBrand]: true
}

export type CheckoutOutcome =
	| Readonly<{
			kind: 'confirmed'
			reference: CheckoutReference
	  }>
	| Readonly<{
			kind: 'failed'
			code: 'mock-unavailable'
	  }>

/** The v1 adapter waits briefly and performs no network call or charge. */
export async function startMockStripeCheckout(
	signup: ReadySignup,
): Promise<CheckoutOutcome> {
	await new Promise<void>((resolve) => {
		setTimeout(resolve, 800)
	})

	const reference =
		`KK-DEMO-${signup.day.toUpperCase()}-${signup.address.postalCode}` as CheckoutReference

	return { kind: 'confirmed', reference }
}
