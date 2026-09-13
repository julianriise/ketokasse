'use client'

import Image from 'next/image'
import {
	useEffect,
	useState,
	type FormEvent,
	type JSX,
	type ReactNode,
} from 'react'

import {
	checkoutReferenceNo,
	checkoutSuccessBodyNo,
	copyNo,
	daySlotAriaLabelNo,
	nextDeliverySentenceNo,
} from './copy.no'
import {
	createSignupDraft,
	DAY_SLOTS,
	deriveNextDelivery,
	editSignupAddress,
	selectDeliveryDay,
	validateSignupDraft,
	type AddressField,
	type AvailableDaySlot,
	type DaySlot,
	type DaySlotTable,
	type NextDelivery,
	type SignupDraft,
	type SignupIssue,
	type SignupValidation,
} from './domain'
import {
	startMockStripeCheckout,
	type CheckoutOutcome,
} from './mock-stripe-checkout.client'

const APP_STORE_URL: string | null = null

const FIELD_FOCUS_ID: Readonly<Record<SignupIssue['field'], string>> = {
	day: 'field-day',
	line1: 'field-line1',
	postalCode: 'field-postalCode',
	city: 'field-city',
	instructions: 'field-instructions',
}

/**
 * Owns the draft and renders the seven page sections in normal document flow.
 * Boundary feedback may appear inline, but no section is conditional.
 */
export function SignupPage(): JSX.Element {
	const [draft, setDraft] = useState(createSignupDraft)
	const [hasSubmitted, setHasSubmitted] = useState(false)
	const [checkoutPending, setCheckoutPending] = useState(false)
	const [checkoutOutcome, setCheckoutOutcome] =
		useState<CheckoutOutcome | null>(null)
	const now = useBrowserNow()

	const validation = validateSignupDraft(draft, DAY_SLOTS)
	const nextDelivery =
		draft.day !== null && now !== null
			? deriveNextDelivery(draft.day, now)
			: null

	function chooseDay(slot: AvailableDaySlot) {
		setCheckoutOutcome(null)
		setDraft((current) => selectDeliveryDay(current, slot))
	}

	function editAddress(field: AddressField, value: string) {
		setCheckoutOutcome(null)
		setDraft((current) => editSignupAddress(current, field, value))
	}

	async function submit(event: FormEvent<HTMLFormElement>) {
		event.preventDefault()
		setHasSubmitted(true)

		const checked = validateSignupDraft(draft, DAY_SLOTS)
		if (!checked.ok) {
			focusFirstIssue(checked.issues[0])
			return
		}

		setCheckoutPending(true)
		try {
			const outcome = await startMockStripeCheckout(checked.signup)
			setCheckoutOutcome(outcome)
		} finally {
			setCheckoutPending(false)
		}
	}

	return (
		<main className="kk-page">
			<a className="kk-skip" href="#signup">
				{copyNo.a11y.skipToSignup}
			</a>
			<HeroSection />
			<FoodBoxImage />
			<form className="kk-form" onSubmit={submit} noValidate>
				<DaySection
					slots={DAY_SLOTS}
					draft={draft}
					hasSubmitted={hasSubmitted}
					validation={validation}
					onChoose={chooseDay}
				/>
				<AddressSection
					draft={draft}
					hasSubmitted={hasSubmitted}
					validation={validation}
					onEdit={editAddress}
				/>
				<CheckoutSection
					hasSubmitted={hasSubmitted}
					validation={validation}
					pending={checkoutPending}
					outcome={checkoutOutcome}
					delivery={nextDelivery}
				/>
			</form>
			<NextDeliverySection
				selected={draft.day !== null}
				delivery={nextDelivery}
			/>
			<IosAppSection />
		</main>
	)
}

/**
 * Returns null during static rendering, then supplies a valid browser Date and
 * refreshes it at each minute boundary so the cutoff cannot leave stale output.
 */
function useBrowserNow(): Date | null {
	const [now, setNow] = useState<Date | null>(null)

	useEffect(() => {
		let intervalId = 0

		function tick() {
			setNow(new Date())
		}

		tick()
		const msToNextMinute = 60_000 - (Date.now() % 60_000)
		const timeoutId = window.setTimeout(() => {
			tick()
			intervalId = window.setInterval(tick, 60_000)
		}, msToNextMinute)

		return () => {
			window.clearTimeout(timeoutId)
			window.clearInterval(intervalId)
		}
	}, [])

	return now
}

function focusFirstIssue(issue: SignupIssue) {
	const node = document.getElementById(FIELD_FOCUS_ID[issue.field])
	if (node instanceof HTMLElement) {
		node.focus()
	}
}

function HeroSection(): JSX.Element {
	return (
		<header className="kk-hero">
			<h1 className="kk-brand">{copyNo.hero.title}</h1>
			<p className="kk-lead">{copyNo.hero.lead}</p>
		</header>
	)
}

function FoodBoxImage(): JSX.Element {
	return (
		<figure className="kk-photo">
			<Image
				src="/ketokasse-hero.jpg"
				alt={copyNo.photo.alt}
				width={1280}
				height={720}
				priority
				sizes="100vw"
				className="kk-photo-img"
			/>
		</figure>
	)
}

function DaySection({
	slots,
	draft,
	hasSubmitted,
	validation,
	onChoose,
}: {
	slots: DaySlotTable
	draft: SignupDraft
	hasSubmitted: boolean
	validation: SignupValidation
	onChoose: (slot: AvailableDaySlot) => void
}): JSX.Element {
	const issue = visibleIssue(validation, hasSubmitted, 'day')

	return (
		<section className="kk-section" id="signup">
			<h2 className="kk-heading">{copyNo.day.heading}</h2>
			<p className="kk-capacity">{copyNo.hero.capacity}</p>
			<p className="kk-copy">{copyNo.day.body}</p>
			<fieldset className="kk-day-set" id="field-day" tabIndex={-1}>
				<legend className="sr-only">{copyNo.day.groupLabel}</legend>
				<div className="kk-days">
					{slots.map((slot) => (
						<DayOption
							key={slot.day}
							slot={slot}
							selected={draft.day === slot.day}
							onChoose={onChoose}
						/>
					))}
				</div>
			</fieldset>
			{issue ? (
				<p className="kk-error" id="day-error">
					{copyNo.issues[issue.code]}
				</p>
			) : null}
		</section>
	)
}

function DayOption({
	slot,
	selected,
	onChoose,
}: {
	slot: DaySlot
	selected: boolean
	onChoose: (slot: AvailableDaySlot) => void
}): JSX.Element {
	const taken = slot.taken
	const status = taken
		? copyNo.day.taken
		: selected
			? copyNo.day.selected
			: copyNo.day.available

	function pick() {
		if (slot.taken) {
			return
		}
		onChoose(slot)
	}

	return (
		<label
			className="kk-day"
			data-selected={selected ? 'true' : 'false'}
			data-taken={taken ? 'true' : 'false'}
			onClick={(event) => {
				event.preventDefault()
				pick()
			}}
		>
			<input
				className="kk-day-input"
				type="radio"
				name="delivery-day"
				value={slot.day}
				checked={selected}
				disabled={taken}
				aria-label={daySlotAriaLabelNo(slot, selected)}
				onChange={pick}
			/>
			<span className="kk-day-name">{copyNo.weekdays[slot.day]}</span>
			<span className="kk-day-state">{status}</span>
		</label>
	)
}

function AddressSection({
	draft,
	hasSubmitted,
	validation,
	onEdit,
}: {
	draft: SignupDraft
	hasSubmitted: boolean
	validation: SignupValidation
	onEdit: (field: AddressField, value: string) => void
}): JSX.Element {
	return (
		<section className="kk-section">
			<h2 className="kk-heading">{copyNo.address.heading}</h2>
			<p className="kk-copy">{copyNo.address.body}</p>
			<div className="kk-fields">
				<TextField
					id="field-line1"
					label={copyNo.address.line1Label}
					required
					value={draft.address.line1}
					placeholder={copyNo.address.line1Placeholder}
					autoComplete="street-address"
					issue={visibleIssue(validation, hasSubmitted, 'line1')}
					onChange={(value) => onEdit('line1', value)}
				/>
				<div className="kk-field-row">
					<TextField
						id="field-postalCode"
						label={copyNo.address.postalCodeLabel}
						required
						value={draft.address.postalCode}
						placeholder={copyNo.address.postalCodePlaceholder}
						autoComplete="postal-code"
						inputMode="numeric"
						issue={visibleIssue(
							validation,
							hasSubmitted,
							'postalCode',
						)}
						onChange={(value) => onEdit('postalCode', value)}
					/>
					<TextField
						id="field-city"
						label={copyNo.address.cityLabel}
						required
						value={draft.address.city}
						placeholder={copyNo.address.cityPlaceholder}
						autoComplete="address-level2"
						issue={visibleIssue(validation, hasSubmitted, 'city')}
						onChange={(value) => onEdit('city', value)}
					/>
				</div>
				<TextField
					id="field-instructions"
					label={copyNo.address.instructionsLabel}
					multiline
					value={draft.address.instructions}
					placeholder={copyNo.address.instructionsPlaceholder}
					help={copyNo.address.instructionsHelp}
					issue={visibleIssue(
						validation,
						hasSubmitted,
						'instructions',
					)}
					onChange={(value) => onEdit('instructions', value)}
				/>
			</div>
		</section>
	)
}

function CheckoutSection({
	hasSubmitted,
	validation,
	pending,
	outcome,
	delivery,
}: {
	hasSubmitted: boolean
	validation: SignupValidation
	pending: boolean
	outcome: CheckoutOutcome | null
	delivery: NextDelivery | null
}): JSX.Element {
	const showErrors = hasSubmitted && !validation.ok

	return (
		<section className="kk-section">
			<h2 className="kk-heading">{copyNo.checkout.heading}</h2>
			<p className="kk-copy">{copyNo.checkout.body}</p>
			<p className="kk-price">{copyNo.checkout.price}</p>
			{showErrors ? (
				<div className="kk-summary" role="alert">
					<p className="kk-summary-title">
						{copyNo.checkout.errorSummaryHeading}
					</p>
					<p>{copyNo.checkout.errorSummaryBody}</p>
					<ul className="kk-summary-list">
						{validation.issues.map((issue) => (
							<li key={`${issue.field}-${issue.code}`}>
								<a href={`#${FIELD_FOCUS_ID[issue.field]}`}>
									{copyNo.issues[issue.code]}
								</a>
							</li>
						))}
					</ul>
				</div>
			) : null}
			<p className="kk-demo">{copyNo.checkout.demoDisclosure}</p>
			<button className="kk-pay" type="submit" disabled={pending}>
				{pending ? copyNo.checkout.pending : copyNo.checkout.submit}
			</button>
			{outcome?.kind === 'failed' ? (
				<p className="kk-error" role="alert">
					{copyNo.checkout.failure}
				</p>
			) : null}
			{outcome?.kind === 'confirmed' ? (
				<div className="kk-success" role="status">
					<p className="kk-success-title">
						{copyNo.checkout.successHeading}
					</p>
					{delivery ? (
						<p>{checkoutSuccessBodyNo(delivery)}</p>
					) : null}
					<p>{checkoutReferenceNo(outcome.reference)}</p>
				</div>
			) : null}
		</section>
	)
}

function NextDeliverySection({
	selected,
	delivery,
}: {
	selected: boolean
	delivery: NextDelivery | null
}): JSX.Element {
	let body: ReactNode
	if (!selected) {
		body = <p className="kk-copy">{copyNo.nextDelivery.unselected}</p>
	} else if (delivery === null) {
		body = <p className="kk-copy">{copyNo.nextDelivery.calculating}</p>
	} else {
		body = (
			<>
				<p className="kk-next-sentence">
					{nextDeliverySentenceNo(delivery)}
				</p>
				<p className="kk-copy">{copyNo.nextDelivery.recurrence}</p>
			</>
		)
	}

	return (
		<section className="kk-section kk-next">
			<h2 className="kk-heading">{copyNo.nextDelivery.heading}</h2>
			{body}
		</section>
	)
}

function IosAppSection(): JSX.Element {
	return (
		<section className="kk-section kk-app">
			<h2 className="kk-heading">{copyNo.app.heading}</h2>
			<p className="kk-copy">{copyNo.app.body}</p>
			<p className="kk-copy">{copyNo.app.platform}</p>
			{APP_STORE_URL ? (
				<a className="kk-store" href={APP_STORE_URL}>
					{copyNo.app.download}
				</a>
			) : (
				<p className="kk-coming">{copyNo.app.comingSoon}</p>
			)}
		</section>
	)
}

function TextField({
	id,
	label,
	value,
	placeholder,
	onChange,
	issue,
	required = false,
	multiline = false,
	help,
	autoComplete,
	inputMode,
}: {
	id: string
	label: string
	value: string
	placeholder: string
	onChange: (value: string) => void
	issue: SignupIssue | null
	required?: boolean
	multiline?: boolean
	help?: string
	autoComplete?: string
	inputMode?: 'numeric'
}): JSX.Element {
	const errorId = `${id}-error`
	const helpId = help ? `${id}-help` : undefined
	const describedBy = [issue ? errorId : null, helpId]
		.filter(Boolean)
		.join(' ')

	const control = multiline ? (
		<textarea
			id={id}
			name={id}
			className="kk-input kk-textarea"
			value={value}
			placeholder={placeholder}
			aria-invalid={issue ? true : undefined}
			aria-describedby={describedBy || undefined}
			onChange={(event) => onChange(event.target.value)}
			rows={3}
		/>
	) : (
		<input
			id={id}
			name={id}
			className="kk-input"
			value={value}
			placeholder={placeholder}
			autoComplete={autoComplete}
			inputMode={inputMode}
			aria-invalid={issue ? true : undefined}
			aria-describedby={describedBy || undefined}
			onChange={(event) => onChange(event.target.value)}
		/>
	)

	return (
		<div className="kk-field">
			<label className="kk-label" htmlFor={id}>
				{label}
				{required ? (
					<>
						<span aria-hidden="true"> *</span>
						<span className="sr-only"> {copyNo.a11y.required}</span>
					</>
				) : null}
			</label>
			{control}
			{help ? (
				<p className="kk-help" id={helpId}>
					{help}
				</p>
			) : null}
			{issue ? (
				<p className="kk-error" id={errorId}>
					{copyNo.issues[issue.code]}
				</p>
			) : null}
		</div>
	)
}

function visibleIssue(
	validation: SignupValidation,
	hasSubmitted: boolean,
	field: SignupIssue['field'],
): SignupIssue | null {
	if (!hasSubmitted || validation.ok) {
		return null
	}
	return validation.issues.find((issue) => issue.field === field) ?? null
}
