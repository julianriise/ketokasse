import assert from 'node:assert/strict'
import { describe, it } from 'node:test'

import {
	createInterestDraft,
	deriveNextMonday,
	editInterestAddress,
	setAllergenAck,
	validateInterestDraft,
} from './domain.ts'

function oslo(isoOffset: string): Date {
	return new Date(isoOffset)
}

function readyDraft() {
	let draft = createInterestDraft()
	draft = editInterestAddress(draft, 'line1', 'Eksempelveien 12')
	draft = editInterestAddress(draft, 'postalCode', '0150')
	draft = editInterestAddress(draft, 'city', 'Oslo')
	draft = setAllergenAck(draft, true)
	return draft
}

describe('createInterestDraft', () => {
	it('starts with empty address and no allergen acknowledgement', () => {
		const draft = createInterestDraft()
		assert.equal(draft.allergenAck, false)
		assert.deepEqual(draft.address, {
			line1: '',
			postalCode: '',
			city: '',
			instructions: '',
		})
	})
})

describe('editInterestAddress', () => {
	it('replaces one field without mutating the previous address', () => {
		const draft = createInterestDraft()
		const next = editInterestAddress(draft, 'city', 'Bergen')
		assert.notEqual(next.address, draft.address)
		assert.equal(draft.address.city, '')
		assert.equal(next.address.city, 'Bergen')
		assert.equal(next.address.line1, '')
	})
})

describe('setAllergenAck', () => {
	it('returns a new draft and leaves the original unchanged', () => {
		const draft = createInterestDraft()
		const next = setAllergenAck(draft, true)
		assert.notEqual(next, draft)
		assert.equal(draft.allergenAck, false)
		assert.equal(next.allergenAck, true)
	})
})

describe('validateInterestDraft', () => {
	it('rejects an empty draft with Norwegian issue codes', () => {
		const result = validateInterestDraft(createInterestDraft())
		assert.equal(result.ok, false)
		if (result.ok) {
			throw new Error('expected issues')
		}
		assert.deepEqual(
			result.issues.map((issue) => issue.code),
			[
				'line1-required',
				'postal-code-invalid',
				'city-required',
				'allergen-required',
			],
		)
	})

	it('rejects a complete address that has not acknowledged allergens', () => {
		let draft = readyDraft()
		draft = setAllergenAck(draft, false)
		const result = validateInterestDraft(draft)
		assert.equal(result.ok, false)
		if (result.ok) {
			throw new Error('expected issues')
		}
		assert.equal(result.issues[0]?.code, 'allergen-required')
		assert.equal(result.issues.length, 1)
	})

	it('rejects postal codes that are not exactly four digits', () => {
		let draft = readyDraft()
		draft = editInterestAddress(draft, 'postalCode', '123')
		const short = validateInterestDraft(draft)
		assert.equal(short.ok, false)

		draft = editInterestAddress(draft, 'postalCode', '12345')
		const long = validateInterestDraft(draft)
		assert.equal(long.ok, false)

		draft = editInterestAddress(draft, 'postalCode', '12 3')
		const spaced = validateInterestDraft(draft)
		assert.equal(spaced.ok, false)
	})

	it('rejects fields that exceed the copy limits', () => {
		let draft = readyDraft()
		draft = editInterestAddress(draft, 'line1', 'x'.repeat(121))
		const line1 = validateInterestDraft(draft)
		assert.equal(line1.ok, false)
		if (!line1.ok) {
			assert.equal(
				line1.issues.some((issue) => issue.code === 'line1-too-long'),
				true,
			)
		}

		draft = readyDraft()
		draft = editInterestAddress(draft, 'city', 'y'.repeat(81))
		const city = validateInterestDraft(draft)
		assert.equal(city.ok, false)
		if (!city.ok) {
			assert.equal(
				city.issues.some((issue) => issue.code === 'city-too-long'),
				true,
			)
		}

		draft = readyDraft()
		draft = editInterestAddress(draft, 'instructions', 'z'.repeat(301))
		const instructions = validateInterestDraft(draft)
		assert.equal(instructions.ok, false)
		if (!instructions.ok) {
			assert.equal(
				instructions.issues.some(
					(issue) => issue.code === 'instructions-too-long',
				),
				true,
			)
		}
	})

	it('normalizes a complete draft and treats blank instructions as null', () => {
		let draft = readyDraft()
		draft = editInterestAddress(draft, 'line1', '  Gate 1  ')
		draft = editInterestAddress(draft, 'postalCode', ' 0150 ')
		draft = editInterestAddress(draft, 'city', ' Oslo ')
		draft = editInterestAddress(draft, 'instructions', '   ')
		const result = validateInterestDraft(draft)
		assert.equal(result.ok, true)
		if (!result.ok) {
			throw new Error('expected ready interest')
		}
		assert.equal(result.interest.allergenAck, true)
		assert.deepEqual(result.interest.address, {
			line1: 'Gate 1',
			postalCode: '0150',
			city: 'Oslo',
			instructions: null,
		})
	})

	it('keeps trimmed delivery instructions', () => {
		let draft = readyDraft()
		draft = editInterestAddress(draft, 'instructions', '  Sett ved døren  ')
		const result = validateInterestDraft(draft)
		assert.equal(result.ok, true)
		if (!result.ok) {
			throw new Error('expected ready interest')
		}
		assert.equal(result.interest.address.instructions, 'Sett ved døren')
	})
})

describe('deriveNextMonday', () => {
	it('returns today when now is Monday before 12:00 Oslo', () => {
		const next = deriveNextMonday(oslo('2026-09-14T11:59:59+02:00'))
		assert.equal(next.date, '2026-09-14')
	})

	it('skips today at exactly 12:00 Oslo on Monday', () => {
		const next = deriveNextMonday(oslo('2026-09-14T12:00:00+02:00'))
		assert.equal(next.date, '2026-09-21')
	})

	it('returns the next Monday from a Thursday afternoon in Oslo', () => {
		const now = oslo('2026-09-17T15:00:00+02:00')
		assert.equal(deriveNextMonday(now).date, '2026-09-21')
	})

	it('crosses the year boundary on civil dates', () => {
		const now = oslo('2026-12-31T15:00:00+01:00')
		assert.equal(deriveNextMonday(now).date, '2027-01-04')
	})

	it('keeps Monday 30 March 2026 before noon through the spring-forward gap', () => {
		const beforeNoon = deriveNextMonday(oslo('2026-03-30T11:30:00+02:00'))
		assert.equal(beforeNoon.date, '2026-03-30')

		const afterCutoff = deriveNextMonday(oslo('2026-03-30T13:00:00+02:00'))
		assert.equal(afterCutoff.date, '2026-04-06')
	})

	it('uses Europe/Oslo rather than the Date instant’s other local zone', () => {
		const next = deriveNextMonday(oslo('2026-09-13T22:30:00-07:00'))
		assert.equal(next.date, '2026-09-14')
	})
})
