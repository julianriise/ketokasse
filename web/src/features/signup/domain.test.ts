import assert from 'node:assert/strict'
import { describe, it } from 'node:test'

import {
	createSignupDraft,
	DAY_SLOTS,
	deriveNextDelivery,
	editSignupAddress,
	selectDeliveryDay,
	validateSignupDraft,
	type DaySlotTable,
	type Weekday,
} from './domain.ts'

const FREE_MON = { day: 'mon', taken: false } as const
const FREE_FRI = { day: 'fri', taken: false } as const

function slotsWithTaken(taken: readonly Weekday[]): DaySlotTable {
	return DAY_SLOTS.map((slot) => ({
		day: slot.day,
		taken: taken.includes(slot.day),
	})) as unknown as DaySlotTable
}

function oslo(isoOffset: string): Date {
	return new Date(isoOffset)
}

function readyDraft() {
	let draft = createSignupDraft()
	draft = selectDeliveryDay(draft, FREE_MON)
	draft = editSignupAddress(draft, 'line1', 'Eksempelveien 12')
	draft = editSignupAddress(draft, 'postalCode', '0150')
	draft = editSignupAddress(draft, 'city', 'Oslo')
	return draft
}

describe('createSignupDraft', () => {
	it('starts with no day and empty address fields', () => {
		const draft = createSignupDraft()
		assert.equal(draft.day, null)
		assert.deepEqual(draft.address, {
			line1: '',
			postalCode: '',
			city: '',
			instructions: '',
		})
	})
})

describe('selectDeliveryDay', () => {
	it('returns a new draft and leaves the original unchanged', () => {
		const draft = createSignupDraft()
		const next = selectDeliveryDay(draft, FREE_MON)
		assert.notEqual(next, draft)
		assert.equal(draft.day, null)
		assert.equal(next.day, 'mon')
	})
})

describe('editSignupAddress', () => {
	it('replaces one field without mutating the previous address', () => {
		const draft = createSignupDraft()
		const next = editSignupAddress(draft, 'city', 'Bergen')
		assert.notEqual(next.address, draft.address)
		assert.equal(draft.address.city, '')
		assert.equal(next.address.city, 'Bergen')
		assert.equal(next.address.line1, '')
	})
})

describe('validateSignupDraft', () => {
	it('rejects an empty draft with Norwegian issue codes', () => {
		const result = validateSignupDraft(createSignupDraft(), DAY_SLOTS)
		assert.equal(result.ok, false)
		if (result.ok) {
			throw new Error('expected issues')
		}
		assert.deepEqual(
			result.issues.map((issue) => issue.code),
			[
				'day-required',
				'line1-required',
				'postal-code-invalid',
				'city-required',
			],
		)
	})

	it('rejects a selected day that is taken in the current table', () => {
		const draft = selectDeliveryDay(createSignupDraft(), FREE_MON)
		const result = validateSignupDraft(draft, slotsWithTaken(['mon']))
		assert.equal(result.ok, false)
		if (result.ok) {
			throw new Error('expected issues')
		}
		assert.equal(result.issues[0]?.code, 'day-taken')
	})

	it('rejects postal codes that are not exactly four digits', () => {
		let draft = readyDraft()
		draft = editSignupAddress(draft, 'postalCode', '123')
		const short = validateSignupDraft(draft, DAY_SLOTS)
		assert.equal(short.ok, false)

		draft = editSignupAddress(draft, 'postalCode', '12345')
		const long = validateSignupDraft(draft, DAY_SLOTS)
		assert.equal(long.ok, false)

		draft = editSignupAddress(draft, 'postalCode', '12 3')
		const spaced = validateSignupDraft(draft, DAY_SLOTS)
		assert.equal(spaced.ok, false)
	})

	it('rejects fields that exceed the copy limits', () => {
		let draft = readyDraft()
		draft = editSignupAddress(draft, 'line1', 'x'.repeat(121))
		const line1 = validateSignupDraft(draft, DAY_SLOTS)
		assert.equal(line1.ok, false)
		if (!line1.ok) {
			assert.equal(
				line1.issues.some((issue) => issue.code === 'line1-too-long'),
				true,
			)
		}

		draft = readyDraft()
		draft = editSignupAddress(draft, 'city', 'y'.repeat(81))
		const city = validateSignupDraft(draft, DAY_SLOTS)
		assert.equal(city.ok, false)
		if (!city.ok) {
			assert.equal(
				city.issues.some((issue) => issue.code === 'city-too-long'),
				true,
			)
		}

		draft = readyDraft()
		draft = editSignupAddress(draft, 'instructions', 'z'.repeat(301))
		const instructions = validateSignupDraft(draft, DAY_SLOTS)
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
		draft = editSignupAddress(draft, 'line1', '  Gate 1  ')
		draft = editSignupAddress(draft, 'postalCode', ' 0150 ')
		draft = editSignupAddress(draft, 'city', ' Oslo ')
		draft = editSignupAddress(draft, 'instructions', '   ')
		const result = validateSignupDraft(draft, DAY_SLOTS)
		assert.equal(result.ok, true)
		if (!result.ok) {
			throw new Error('expected ready signup')
		}
		assert.equal(result.signup.day, 'mon')
		assert.deepEqual(result.signup.address, {
			line1: 'Gate 1',
			postalCode: '0150',
			city: 'Oslo',
			instructions: null,
		})
	})

	it('keeps trimmed delivery instructions', () => {
		let draft = readyDraft()
		draft = editSignupAddress(draft, 'instructions', '  Sett ved døren  ')
		const result = validateSignupDraft(draft, DAY_SLOTS)
		assert.equal(result.ok, true)
		if (!result.ok) {
			throw new Error('expected ready signup')
		}
		assert.equal(result.signup.address.instructions, 'Sett ved døren')
	})
})

describe('deriveNextDelivery', () => {
	it('returns today when the selected weekday is today and now is before 12:00 Oslo', () => {
		const next = deriveNextDelivery(
			'mon',
			oslo('2026-09-14T11:59:59+02:00'),
		)
		assert.equal(next.day, 'mon')
		assert.equal(next.date, '2026-09-14')
	})

	it('skips today at exactly 12:00 Oslo', () => {
		const next = deriveNextDelivery(
			'mon',
			oslo('2026-09-14T12:00:00+02:00'),
		)
		assert.equal(next.date, '2026-09-21')
	})

	it('computes each weekday offset from a Thursday afternoon in Oslo', () => {
		const now = oslo('2026-09-17T15:00:00+02:00')
		assert.equal(deriveNextDelivery('thu', now).date, '2026-09-24')
		assert.equal(deriveNextDelivery('fri', now).date, '2026-09-18')
		assert.equal(deriveNextDelivery('sat', now).date, '2026-09-19')
		assert.equal(deriveNextDelivery('sun', now).date, '2026-09-20')
		assert.equal(deriveNextDelivery('mon', now).date, '2026-09-21')
		assert.equal(deriveNextDelivery('tue', now).date, '2026-09-22')
		assert.equal(deriveNextDelivery('wed', now).date, '2026-09-23')
	})

	it('crosses the year boundary on civil dates', () => {
		const now = oslo('2026-12-31T15:00:00+01:00')
		assert.equal(deriveNextDelivery('thu', now).date, '2027-01-07')
		assert.equal(deriveNextDelivery('fri', now).date, '2027-01-01')
		assert.equal(deriveNextDelivery('sun', now).date, '2027-01-03')
	})

	it('keeps Sunday 29 March 2026 before noon through the spring-forward gap', () => {
		const beforeNoon = deriveNextDelivery(
			'sun',
			oslo('2026-03-29T01:30:00+01:00'),
		)
		assert.equal(beforeNoon.date, '2026-03-29')

		const afterCutoff = deriveNextDelivery(
			'sun',
			oslo('2026-03-29T13:00:00+02:00'),
		)
		assert.equal(afterCutoff.date, '2026-04-05')
	})

	it('keeps Sunday 25 October 2026 before noon through the fall-back overlap', () => {
		const beforeNoon = deriveNextDelivery(
			'sun',
			oslo('2026-10-25T11:30:00+02:00'),
		)
		assert.equal(beforeNoon.date, '2026-10-25')

		const afterCutoff = deriveNextDelivery(
			'sun',
			oslo('2026-10-25T13:00:00+01:00'),
		)
		assert.equal(afterCutoff.date, '2026-11-01')
	})

	it('uses Europe/Oslo rather than the Date instant’s other local zone', () => {
		// Saturday evening on the US west coast is Sunday morning in Oslo.
		const next = deriveNextDelivery(
			'sun',
			oslo('2026-09-12T22:30:00-07:00'),
		)
		assert.equal(next.date, '2026-09-13')
	})
})

describe('selectDeliveryDay with Friday', () => {
	it('can move from Monday to Friday', () => {
		const monday = selectDeliveryDay(createSignupDraft(), FREE_MON)
		const friday = selectDeliveryDay(monday, FREE_FRI)
		assert.equal(friday.day, 'fri')
	})
})
