export type Weekday =
	| 'mon'
	| 'tue'
	| 'wed'
	| 'thu'
	| 'fri'
	| 'sat'
	| 'sun'

export type AvailableDaySlot<D extends Weekday = Weekday> = Readonly<{
	day: D
	taken: false
}>

export type TakenDaySlot<D extends Weekday = Weekday> = Readonly<{
	day: D
	taken: true
}>

export type DaySlot<D extends Weekday = Weekday> =
	| AvailableDaySlot<D>
	| TakenDaySlot<D>

/** One row per weekday, in display order. */
export type DaySlotTable = readonly [
	DaySlot<'mon'>,
	DaySlot<'tue'>,
	DaySlot<'wed'>,
	DaySlot<'thu'>,
	DaySlot<'fri'>,
	DaySlot<'sat'>,
	DaySlot<'sun'>,
]

export const DAY_SLOTS: DaySlotTable = [
	{ day: 'mon', taken: false },
	{ day: 'tue', taken: false },
	{ day: 'wed', taken: true },
	{ day: 'thu', taken: false },
	{ day: 'fri', taken: false },
	{ day: 'sat', taken: true },
	{ day: 'sun', taken: false },
]

export type DraftAddress = Readonly<{
	line1: string
	postalCode: string
	city: string
	instructions: string
}>

export type AddressField = keyof DraftAddress

const signupDraftBrand: unique symbol = Symbol('SignupDraft')

/** An immutable value that may be incomplete while the customer types. */
export type SignupDraft = Readonly<{
	day: Weekday | null
	address: DraftAddress
	[signupDraftBrand]: true
}>

export type SignupIssue =
	| Readonly<{ field: 'day'; code: 'day-required' }>
	| Readonly<{ field: 'day'; code: 'day-taken' }>
	| Readonly<{
			field: 'line1'
			code: 'line1-required' | 'line1-too-long'
	  }>
	| Readonly<{ field: 'postalCode'; code: 'postal-code-invalid' }>
	| Readonly<{
			field: 'city'
			code: 'city-required' | 'city-too-long'
	  }>
	| Readonly<{
			field: 'instructions'
			code: 'instructions-too-long'
	  }>

export type DeliveryAddress = Readonly<{
	line1: string
	postalCode: string
	city: string
	instructions: string | null
}>

const readySignupBrand: unique symbol = Symbol('ReadySignup')

/** A normalized signup that has passed all current slot and address rules. */
export type ReadySignup = Readonly<{
	day: Weekday
	address: DeliveryAddress
	[readySignupBrand]: true
}>

export type SignupValidation =
	| Readonly<{ ok: true; signup: ReadySignup }>
	| Readonly<{
			ok: false
			issues: readonly [SignupIssue, ...SignupIssue[]]
	  }>

const osloCalendarDateBrand: unique symbol = Symbol('OsloCalendarDate')

/** An ISO calendar date interpreted only in Europe/Oslo. */
export type OsloCalendarDate = string & {
	readonly [osloCalendarDateBrand]: true
}

export type NextDelivery = Readonly<{
	day: Weekday
	date: OsloCalendarDate
}>

const LINE1_MAX = 120
const CITY_MAX = 80
const INSTRUCTIONS_MAX = 300
const POSTAL_CODE_PATTERN = /^\d{4}$/
const OSLO_TIME_ZONE = 'Europe/Oslo'
// Same-day delivery is allowed only before 12:00:00 Europe/Oslo.
const SAME_DAY_CUTOFF_HOUR = 12

const JS_DAY_TO_WEEKDAY = [
	'sun',
	'mon',
	'tue',
	'wed',
	'thu',
	'fri',
	'sat',
] as const satisfies readonly Weekday[]

const WEEKDAY_TO_ISO: Readonly<Record<Weekday, number>> = {
	mon: 1,
	tue: 2,
	wed: 3,
	thu: 4,
	fri: 5,
	sat: 6,
	sun: 7,
}

const EMPTY_ADDRESS: DraftAddress = {
	line1: '',
	postalCode: '',
	city: '',
	instructions: '',
}

export function createSignupDraft(): SignupDraft {
	return {
		day: null,
		address: EMPTY_ADDRESS,
		[signupDraftBrand]: true,
	}
}

/** Returns a new draft. A taken slot cannot reach this signature. */
export function selectDeliveryDay(
	draft: SignupDraft,
	slot: AvailableDaySlot,
): SignupDraft {
	return {
		...draft,
		day: slot.day,
	}
}

/** Replaces one raw controlled-input value without mutating the draft. */
export function editSignupAddress(
	draft: SignupDraft,
	field: AddressField,
	value: string,
): SignupDraft {
	return {
		...draft,
		address: {
			...draft.address,
			[field]: value,
		},
	}
}

/**
 * Trims required fields, validates the four-digit postal code and field limits,
 * and rejects a missing or currently taken day.
 */
export function validateSignupDraft(
	draft: SignupDraft,
	slots: DaySlotTable,
): SignupValidation {
	const issues: SignupIssue[] = []

	if (draft.day === null) {
		issues.push({ field: 'day', code: 'day-required' })
	} else if (isTakenDay(slots, draft.day)) {
		issues.push({ field: 'day', code: 'day-taken' })
	}

	const line1 = draft.address.line1.trim()
	if (line1.length === 0) {
		issues.push({ field: 'line1', code: 'line1-required' })
	} else if (line1.length > LINE1_MAX) {
		issues.push({ field: 'line1', code: 'line1-too-long' })
	}

	const postalCode = draft.address.postalCode.trim()
	if (!POSTAL_CODE_PATTERN.test(postalCode)) {
		issues.push({ field: 'postalCode', code: 'postal-code-invalid' })
	}

	const city = draft.address.city.trim()
	if (city.length === 0) {
		issues.push({ field: 'city', code: 'city-required' })
	} else if (city.length > CITY_MAX) {
		issues.push({ field: 'city', code: 'city-too-long' })
	}

	const instructions = draft.address.instructions.trim()
	if (instructions.length > INSTRUCTIONS_MAX) {
		issues.push({ field: 'instructions', code: 'instructions-too-long' })
	}

	const first = issues[0]
	if (first !== undefined) {
		return { ok: false, issues: [first, ...issues.slice(1)] }
	}

	if (draft.day === null) {
		return {
			ok: false,
			issues: [{ field: 'day', code: 'day-required' }],
		}
	}

	return {
		ok: true,
		signup: {
			day: draft.day,
			address: {
				line1,
				postalCode,
				city,
				instructions: instructions.length === 0 ? null : instructions,
			},
			[readySignupBrand]: true,
		},
	}
}

/**
 * Uses Europe/Oslo local calendar arithmetic. Today is eligible only when the
 * selected weekday is today and now is before the private same-day cutoff.
 */
export function deriveNextDelivery(day: Weekday, now: Date): NextDelivery {
	const oslo = readOsloCivil(now)
	const delta = daysUntilDelivery(day, oslo.weekday, oslo.hour)
	return {
		day,
		date: addCivilDays(oslo.year, oslo.month, oslo.day, delta),
	}
}

function isTakenDay(slots: DaySlotTable, day: Weekday): boolean {
	for (const slot of slots) {
		if (slot.day === day) {
			return slot.taken
		}
	}
	return false
}

function daysUntilDelivery(
	target: Weekday,
	current: Weekday,
	hour: number,
): number {
	let delta = (WEEKDAY_TO_ISO[target] - WEEKDAY_TO_ISO[current] + 7) % 7
	if (delta === 0 && hour >= SAME_DAY_CUTOFF_HOUR) {
		delta = 7
	}
	return delta
}

function readOsloCivil(now: Date): {
	year: number
	month: number
	day: number
	hour: number
	weekday: Weekday
} {
	const parts = new Intl.DateTimeFormat('en-US', {
		timeZone: OSLO_TIME_ZONE,
		year: 'numeric',
		month: '2-digit',
		day: '2-digit',
		hour: '2-digit',
		hourCycle: 'h23',
	}).formatToParts(now)

	const year = numberPart(parts, 'year')
	const month = numberPart(parts, 'month')
	const day = numberPart(parts, 'day')
	const hour = numberPart(parts, 'hour')
	const jsDay = new Date(Date.UTC(year, month - 1, day)).getUTCDay()
	const weekday = JS_DAY_TO_WEEKDAY[jsDay]
	if (weekday === undefined) {
		throw new Error(`Unexpected JS weekday index: ${jsDay}`)
	}

	return { year, month, day, hour, weekday }
}

function numberPart(
	parts: Intl.DateTimeFormatPart[],
	type: Intl.DateTimeFormatPartTypes,
): number {
	const value = parts.find((part) => part.type === type)?.value
	if (value === undefined) {
		throw new Error(`Missing Oslo date part: ${type}`)
	}
	return Number(value)
}

function addCivilDays(
	year: number,
	month: number,
	day: number,
	delta: number,
): OsloCalendarDate {
	// Civil Y-M-D addition is timezone-independent; UTC calendar math is safe.
	const utc = new Date(Date.UTC(year, month - 1, day + delta))
	const y = String(utc.getUTCFullYear()).padStart(4, '0')
	const m = String(utc.getUTCMonth() + 1).padStart(2, '0')
	const d = String(utc.getUTCDate()).padStart(2, '0')
	return `${y}-${m}-${d}` as OsloCalendarDate
}
