#!/usr/bin/env python3
"""Generate the app icon, the maskable variants and the favicon.

The web build shipped Flutter's default blue logo, which is the first thing
anyone sees when they install the app or open a tab. This draws the brand mark
instead: the map pin from section 15 of the brand guidelines, in white on Trust
Burgundy.

The pin is drawn analytically rather than traced from the Dart painter — one
circle for the head and the two tangent lines down to the point, which is the
same construction `job_marker.dart` uses and the reason the silhouette matches.

Standard library only, and RGBA rather than the RGB writer in
`generate_placeholder_assets.py`, because an icon with square corners on a
light background looks broken on iOS and on a browser tab.

Usage:
    python3 tool/generate_app_icons.py
"""

from __future__ import annotations

import math
import pathlib
import struct
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
WEB_DIR = ROOT / "web"
ICON_DIR = WEB_DIR / "icons"

# Brand palette, sections 5-6 of the brand guidelines.
TRUST_BURGUNDY = (0x7A, 0x26, 0x3A)
WHITE = (0xFF, 0xFF, 0xFF)

# Samples per axis. 4 is enough to keep the pin's curve clean at 192px and
# costs nothing at these sizes.
SUPERSAMPLE = 4


def write_png(path: pathlib.Path, size: int, pixels: list[bytearray]) -> None:
    """Write 8-bit RGBA rows as a PNG. Minimal encoder, filter type 0."""
    raw = bytearray()
    for row in pixels:
        raw.append(0)  # filter: none
        raw.extend(row)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )


def in_rounded_square(x: float, y: float, size: float, radius: float) -> bool:
    """Whether a point is inside a square with rounded corners."""
    cx = min(max(x, radius), size - radius)
    cy = min(max(y, radius), size - radius)
    return (x - cx) ** 2 + (y - cy) ** 2 <= radius**2


def tangent_points(cx: float, cy: float, r: float, tip: float):
    """Where the pin's straight edges meet its round head.

    The apex, the centre and a tangent point form a right angle at the tangent
    point, so the angle at the centre is arccos(r / d). Deriving the join this
    way is what stops the point looking bolted on: the straight edge leaves the
    curve along it rather than crossing it.

    Returns the half-width at the join and the height it sits at.
    """
    ratio = r / (tip - cy)
    return r * math.sqrt(1 - ratio**2), cy + r * ratio


def in_pin(
    x: float,
    y: float,
    cx: float,
    cy: float,
    r: float,
    tip: float,
    tangents: tuple[float, float],
) -> bool:
    """Whether a point is inside a map pin: a circle union a tangent triangle.

    A triangle, not the cone from the apex. The cone carries on past the
    tangent points and flares out either side of the head, which turns the pin
    into a funnel.
    """
    if (x - cx) ** 2 + (y - cy) ** 2 <= r**2:
        return True

    half_width, join_y = tangents
    if y < join_y or y > tip:
        return False

    # Full width where the edges leave the head, nothing at the point.
    return abs(x - cx) <= half_width * (1 - (y - join_y) / (tip - join_y))


def build_icon(size: int, *, full_bleed: bool, pin_scale: float) -> list[bytearray]:
    """One icon: burgundy ground, white pin.

    `full_bleed` squares the corners for the maskable variants, where the
    launcher applies its own shape and a rounded source would be clipped twice.
    `pin_scale` shrinks the mark for those same variants, so it survives the
    aggressive circular masks some launchers use.
    """
    radius = 0 if full_bleed else size * 0.22

    # The same proportions as the marker on the map (job_marker.dart): a head
    # of 0.39 of the pin's height, with the point reaching the bottom edge. A
    # longer point reads as a funnel rather than a pin.
    pin_height = size * pin_scale
    head_radius = pin_height * 0.39
    top = (size - pin_height) / 2
    centre_x = size / 2
    head_y = top + head_radius
    tip_y = top + pin_height
    tangents = tangent_points(centre_x, head_y, head_radius, tip_y)

    step = 1.0 / SUPERSAMPLE
    offset = step / 2
    total = SUPERSAMPLE * SUPERSAMPLE

    rows = []
    for py in range(size):
        row = bytearray()
        for px in range(size):
            ground = 0
            mark = 0
            for sy in range(SUPERSAMPLE):
                y = py + offset + sy * step
                for sx in range(SUPERSAMPLE):
                    x = px + offset + sx * step
                    if full_bleed or in_rounded_square(x, y, size, radius):
                        ground += 1
                        if in_pin(
                            x, y, centre_x, head_y, head_radius, tip_y, tangents
                        ):
                            mark += 1

            alpha = round(255 * ground / total)
            if alpha == 0:
                row.extend((0, 0, 0, 0))
                continue

            # Coverage of the mark within the ground that is actually painted.
            t = mark / ground
            colour = tuple(
                round(TRUST_BURGUNDY[i] + (WHITE[i] - TRUST_BURGUNDY[i]) * t)
                for i in range(3)
            )
            row.extend((*colour, alpha))
        rows.append(row)

    return rows


def main() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)

    targets = [
        (ICON_DIR / "Icon-192.png", 192, False, 0.58),
        (ICON_DIR / "Icon-512.png", 512, False, 0.58),
        # Maskable icons are cropped by the launcher, so the mark stays inside
        # the 80% safe zone the spec guarantees.
        (ICON_DIR / "Icon-maskable-192.png", 192, True, 0.44),
        (ICON_DIR / "Icon-maskable-512.png", 512, True, 0.44),
        # A browser tab renders this at 16px, where a rounded corner is one
        # pixel of mush — square it and let the pin carry the recognition.
        (WEB_DIR / "favicon.png", 32, True, 0.66),
    ]

    for path, size, full_bleed, pin_scale in targets:
        write_png(path, size, build_icon(size, full_bleed=full_bleed, pin_scale=pin_scale))
        print(f"wrote {path.relative_to(ROOT)} ({size}x{size})")


if __name__ == "__main__":
    main()
