'use client'

import { useState, type FormEvent, type JSX } from 'react'

import {
	copyNo,
	interestReferenceNo,
	interestSuccessBodyNo,
} from './copy.no'
import {
	createInterestDraft,
	editInterestAddress,
	EU_ALLERGEN_REFERENCE,
	setAllergenAck,
	validateInterestDraft,
	WEEKLY_BOX_ALLERGENS,
	type AddressField,
	type InterestDraft,
	type InterestIssue,
	type InterestValidation,
	type NextDelivery,
} from './domain'
import {
	startMockWaitlist,
	type WaitlistOutcome,
} from './mock-waitlist.client'

const FIELD_FOCUS_ID: Readonly<Record<InterestIssue['field'], string>> = {
	line1: 'field-line1',
	postalCode: 'field-postalCode',
	city: 'field-city',
	instructions: 'field-instructions',
	allergenAck: 'field-allergenAck',
}

export function InterestForm({
	nextDelivery,
}: {
	nextDelivery: NextDelivery
}): JSX.Element {
	const [draft, setDraft] = useState(createInterestDraft)
	const [hasSubmitted, setHasSubmitted] = useState(false)
	const [pending, setPending] = useState(false)
	const [outcome, setOutcome] = useState<WaitlistOutcome | null>(null)
	const validation = validateInterestDraft(draft)

	function editAddress(field: AddressField, value: string) {
		setOutcome(null)
		setDraft((current) => editInterestAddress(current, field, value))
	}

	function editAck(value: boolean) {
		setOutcome(null)
		setDraft((current) => setAllergenAck(current, value))
	}

	async function submit(event: FormEvent<HTMLFormElement>) {
		event.preventDefault()
		setHasSubmitted(true)

		const checked = validateInterestDraft(draft)
		if (!checked.ok) {
			focusFirstIssue(checked.issues[0])
			return
		}

		setPending(true)
		try {
			const result = await startMockWaitlist(checked.interest)
			setOutcome(result)
		} finally {
			setPending(false)
		}
	}

	return (
		<>
			<form
				id="interesse"
				className="kk-form"
				onSubmit={submit}
				noValidate
			>
				<AddressSection
					draft={draft}
					hasSubmitted={hasSubmitted}
					validation={validation}
					onEdit={editAddress}
				/>
				<AllergenSection
					draft={draft}
					hasSubmitted={hasSubmitted}
					validation={validation}
					onAck={editAck}
				/>
				<InterestSection
					hasSubmitted={hasSubmitted}
					validation={validation}
					pending={pending}
					outcome={outcome}
					delivery={nextDelivery}
				/>
			</form>
			<div className="kk-cta">
				<button
					className="kk-pay"
					type="submit"
					form="interesse"
					disabled={pending}
				>
					{pending ? copyNo.interest.pending : copyNo.interest.submit}
				</button>
			</div>
		</>
	)
}

function AddressSection({
	draft,
	hasSubmitted,
	validation,
	onEdit,
}: {
	draft: InterestDraft
	hasSubmitted: boolean
	validation: InterestValidation
	onEdit: (field: AddressField, value: string) => void
}): JSX.Element {
	return (
		<section className="kk-section" id="signup">
			<h2 className="kk-heading">{copyNo.address.heading}</h2>
			<p className="kk-copy">{copyNo.address.body}</p>
			<div className="kk-group">
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

function AllergenSection({
	draft,
	hasSubmitted,
	validation,
	onAck,
}: {
	draft: InterestDraft
	hasSubmitted: boolean
	validation: InterestValidation
	onAck: (value: boolean) => void
}): JSX.Element {
	const issue = visibleIssue(validation, hasSubmitted, 'allergenAck')
	const weekly =
		WEEKLY_BOX_ALLERGENS.length === 0
			? [copyNo.allergens.weeklyEmpty]
			: WEEKLY_BOX_ALLERGENS

	return (
		<section className="kk-section" aria-labelledby="allergener-heading">
			<h2 className="kk-heading" id="allergener-heading">
				{copyNo.allergens.heading}
			</h2>
			<div className="kk-group">
				<div className="kk-row">
					<p className="kk-row-label">
						{copyNo.allergens.weeklyHeading}
					</p>
					<ul className="kk-row-list">
						{weekly.map((item) => (
							<li key={item}>{item}</li>
						))}
					</ul>
				</div>
				<details className="kk-row kk-details">
					<summary>{copyNo.allergens.referenceHeading}</summary>
					<ul className="kk-row-list">
						{EU_ALLERGEN_REFERENCE.map((item) => (
							<li key={item}>{item}</li>
						))}
					</ul>
				</details>
				<p className="kk-row kk-row-note">
					{copyNo.allergens.packaging}
				</p>
				<label className="kk-ack" htmlFor="field-allergenAck">
					<input
						id="field-allergenAck"
						name="allergenAck"
						type="checkbox"
						checked={draft.allergenAck}
						aria-invalid={issue ? true : undefined}
						aria-describedby={issue ? 'allergen-error' : undefined}
						onChange={(event) => onAck(event.target.checked)}
					/>
					<span>{copyNo.allergens.ack}</span>
				</label>
			</div>
			{issue ? (
				<p className="kk-error" id="allergen-error">
					{copyNo.issues[issue.code]}
				</p>
			) : null}
		</section>
	)
}

function InterestSection({
	hasSubmitted,
	validation,
	pending,
	outcome,
	delivery,
}: {
	hasSubmitted: boolean
	validation: InterestValidation
	pending: boolean
	outcome: WaitlistOutcome | null
	delivery: NextDelivery
}): JSX.Element {
	const showErrors = hasSubmitted && !validation.ok

	return (
		<section className="kk-section">
			<h2 className="kk-heading">{copyNo.interest.heading}</h2>
			<p className="kk-copy">{copyNo.interest.body}</p>
			<div className="kk-group">
				<p className="kk-row kk-price">{copyNo.interest.price}</p>
				<p className="kk-row">{copyNo.interest.deposit}</p>
			</div>
			{showErrors ? (
				<div className="kk-summary" role="alert">
					<p className="kk-summary-title">
						{copyNo.interest.errorSummaryHeading}
					</p>
					<p>{copyNo.interest.errorSummaryBody}</p>
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
			<p className="kk-demo">{copyNo.interest.demoDisclosure}</p>
			{pending ? (
				<p className="sr-only" role="status">
					{copyNo.interest.pending}
				</p>
			) : null}
			{outcome?.kind === 'failed' ? (
				<p className="kk-error" role="alert">
					{copyNo.interest.failure}
				</p>
			) : null}
			{outcome?.kind === 'confirmed' ? (
				<div className="kk-success" role="status">
					<p className="kk-success-title">
						{copyNo.interest.successHeading}
					</p>
					<p>{interestSuccessBodyNo(delivery)}</p>
					<p>{interestReferenceNo(outcome.reference)}</p>
				</div>
			) : null}
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
	issue: InterestIssue | null
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
	validation: InterestValidation,
	hasSubmitted: boolean,
	field: InterestIssue['field'],
): InterestIssue | null {
	if (!hasSubmitted || validation.ok) {
		return null
	}
	return validation.issues.find((issue) => issue.field === field) ?? null
}

function focusFirstIssue(issue: InterestIssue) {
	const node = document.getElementById(FIELD_FOCUS_ID[issue.field])
	if (node instanceof HTMLElement) {
		node.focus()
	}
}
