import { spawnSync } from 'node:child_process'
import { readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '../..')

const files = [
	'web/public/visuals/anywhere.svg',
	'web/public/visuals/hero.svg',
	'web/public/visuals/logo.svg',
	'web/public/visuals/monday.svg',
	'web/public/visuals/recipes.svg',
	'ios/KetoKasse/Assets.xcassets/Logo.imageset/logo.svg',
	'ios/KetoKasse/Resources/Visuals/logo.svg',
]

const map = [
	['#58CC02', '#00473C'],
	['#46A302', '#0E150E'],
	['#1B4332', '#00473C'],
	['#7AC70C', '#2D6B52'],
	['#89E219', '#E6FF55'],
	['#FFC800', '#E6FF55'],
	['#CE82FF', '#A61846'],
	['#1CB0F6', '#00473C'],
	['#00CD9C', '#2D6B52'],
	['#F59E0B', '#E59700'],
	['#FF8AA0', '#F9DFCE'],
	['#DDF4FF', '#D6E9E9'],
	['#E8F8D8', '#D8E5D6'],
	['#FFF0E5', '#F9DFCE'],
]

const hex = '#[0-9A-Fa-f]{6}'
const pattern = new RegExp(hex, 'g')
const lookup = new Map(map.map(([from, to]) => [from.toUpperCase(), to.toUpperCase()]))

for (const rel of files) {
	const path = join(root, rel)
	let src
	try {
		src = readFileSync(path, 'utf8')
	} catch (error) {
		console.log(rel, 'skip', error.code)
		continue
	}
	const out = src.replace(pattern, (token) => lookup.get(token.toUpperCase()) ?? token)
	writeFileSync(path, out)
	console.log(rel, src === out ? 'unchanged' : 'updated')
}

const render = spawnSync(
	'python3',
	[join(root, 'ios/scripts/render-appicon.py')],
	{ stdio: 'inherit' },
)
if (render.error || render.status !== 0) {
	console.log('ios AppIcon not rebuilt; run python3 ios/scripts/render-appicon.py')
}
