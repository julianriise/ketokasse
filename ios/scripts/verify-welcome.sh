#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
OUT="${1:-/tmp/ketokasse-welcome.png}"
ON="${SWEETPAD_ON:-iPhone 17}"

cd "$ROOT"

sweetpad --non-interactive simulator boot --wait -- "$ON"

sweetpad --non-interactive build --scheme KetoKasse --on "$ON"
sweetpad --non-interactive run --scheme KetoKasse --on "$ON" --no-logs --detach

sleep 2

sweetpad --non-interactive simulator screenshot --output-file "$OUT" -- "$ON"
echo "screenshot $OUT"
