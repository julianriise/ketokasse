import { readFileSync, writeFileSync, readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const publicDir = join(root, 'public')
const outJpg = join(publicDir, 'ketokasse-hero.jpg')

const parts = readdirSync(publicDir)
	.filter((name) => /^hero-\d{2}\.b64$/.test(name))
	.sort()

if (parts.length === 0) {
	console.error('missing public/hero-NN.b64 parts')
	process.exit(1)
}

const b64 = parts.map((name) => readFileSync(join(publicDir, name), 'utf8')).join('')
writeFileSync(outJpg, Buffer.from(b64, 'base64'))
console.log('wrote', outJpg, 'from', parts.length, 'parts')
