import type { InterestIssue, NextDelivery, OsloCalendarDate } from './domain'

export type CopyNo = Readonly<{
	metadata: Readonly<{ title: string; description: string }>
	a11y: Readonly<{ skipToSignup: string; required: string }>
	hero: Readonly<{
		title: string
		lead: string
		softLaunch: string
	}>
	photo: Readonly<{ alt: string }>
	offer: Readonly<{
		heading: string
		body: string
		rows: readonly string[]
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
	allergens: Readonly<{
		heading: string
		weeklyHeading: string
		weeklyEmpty: string
		referenceHeading: string
		packaging: string
		ack: string
	}>
	interest: Readonly<{
		heading: string
		body: string
		price: string
		deposit: string
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
		recurrence: string
	}>
	recipe: Readonly<{
		heading: string
		body: string
	}>
	issues: Readonly<Record<InterestIssue['code'], string>>
}>

export const copyNo: CopyNo = {
	metadata: {
		title: 'KetoKasse | Keto-måltidskasse levert mandag',
		description:
			'Ukentlig keto-måltidskasse. 5 middager, 2 porsjoner. Levering mandag. 1490 kr per uke.',
	},
	a11y: {
		skipToSignup: 'Gå til interesseregistrering',
		required: 'Påkrevd',
	},
	hero: {
		title: 'KetoKasse',
		lead: 'Ukentlig keto-måltidskasse. 5 middager, 2 porsjoner. Du lager maten hjemme.',
		softLaunch: 'Begrenset plass.',
	},
	photo: {
		alt: 'En KetoKasse med pakkede kjøttvarer og friske grønnsaker sett ovenfra.',
	},
	offer: {
		heading: 'Hva du får',
		body: 'Ferdig kasse. Du legger ikke ut for maten.',
		rows: [
			'5 middager, 2 porsjoner (10 porsjoner)',
			'Levering mandag',
			'Digital oppskrift. Ingen papir.',
			'1490 kr per uke, alt inkludert',
			'+200 kr pant første gang (Sono-kasse, byttes ved neste levering)',
			'Frysepose følger med. Ingen pant.',
		],
	},
	address: {
		heading: 'Hvor skal kassen?',
		body: 'Vi bruker adressen til mandagsleveringen.',
		line1Label: 'Gateadresse og husnummer',
		line1Placeholder: 'Eksempelveien 12',
		postalCodeLabel: 'Postnummer',
		postalCodePlaceholder: '0123',
		cityLabel: 'Poststed',
		cityPlaceholder: 'Oslo',
		instructionsLabel: 'Leveringsinstruksjoner',
		instructionsPlaceholder: 'Sett kassen ved sidedøren',
		instructionsHelp: 'Valgfritt. Maks 300 tegn.',
	},
	allergens: {
		heading: 'Allergener',
		weeklyHeading: 'Ukens kasse',
		weeklyEmpty: 'Oppdateres hver uke',
		referenceHeading: 'De 14 allergenene (referanse)',
		packaging: 'Full ingrediensliste står på originale pakninger i kassen.',
		ack: 'Jeg har lest allergeninformasjonen',
	},
	interest: {
		heading: 'Meld interesse',
		body: 'Ingen betaling her. Vi tar kontakt.',
		price: '1490 kr per uke',
		deposit: '+200 kr pant første gang',
		demoDisclosure: 'Interesseregistrering. Ingen betaling gjennomføres.',
		submit: 'Meld interesse',
		pending: 'Sender …',
		errorSummaryHeading: 'Sjekk opplysningene',
		errorSummaryBody:
			'Noen felt mangler eller må rettes før du kan fortsette.',
		failure: 'Vi fikk ikke registrert interessen. Prøv igjen.',
		successHeading: 'Interessen er registrert',
	},
	nextDelivery: {
		heading: 'Neste levering',
		recurrence: 'Deretter hver mandag.',
	},
	recipe: {
		heading: 'Oppskriften er digital',
		body: 'Ingen papir i kassen. Du får oppskriften digitalt.',
	},
	issues: {
		'line1-required': 'Skriv inn gateadresse og husnummer.',
		'line1-too-long': 'Gateadressen kan ha maks 120 tegn.',
		'postal-code-invalid': 'Postnummeret må bestå av fire sifre.',
		'city-required': 'Skriv inn poststed.',
		'city-too-long': 'Poststedet kan ha maks 80 tegn.',
		'instructions-too-long':
			'Leveringsinstruksjonene kan ha maks 300 tegn.',
		'allergen-required': 'Les allergeninformasjonen før du melder interesse.',
	},
}

export function nextDeliverySentenceNo(delivery: NextDelivery): string {
	return `Neste mandagslevering er ${formatOsloDateNo(delivery.date)}.`
}

export function interestSuccessBodyNo(delivery: NextDelivery): string {
	return `Ingen betaling ble gjennomført. Første mulige mandag er ${formatOsloDateNo(delivery.date)}.`
}

export function interestReferenceNo(reference: string): string {
	return `Referanse: ${reference}`
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
