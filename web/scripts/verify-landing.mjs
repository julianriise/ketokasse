import { chromium } from 'playwright'
import { mkdir } from 'node:fs/promises'

const out = '/opt/cursor/artifacts'
await mkdir(out, { recursive: true })

const browser = await chromium.launch({ headless: true })
const context = await browser.newContext({
	viewport: { width: 1280, height: 900 },
	locale: 'nb-NO',
	recordVideo: { dir: out, size: { width: 1280, height: 900 } },
})
const page = await context.newPage()
const results = []

function check(name, ok, detail = '') {
	results.push({ name, ok, detail })
	console.log(`${ok ? 'PASS' : 'FAIL'} ${name}${detail ? ` — ${detail}` : ''}`)
}

await page.goto('http://127.0.0.1:3456/', { waitUntil: 'networkidle' })
await page.waitForTimeout(600)
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
			'Velg din faste leveringsdag',
			'Hvor skal vi levere?',
			'Start ukesleveringen',
			'Din neste levering',
			'KetoKasse på iPhone',
		].join('|'),
	headings.join(' | '),
)

const wed = page.locator('label.kk-day').filter({ hasText: 'Onsdag' })
const sat = page.locator('label.kk-day').filter({ hasText: 'Lørdag' })
check('onsdag taken', (await wed.getAttribute('data-taken')) === 'true')
check('lørdag taken', (await sat.getAttribute('data-taken')) === 'true')
check('onsdag disabled', await wed.locator('input').isDisabled())

await page.locator('label.kk-day').filter({ hasText: 'Mandag' }).click()
await page.waitForTimeout(300)
const nextText = await page.locator('.kk-next-sentence').innerText()
check('next delivery updates', nextText.includes('Din neste levering er'), nextText)
await page.screenshot({ path: `${out}/ketokasse_day_selected.png`, fullPage: false })

await page.locator('.kk-pay').click()
await page.waitForTimeout(200)
check(
	'validation Norwegian',
	await page.getByText('Sjekk opplysningene').isVisible(),
)
await page.screenshot({ path: `${out}/ketokasse_validation.png`, fullPage: false })

await page.fill('#field-line1', 'Testveien 1')
await page.fill('#field-postalCode', '0150')
await page.fill('#field-city', 'Oslo')
await page.fill('#field-instructions', 'Ved døren')
await page.locator('.kk-pay').click()
await page.waitForSelector('.kk-success', { timeout: 5000 })
check('checkout success', await page.locator('.kk-success').isVisible())
check(
	'demo disclosure',
	await page.getByText('Dette er en demo').isVisible(),
)
await page.screenshot({ path: `${out}/ketokasse_success.png`, fullPage: true })

await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight))
await page.waitForTimeout(400)
check('ios coming soon', await page.getByText('Kommer snart i App Store').isVisible())

const videoPath = await page.video()?.path()
await context.close()
await browser.close()

const failed = results.filter((r) => !r.ok)
console.log(JSON.stringify({ failed: failed.length, results, videoPath }, null, 2))
process.exit(failed.length ? 1 : 0)
