import { spawnSync } from 'node:child_process'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '../..')

const render = spawnSync(
	'python3',
	[join(root, 'ios/scripts/render-appicon.py')],
	{ stdio: 'inherit' },
)
if (render.error || render.status !== 0) {
	console.log('ios AppIcon not rebuilt; run python3 ios/scripts/render-appicon.py')
}
