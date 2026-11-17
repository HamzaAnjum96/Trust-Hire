#!/usr/bin/env python3
"""Generate the POC's placeholder photo and voice-note assets.

The seed data references photos and voice notes so the job details screen has
something to display. Real photography is out of scope for a POC, and stock
imagery would contradict the brand guidelines (section 16 rules out staged and
AI-generated-looking material), so this produces *obvious placeholders* drawn
from the brand palette instead — clearly synthetic, never passing as real work.

Voice notes are amplitude-modulated tones, not speech. They exist so playback
and the waveform display can be demonstrated end to end.

Standard library only — no Pillow or numpy in the build environment.

Usage:
    python3 tool/generate_placeholder_assets.py
"""

from __future__ import annotations

import math
import pathlib
import struct
import wave
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
IMAGE_DIR = ROOT / "assets" / "images" / "jobs"
AUDIO_DIR = ROOT / "assets" / "audio"

# Brand palette v0.2 (0.24): ink and turmeric on lime-wash, with peacock.
# The names say the role each hue plays in these graphics.
PEACOCK = (0x0B, 0x6E, 0x6B)
SLATE_BLUE = (0x3B, 0x4A, 0x5A)
TURMERIC = (0xF2, 0xA9, 0x00)
LIME_WASH = (0xF3, 0xF5, 0xF7)
INK = (0x16, 0x20, 0x2A)

WIDTH, HEIGHT = 800, 600


def mix(a, b, t):
    """Linear blend between two RGB tuples."""
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def write_png(path: pathlib.Path, rows: list[bytearray]) -> None:
    """Write 8-bit RGB rows as a PNG. Minimal encoder, filter type 0."""
    raw = bytearray()
    for row in rows:
        raw.append(0)  # filter: none
        raw.extend(row)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 2, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def build_image(seed: int, accent, base) -> list[bytearray]:
    """A soft diagonal gradient with a banded overlay.

    Distinct per seed so photos in a gallery are visibly different, but
    unmistakably graphic rather than photographic.
    """
    rows: list[bytearray] = []
    band_period = 90 + (seed % 4) * 30
    angle = 0.35 + (seed % 5) * 0.12

    for y in range(HEIGHT):
        row = bytearray()
        for x in range(WIDTH):
            # Diagonal gradient across the tile.
            t = ((x * angle + y * (1 - angle)) / (WIDTH * angle + HEIGHT)) % 1.0
            colour = mix(base, accent, t * 0.55)

            # Wide diagonal bands, subtle enough to stay calm.
            band = ((x + y * 2 + seed * 57) % band_period) / band_period
            if band < 0.16:
                colour = mix(colour, accent, 0.22)

            # Corner vignette keeps the tile from feeling flat.
            dx = (x - WIDTH / 2) / (WIDTH / 2)
            dy = (y - HEIGHT / 2) / (HEIGHT / 2)
            vignette = min(1.0, (dx * dx + dy * dy) * 0.28)
            colour = mix(colour, SLATE_BLUE, vignette * 0.18)

            row.extend(colour)
        rows.append(row)
    return rows


def write_wav(path: pathlib.Path, seconds: float, seed: int) -> None:
    """An amplitude-modulated tone standing in for a voice note.

    The envelope varies in a speech-like cadence so the Sprint 2 waveform has
    something plausible to render.
    """
    rate = 22050
    frames = int(rate * seconds)
    base_hz = 150 + (seed % 5) * 25

    data = bytearray()
    for n in range(frames):
        t = n / rate

        # Syllable-rate envelope, roughly 3.5 per second, plus a slow fade.
        syllable = 0.5 + 0.5 * math.sin(2 * math.pi * 3.5 * t + seed)
        phrase = 0.55 + 0.45 * math.sin(2 * math.pi * 0.4 * t)
        edge = min(1.0, t / 0.08, max(0.0, (seconds - t) / 0.12))
        envelope = syllable * phrase * edge * 0.42

        # A couple of harmonics so it is not a bare sine.
        sample = (
            math.sin(2 * math.pi * base_hz * t)
            + 0.4 * math.sin(2 * math.pi * base_hz * 2 * t)
            + 0.2 * math.sin(2 * math.pi * base_hz * 3 * t)
        ) / 1.6

        data.extend(struct.pack("<h", int(sample * envelope * 32767)))

    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(rate)
        out.writeframes(bytes(data))


PHOTOS = [
    ("plumbing-01", TURMERIC, LIME_WASH),
    ("plumbing-02", PEACOCK, LIME_WASH),
    ("electrical-01", TURMERIC, LIME_WASH),
    ("painting-01", PEACOCK, LIME_WASH),
    ("painting-02", TURMERIC, LIME_WASH),
    ("carpentry-01", SLATE_BLUE, LIME_WASH),
    ("ac-repair-01", PEACOCK, LIME_WASH),
    ("masonry-01", TURMERIC, LIME_WASH),
    ("delivery-01", SLATE_BLUE, LIME_WASH),
    ("cleaning-01", PEACOCK, LIME_WASH),
]

VOICE_NOTES = [
    ("voice-01", 7.5),
    ("voice-02", 11.0),
    ("voice-03", 5.0),
    ("voice-04", 14.5),
    ("voice-05", 9.0),
    ("voice-06", 6.5),
]


def main() -> None:
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)

    for index, (name, accent, base) in enumerate(PHOTOS):
        target = IMAGE_DIR / f"{name}.png"
        write_png(target, build_image(index, accent, base))
        print(f"wrote {target.relative_to(ROOT)}")

    for index, (name, seconds) in enumerate(VOICE_NOTES):
        target = AUDIO_DIR / f"{name}.wav"
        write_wav(target, seconds, index)
        print(f"wrote {target.relative_to(ROOT)} ({seconds}s)")


if __name__ == "__main__":
    main()
