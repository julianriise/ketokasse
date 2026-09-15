#!/usr/bin/env python3
"""Apple rejects App Store icons that contain an alpha channel."""

from __future__ import annotations

import sys
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "KetoKasse/Assets.xcassets/Logo.imageset/logo.png"
DEST = ROOT / "KetoKasse/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
FOREST = (0x00, 0x47, 0x3C)
OLD_GREEN = (0x58, 0xCC, 0x02)
WHITE = (0xFF, 0xFF, 0xFF)
BLUSH = (0xF9, 0xDF, 0xCE)
SIZE = 1024


def near_count(counts: Counter, target: tuple[int, int, int], tol: int = 8) -> int:
    tr, tg, tb = target
    return sum(
        n
        for (r, g, b), n in counts.items()
        if abs(r - tr) <= tol and abs(g - tg) <= tol and abs(b - tb) <= tol
    )


def rasterize(path: Path, size: int) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    if image.size != (size, size):
        image = image.resize((size, size), Image.Resampling.LANCZOS)
    return image


def flatten(mascot: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", (SIZE, SIZE), FOREST + (255,))
    if mascot.size != (SIZE, SIZE):
        mascot = mascot.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    return Image.alpha_composite(canvas, mascot).convert("RGB")


def verify(image: Image.Image) -> None:
    if image.size != (SIZE, SIZE):
        raise SystemExit(f"AppIcon size is {image.size}, expected {(SIZE, SIZE)}")
    if image.mode != "RGB":
        raise SystemExit(f"AppIcon mode is {image.mode}, expected RGB")
    counts = Counter(image.getdata())
    total = SIZE * SIZE
    old = near_count(counts, OLD_GREEN)
    forest = near_count(counts, FOREST)
    white = near_count(counts, WHITE)
    blush = near_count(counts, BLUSH)
    if old / total > 0.01:
        raise SystemExit(f"old #58CC02 still covers {100 * old / total:.1f}%")
    if forest == 0 or white == 0 or blush == 0:
        raise SystemExit("missing forest, white, or blush in AppIcon")
    print(
        f"ok  {SIZE}x{SIZE} RGB forest={100 * forest / total:.1f}% "
        f"white={100 * white / total:.1f}% blush={100 * blush / total:.1f}% "
        f"old58CC02={100 * old / total:.1f}%"
    )


def main() -> None:
    if not LOGO.is_file():
        raise SystemExit(f"missing {LOGO}")
    mascot = rasterize(LOGO, SIZE)
    icon = flatten(mascot)
    DEST.parent.mkdir(parents=True, exist_ok=True)
    icon.save(DEST, format="PNG")
    verify(Image.open(DEST))


if __name__ == "__main__":
    sys.exit(main())
