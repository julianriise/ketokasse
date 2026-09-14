#!/usr/bin/env python3
"""Rebuild AppIcon.png from Logo.imageset/logo.svg on opaque KKColor.forest.

Apple rejects App Store icons that contain an alpha channel.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "KetoKasse/Assets.xcassets/Logo.imageset/logo.svg"
DEST = ROOT / "KetoKasse/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
FOREST = (0x00, 0x47, 0x3C)
OLD_GREEN = (0x58, 0xCC, 0x02)
LIME = (0xE6, 0xFF, 0x55)
LIME_LID = (0x2D, 0x6B, 0x52)
SIZE = 1024


def near_count(counts: Counter, target: tuple[int, int, int], tol: int = 8) -> int:
    tr, tg, tb = target
    return sum(
        n
        for (r, g, b), n in counts.items()
        if abs(r - tr) <= tol and abs(g - tg) <= tol and abs(b - tb) <= tol
    )


def rasterize(svg: Path, size: int) -> Image.Image:
    with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
        cmd = [
            "rsvg-convert",
            "--width",
            str(size),
            "--height",
            str(size),
            "--keep-aspect-ratio",
            str(svg),
            "--output",
            tmp.name,
        ]
        subprocess.run(cmd, check=True)
        return Image.open(tmp.name).convert("RGBA")


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
    lime = near_count(counts, LIME)
    lid = near_count(counts, LIME_LID)
    if old / total > 0.01:
        raise SystemExit(f"old #58CC02 still covers {100 * old / total:.1f}%")
    if forest == 0 or lime == 0:
        raise SystemExit("missing forest or lime in AppIcon")
    print(
        f"ok  {SIZE}x{SIZE} RGB forest={100 * forest / total:.1f}% "
        f"limeLid={100 * lid / total:.1f}% lime={100 * lime / total:.1f}% "
        f"old58CC02={100 * old / total:.1f}%"
    )


def main() -> None:
    if not LOGO.is_file():
        raise SystemExit(f"missing {LOGO}")
    try:
        mascot = rasterize(LOGO, SIZE)
    except FileNotFoundError:
        raise SystemExit("rsvg-convert is required") from None
    except subprocess.CalledProcessError as error:
        raise SystemExit(f"rsvg-convert failed: {error}") from None
    icon = flatten(mascot)
    DEST.parent.mkdir(parents=True, exist_ok=True)
    icon.save(DEST, format="PNG")
    verify(Image.open(DEST))


if __name__ == "__main__":
    sys.exit(main())
