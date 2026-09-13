import { chromium } from 'playwright'
import { mkdir } from 'node:fs/promises'

const out = '/opt/cursor/artifacts'
await mkdir(out, { recursive: true })

const browser = await chromium.launch({ headless: true })
const results = []

function check(name, ok, detail = '') {
	results.push({ name, ok, detail })
	console.log(`${ok ? 'PASS' : 'FAIL'} ${name}${detail ? ` — ${detail}` : ''}`)
}

async function assertNoHorizontalOverflow(page, width) {
	await page.setViewportSize({ width, height: 844 })
	await page.waitForTimeout(200)
	const metrics = await page.evaluate(() => {
		const root = document.documentElement
		const body = document.body
		return {
			rootScroll: root.scrollWidth,
			rootClient: root.clientWidth,
			bodyScroll: body.scrollWidth,
			bodyClient: body.clientWidth,
		}
	})
	const ok =
		metrics.rootScroll <= metrics.rootClient + 1 &&
		metrics.bodyScroll <= metrics.bodyClient + 1
	check(`no overflow ${width}`, ok, JSON.stringify(metrics))
}

const context = await browser.newContext({
	viewport: { width: 390, height: 844 },
	locale: 'nb-NO',
	recordVideo: { dir: out, size: { width: 390, height: 844 } },
})
const page = await context.newPage()

await page.goto('http://127.0.0.1:3456/', { waitUntil: 'networkidle' })
await page.waitForTimeout(400)
await page.screenshot({ path: `${out}/ketokasse_hero.png`, fullPage: false })

const lang = await page.locator('html').getAttribute('lang')
check('lang=nb', lang === 'nb', `lang=${lang}`)

const brand = page.locator('h1.kk-brand')
check('brand visible', await brand.isVisible())
check('brand text', (await brand.innerText()).trim() === 'KetoKasse')

const img = page.locator('img.kk-photo-img')
check('hero image', await img.isVisible())

const headings = await page.locator('h2.kk-heading').allInnerTexts()
check(
	'section order',
	headings.join('|') ===
		[
			'Hva du får',
			'Hvor skal kassen?',
			'Allergener',
			'Meld interesse',
			'Neste levering',
			'Oppskriften er digital',
		].join('|'),
	headings.join(' | '),
)

const bodyText = await page.locator('body').innerText()
check('price 1490', bodyText.includes('1490 kr'))
check('deposit 200', bodyText.includes('+200 kr pant'))
check('monday delivery', bodyText.includes('Levering mandag'))
check('limited space', bodyText.includes('Begrenset plass'))
check('no live payment copy', !/stripe|vipps|betal med/i.test(bodyText))
check(
	'no capacity number',
	!/5 kunder|én kunde per dag|sju leveringsdager/i.test(bodyText),
)
check('weekly allergen placeholder', bodyText.includes('Oppdateres hver uke'))
check(
	'14 allergen helper',
	bodyText.includes('De 14 allergenene') ||
		(await page.locator('.kk-details').count()) > 0,
)
await page.locator('.kk-details summary').click()
check(
	'14 allergen list',
	await page.getByText('Glutenholdig korn', { exact: true }).isVisible(),
)
check('packaging note', bodyText.includes('originale pakninger'))

const allergenBeforeSubmit = await page.evaluate(() => {
	const allergen = document.getElementById('allergener-heading')
	const submit = document.querySelector('.kk-pay')
	if (!allergen || !submit) {
		return false
	}
	return Boolean(
		allergen.compareDocumentPosition(submit) & Node.DOCUMENT_POSITION_FOLLOWING,
	)
})
check('allergen before submit in DOM', allergenBeforeSubmit)

await page.locator('.kk-pay').click()
await page.waitForTimeout(200)
check(
	'validation Norwegian',
	await page.getByText('Sjekk opplysningene').isVisible(),
)
check(
	'allergen required',
	await page.locator('#allergen-error').isVisible(),
)
await page.screenshot({
	path: `${out}/ketokasse_validation.png`,
	fullPage: false,
})

await page.fill('#field-line1', 'Testveien 1')
await page.fill('#field-postalCode', '0150')
await page.fill('#field-city', 'Oslo')
await page.fill('#field-instructions', 'Ved døren')
await page.locator('.kk-pay').click()
await page.waitForTimeout(200)
check(
	'blocks submit without allergen ack',
	await page.locator('#allergen-error').isVisible(),
)

await page.locator('#field-allergenAck').check()
await page.locator('.kk-pay').click()
await page.waitForSelector('.kk-success', { timeout: 5000 })
check('waitlist success', await page.locator('.kk-success').isVisible())
check(
	'waitlist disclosure',
	await page.getByText('Ingen betaling').first().isVisible(),
)
await page.screenshot({ path: `${out}/ketokasse_success.png`, fullPage: true })

await assertNoHorizontalOverflow(page, 390)
await page.screenshot({ path: `${out}/ketokasse_390.png`, fullPage: true })
await assertNoHorizontalOverflow(page, 430)
await page.screenshot({ path: `${out}/ketokasse_430.png`, fullPage: true })

const videoPath = await page.video()?.path()
await context.close()
await browser.close()

const failed = results.filter((r) => !r.ok)
console.log(JSON.stringify({ failed: failed.length, results, videoPath }, null, 2))
process.exit(failed.length ? 1 : 0)
