import { readFileSync, writeFileSync, readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const publicDir = join(root, 'public')
const parts = readdirSync(publicDir)
	.filter((name) => name.startsWith('hero-b64-') && name.endsWith('.part'))
	.sort()
if (parts.length === 0) {
	console.error('missing public/hero-b64-*.part')
	process.exit(1)
}
const b64 = parts.map((name) => readFileSync(join(publicDir, name), 'utf8')).join('')
writeFileSync(join(publicDir, 'ketokasse-hero.png'), Buffer.from(b64, 'base64'))
console.log('wrote public/ketokasse-hero.png from', parts.length, 'parts')
