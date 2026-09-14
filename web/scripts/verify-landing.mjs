import { chromium } from 'playwright'
import { mkdir } from 'node:fs/promises'

const out = '/tmp/ketokasse-verify'
await mkdir(out, { recursive: true })

const browser = await chromium.launch({ headless: true })
const results = []

function check(name, ok, detail = '') {
  results.push({ name, ok, detail })
  console.log(`${ok ? 'PASS' : 'FAIL'} ${name}${detail ? ` — ${detail}` : ''}`)
}

async function assertNoHorizontalOverflow(page, width) {
  await page.setViewportSize({ width, height: 844 })
  await page.locator('h1').waitFor()
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
})
const page = await context.newPage()

await page.goto('http://127.0.0.1:3456/', { waitUntil: 'networkidle' })
await page.locator('h1').waitFor()
await page.screenshot({ path: `${out}/hero.png`, fullPage: false })

const lang = await page.locator('html').getAttribute('lang')
check('lang=nb', lang === 'nb', `lang=${lang}`)

const h1 = page.locator('h1')
check('h1 visible', await h1.isVisible())
check(
  'h1 is hero heading',
  (await h1.innerText()).trim() === 'Den gøyeste måten å spise keto på',
  (await h1.innerText()).trim(),
)

check('no form', (await page.locator('form').count()) === 0)
const bodyText = await page.locator('body').innerText()
check('no Meld interesse', !bodyText.includes('Meld interesse'))
check(
  'no address fields',
  (await page.locator('#field-line1, #field-postalCode, #field-city').count()) ===
    0,
)

const headerCta = page.locator('header a.kk-cta-pill')
check('header Last ned is a', (await headerCta.count()) === 1)
check(
  'header Last ned has no href',
  (await headerCta.getAttribute('href')) === null,
  `href=${await headerCta.getAttribute('href')}`,
)
check(
  'header Last ned aria-disabled',
  (await headerCta.getAttribute('aria-disabled')) === 'true',
  `aria-disabled=${await headerCta.getAttribute('aria-disabled')}`,
)

const badges = page.locator('a.kk-store')
const badgeCount = await badges.count()
check('App Store badges present', badgeCount >= 1, `count=${badgeCount}`)
for (let i = 0; i < badgeCount; i += 1) {
  const href = await badges.nth(i).getAttribute('href')
  check(`App Store badge ${i} has no href`, href === null, `href=${href}`)
}

const headings = await page.locator('h2').allInnerTexts()
const headingLine = headings.map((text) => text.trim()).join('|')
check(
  'section h2 texts',
  headingLine ===
    'fem middager|mandagslevering|oppskrift i appen|keto hvor som helst',
  headingLine,
)

const family = await h1.evaluate((el) => getComputedStyle(el).fontFamily)
check('Nunito in h1 font-family', /nunito/i.test(family), family)

await assertNoHorizontalOverflow(page, 390)
await page.screenshot({ path: `${out}/390.png`, fullPage: true })
await assertNoHorizontalOverflow(page, 1280)
await page.screenshot({ path: `${out}/1280.png`, fullPage: true })

await context.close()
await browser.close()

const failed = results.filter((r) => !r.ok)
console.log(JSON.stringify({ failed: failed.length, results }, null, 2))
process.exit(failed.length ? 1 : 0)
