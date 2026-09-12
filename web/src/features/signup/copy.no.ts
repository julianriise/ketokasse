import type {
	DaySlot,
	NextDelivery,
	OsloCalendarDate,
	SignupIssue,
	Weekday,
} from './domain'

export type CopyNo = Readonly<{
	metadata: Readonly<{ title: string; description: string }>
	a11y: Readonly<{ skipToSignup: string; required: string }>
	hero: Readonly<{
		eyebrow: string
		title: string
		lead: string
		capacity: string
	}>
	photo: Readonly<{ alt: string }>
	day: Readonly<{
		heading: string
		body: string
		groupLabel: string
		available: string
		taken: string
		selected: string
	}>
	address: Readonly<{
		heading: string
		body: string
		line1Label: string
		line1Placeholder: string
		postalCodeLabel: string
		postalCodePlaceholder: string
		cityLabel: string
		cityPlaceholder: string
		instructionsLabel: string
		instructionsPlaceholder: string
		instructionsHelp: string
	}>
	checkout: Readonly<{
		heading: string
		body: string
		price: string
		demoDisclosure: string
		submit: string
		pending: string
		errorSummaryHeading: string
		errorSummaryBody: string
		failure: string
		successHeading: string
	}>
	nextDelivery: Readonly<{
		heading: string
		unselected: string
		calculating: string
		recurrence: string
	}>
	app: Readonly<{
		heading: string
		body: string
		platform: string
		download: string
		comingSoon: string
	}>
	weekdays: Readonly<Record<Weekday, string>>
	issues: Readonly<Record<SignupIssue['code'], string>>
}>

export const copyNo: CopyNo = {
	metadata: {
		title: 'KetoKasse | Ketomat levert hjem hver uke',
		description:
			'Velg en fast leveringsdag og få en KetoKasse med kjøtt og grønnsaker levert hjem hver uke.',
	},
	a11y: {
		skipToSignup: 'Gå til påmelding',
		required: 'Påkrevd',
	},
	hero: {
		eyebrow: 'Rett fra gården, hjem til deg',
		title: 'KetoKasse',
		lead: 'En ukentlig kasse med kjøtt, grønnsaker og gode fettkilder.',
		capacity: 'Sju leveringsdager. Én kunde per dag.',
	},
	photo: {
		alt: 'En KetoKasse med pakkede kjøttvarer og friske grønnsaker sett ovenfra.',
	},
	day: {
		heading: 'Velg din faste leveringsdag',
		body: 'Vi leverer til én kunde per dag. Dagen du velger, blir din faste dag hver uke.',
		groupLabel: 'Tilgjengelige leveringsdager',
		available: 'Ledig',
		taken: 'Opptatt',
		selected: 'Valgt',
	},
	address: {
		heading: 'Hvor skal vi levere?',
		body: 'Adressen brukes til de ukentlige leveringene dine.',
		line1Label: 'Gateadresse og husnummer',
		line1Placeholder: 'Eksempelveien 12',
		postalCodeLabel: 'Postnummer',
		postalCodePlaceholder: '0123',
		cityLabel: 'Poststed',
		cityPlaceholder: 'Oslo',
		instructionsLabel: 'Leveringsinstruksjoner (valgfritt)',
		instructionsPlaceholder: 'Sett kassen ved sidedøren',
		instructionsHelp: 'Maks 300 tegn.',
	},
	checkout: {
		heading: 'Start ukesleveringen',
		body: 'Betal med Stripe. Abonnementet fornyes hver uke til du sier opp.',
		price: '649 kr per uke',
		demoDisclosure: 'Dette er en demo. Ingen betaling gjennomføres.',
		submit: 'Start ukesleveringen',
		pending: 'Klargjør betaling …',
		errorSummaryHeading: 'Sjekk opplysningene',
		errorSummaryBody:
			'Noen felt mangler eller må rettes før du kan fortsette.',
		failure: 'Vi fikk ikke startet betalingen. Prøv igjen.',
		successHeading: 'Demoen er fullført',
	},
	nextDelivery: {
		heading: 'Din neste levering',
		unselected: 'Velg en ledig dag for å se datoen.',
		calculating: 'Beregner neste levering …',
		recurrence: 'Deretter leverer vi samme dag hver uke.',
	},
	app: {
		heading: 'KetoKasse på iPhone',
		body: 'Se leveringer og administrer abonnementet i appen.',
		platform: 'Kun for iPhone.',
		download: 'Last ned i App Store',
		comingSoon: 'Kommer snart i App Store',
	},
	weekdays: {
		mon: 'Mandag',
		tue: 'Tirsdag',
		wed: 'Onsdag',
		thu: 'Torsdag',
		fri: 'Fredag',
		sat: 'Lørdag',
		sun: 'Søndag',
	},
	issues: {
		'day-required': 'Velg en ledig leveringsdag.',
		'day-taken': 'Denne dagen er ikke lenger ledig. Velg en annen dag.',
		'line1-required': 'Skriv inn gateadresse og husnummer.',
		'line1-too-long': 'Gateadressen kan ha maks 120 tegn.',
		'postal-code-invalid': 'Postnummeret må bestå av fire sifre.',
		'city-required': 'Skriv inn poststed.',
		'city-too-long': 'Poststedet kan ha maks 80 tegn.',
		'instructions-too-long':
			'Leveringsinstruksjonene kan ha maks 300 tegn.',
	},
}

export function daySlotAriaLabelNo(
	slot: DaySlot,
	selected: boolean,
): string {
	const name = copyNo.weekdays[slot.day]
	if (selected && slot.taken) {
		return `${name}, valgt, men ikke lenger ledig`
	}
	if (selected) {
		return `${name}, valgt`
	}
	if (slot.taken) {
		return `${name}, opptatt`
	}
	return `${name}, ledig`
}

export function nextDeliverySentenceNo(delivery: NextDelivery): string {
	return `Din neste levering er ${formatOsloDateNo(delivery.date)}.`
}

export function checkoutSuccessBodyNo(delivery: NextDelivery): string {
	return `Ingen betaling ble gjennomført. I en ekte bestilling ville første levering vært ${formatOsloDateNo(delivery.date)}.`
}

export function checkoutReferenceNo(reference: string): string {
	return `Demoreferanse: ${reference}`
}

function formatOsloDateNo(date: OsloCalendarDate): string {
	const [year, month, day] = date.split('-').map(Number)
	const utcNoon = new Date(Date.UTC(year, month - 1, day, 12))
	return new Intl.DateTimeFormat('nb-NO', {
		timeZone: 'Europe/Oslo',
		weekday: 'long',
		day: 'numeric',
		month: 'long',
		year: 'numeric',
	}).format(utcNoon)
}
