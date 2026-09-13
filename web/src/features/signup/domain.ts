export type DraftAddress = Readonly<{
	line1: string
	postalCode: string
	city: string
	instructions: string
}>

export type AddressField = keyof DraftAddress

const interestDraftBrand: unique symbol = Symbol('InterestDraft')

export type InterestDraft = Readonly<{
	address: DraftAddress
	allergenAck: boolean
	[interestDraftBrand]: true
}>

export type InterestIssue =
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
	| Readonly<{ field: 'allergenAck'; code: 'allergen-required' }>

export type DeliveryAddress = Readonly<{
	line1: string
	postalCode: string
	city: string
	instructions: string | null
}>

const readyInterestBrand: unique symbol = Symbol('ReadyInterest')

export type ReadyInterest = Readonly<{
	address: DeliveryAddress
	allergenAck: true
	[readyInterestBrand]: true
}>

export type InterestValidation =
	| Readonly<{ ok: true; interest: ReadyInterest }>
	| Readonly<{
			ok: false
			issues: readonly [InterestIssue, ...InterestIssue[]]
	  }>

const osloCalendarDateBrand: unique symbol = Symbol('OsloCalendarDate')

export type OsloCalendarDate = string & {
	readonly [osloCalendarDateBrand]: true
}

export type NextDelivery = Readonly<{
	date: OsloCalendarDate
}>

export const WEEKLY_BOX_ALLERGENS: readonly string[] = []

export const EU_ALLERGEN_REFERENCE = [
	'Glutenholdig korn',
	'Krepsdyr',
	'Egg',
	'Fisk',
	'Peanøtter',
	'Soya',
	'Melk',
	'Nøtter',
	'Selleri',
	'Sennep',
	'Sesamfrø',
	'Svoveldioksid og sulfitter',
	'Lupin',
	'Bløtdyr',
] as const

const LINE1_MAX = 120
const CITY_MAX = 80
const INSTRUCTIONS_MAX = 300
const POSTAL_CODE_PATTERN = /^\d{4}$/
const OSLO_TIME_ZONE = 'Europe/Oslo'
const SAME_DAY_CUTOFF_HOUR = 12
const MONDAY_ISO = 1

const EMPTY_ADDRESS: DraftAddress = {
	line1: '',
	postalCode: '',
	city: '',
	instructions: '',
}

export function createInterestDraft(): InterestDraft {
	return {
		address: EMPTY_ADDRESS,
		allergenAck: false,
		[interestDraftBrand]: true,
	}
}

export function editInterestAddress(
	draft: InterestDraft,
	field: AddressField,
	value: string,
): InterestDraft {
	return {
		...draft,
		address: {
			...draft.address,
			[field]: value,
		},
	}
}

export function setAllergenAck(
	draft: InterestDraft,
	allergenAck: boolean,
): InterestDraft {
	return {
		...draft,
		allergenAck,
	}
}

export function validateInterestDraft(
	draft: InterestDraft,
): InterestValidation {
	const issues: InterestIssue[] = []

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

	if (!draft.allergenAck) {
		issues.push({ field: 'allergenAck', code: 'allergen-required' })
	}

	const first = issues[0]
	if (first !== undefined) {
		return { ok: false, issues: [first, ...issues.slice(1)] }
	}

	return {
		ok: true,
		interest: {
			address: {
				line1,
				postalCode,
				city,
				instructions: instructions.length === 0 ? null : instructions,
			},
			allergenAck: true,
			[readyInterestBrand]: true,
		},
	}
}

export function deriveNextMonday(now: Date): NextDelivery {
	const oslo = readOsloCivil(now)
	const delta = daysUntilMonday(oslo.weekdayIso, oslo.hour)
	return {
		date: addCivilDays(oslo.year, oslo.month, oslo.day, delta),
	}
}

function daysUntilMonday(currentIso: number, hour: number): number {
	let delta = (MONDAY_ISO - currentIso + 7) % 7
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
	weekdayIso: number
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
	const weekdayIso = jsDay === 0 ? 7 : jsDay

	return { year, month, day, hour, weekdayIso }
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
	const utc = new Date(Date.UTC(year, month - 1, day + delta))
	const y = String(utc.getUTCFullYear()).padStart(4, '0')
	const m = String(utc.getUTCMonth() + 1).padStart(2, '0')
	const d = String(utc.getUTCDate()).padStart(2, '0')
	return `${y}-${m}-${d}` as OsloCalendarDate
}
