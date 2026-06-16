#!/usr/bin/env python3
"""Procedural attack-VFX projectile strips for Dragon Forge.

Renders a 1024x256 horizontal strip of 4 frames (256x256 each) per attack,
telling the launch -> travel -> peak -> impact story described in
handoff/ATTACK_VFX_SPRITE_GUIDE.md. These are placeholders that the battle
engine plays as animated travelling projectiles; high-fidelity hand-art from
tools/asset_gen/gen_vfx_sheets.sh (fal pipeline) drops in over the same
filenames + format when a fal key is available.

Output: public/assets/vfx/vfx_<move>.png  (RGBA, transparent background)
Run:    python3 tools/asset_gen/make_vfx_strips.py
"""
from __future__ import annotations

import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

S = 256          # frame size
FRAMES = 4
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT_DIR = os.path.join(ROOT, "public", "assets", "vfx")

# Element palettes (core = hot/bright centre, primary = body, glow = halo, dark = base)
PAL = {
    "fire":    dict(core=(255, 244, 196), primary=(255, 102, 34),  glow=(255, 150, 70),  dark=(204, 34, 0)),
    "ice":     dict(core=(232, 250, 255), primary=(68, 170, 255),  glow=(140, 212, 255), dark=(32, 110, 180)),
    "storm":   dict(core=(246, 236, 255), primary=(170, 102, 255), glow=(205, 152, 255), dark=(96, 51, 170)),
    "stone":   dict(core=(244, 226, 190), primary=(170, 136, 68),  glow=(214, 182, 112), dark=(94, 72, 40)),
    "venom":   dict(core=(222, 255, 198), primary=(68, 204, 68),   glow=(130, 238, 118), dark=(34, 136, 34)),
    "shadow":  dict(core=(214, 162, 234), primary=(136, 68, 170),  glow=(182, 112, 212), dark=(51, 0, 68)),
    "void":    dict(core=(206, 184, 255), primary=(122, 92, 222),  glow=(172, 142, 255), dark=(40, 20, 84)),
    "light":   dict(core=(255, 253, 228), primary=(255, 220, 120), glow=(255, 242, 184), dark=(214, 160, 40)),
    "neutral": dict(core=(255, 255, 255), primary=(202, 202, 212), glow=(236, 236, 246), dark=(112, 112, 124)),
}

# move -> (archetype, element)
MOVES = {
    "magma_breath":     ("projectile", "fire"),
    "flame_wall":       ("wall",       "fire"),
    "frost_bite":       ("shard",      "ice"),
    "blizzard":         ("wall",       "ice"),
    "lightning_strike": ("bolt",       "storm"),
    "thunder_clap":     ("ring",       "storm"),
    "rock_slide":       ("cluster",    "stone"),
    "earthquake":       ("cluster",    "stone"),
    "acid_spit":        ("projectile", "venom"),
    "toxic_cloud":      ("cloud",      "venom"),
    "shadow_strike":    ("slash",      "shadow"),
    "void_pulse":       ("ring",       "void"),
    "void_rift":        ("rift",       "void"),
    "radiant_beam":     ("beam",       "light"),
    "solar_flare":      ("cloud",      "light"),
}


def soft_circle(size, color, radius, blur, alpha=255, center=None):
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center or (size // 2, size // 2)
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=color + (alpha,))
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    return layer


def add(base, layer):
    return Image.alpha_composite(base, layer)


def glow_orb(pal, cx, cy, r, intensity=1.0):
    """A bright-cored energy orb with a soft halo."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    layer = add(layer, soft_circle(S, pal["glow"], int(r * 1.6), int(r * 0.7), int(150 * intensity), (cx, cy)))
    layer = add(layer, soft_circle(S, pal["primary"], int(r * 1.05), int(r * 0.35), int(220 * intensity), (cx, cy)))
    layer = add(layer, soft_circle(S, pal["core"], int(r * 0.55), int(r * 0.16), int(255 * intensity), (cx, cy)))
    return layer


def particles(pal, n, cx, cy, spread, rng, size=(3, 9), behind=True):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    for _ in range(n):
        ang = rng.uniform(0, 2 * math.pi)
        dist = rng.uniform(0, spread)
        px = cx + math.cos(ang) * dist - (spread * 0.4 if behind else 0)
        py = cy + math.sin(ang) * dist
        r = rng.randint(*size)
        col = rng.choice([pal["glow"], pal["primary"], pal["core"]])
        layer = add(layer, soft_circle(S, col, r, r * 0.6, rng.randint(120, 230), (px, py)))
    return layer


def frame_projectile(f, pal, rng):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S // 2, S // 2
    if f < 3:
        r = [26, 40, 52][f]
        inten = [0.75, 0.95, 1.1][f]
        # trail behind (projectile travels to the right -> trail on the left)
        for i in range(1, 5):
            tx = cx - i * (10 + f * 5)
            tr = max(4, r - i * 7)
            img = add(img, soft_circle(S, pal["primary"], tr, tr * 0.6, max(20, 120 - i * 22), (tx, cy + rng.randint(-6, 6))))
        img = add(img, glow_orb(pal, cx, cy, r, inten))
        img = add(img, particles(pal, 6 + f * 3, cx, cy, 30 + f * 12, rng))
    else:  # impact burst
        img = add(img, soft_circle(S, pal["glow"], 90, 30, 150, (cx, cy)))
        img = add(img, soft_circle(S, pal["core"], 40, 12, 230, (cx, cy)))
        img = add(img, particles(pal, 26, cx, cy, 95, rng, size=(4, 12), behind=False))
    return img


def frame_shard(f, pal, rng):
    """Angular ice shard projectile + frost trail."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S // 2, S // 2
    d = ImageDraw.Draw(img)
    if f < 3:
        scale = [0.6, 0.85, 1.05][f]
        L = 70 * scale
        # diamond/shard pointing right
        pts = [(cx + L, cy), (cx, cy - 22 * scale), (cx - L * 0.7, cy), (cx, cy + 22 * scale)]
        glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(glow).polygon(pts, fill=pal["glow"] + (200,))
        img = add(img, glow.filter(ImageFilter.GaussianBlur(10)))
        d.polygon(pts, fill=pal["primary"] + (235,), outline=pal["core"] + (255,))
        inner = [(cx + L * 0.7, cy), (cx, cy - 11 * scale), (cx - L * 0.3, cy), (cx, cy + 11 * scale)]
        d.polygon(inner, fill=pal["core"] + (220,))
        img = add(img, particles(pal, 5 + f * 2, cx - 30, cy, 24 + f * 10, rng))
    else:
        img = add(img, soft_circle(S, pal["glow"], 80, 26, 150, (cx, cy)))
        for _ in range(14):
            ang = rng.uniform(0, 2 * math.pi)
            dist = rng.uniform(20, 95)
            ex, ey = cx + math.cos(ang) * dist, cy + math.sin(ang) * dist
            ImageDraw.Draw(img).line([(cx, cy), (ex, ey)], fill=pal["core"] + (210,), width=rng.randint(2, 4))
        img = add(img, soft_circle(S, pal["core"], 30, 9, 230, (cx, cy)))
    return img


def frame_wall(f, pal, rng):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx = S // 2
    width = [40, 80, 120, 150][f]
    for i in range(14):
        y = int(S * (i + 0.5) / 14)
        wob = rng.randint(-18, 18)
        r = rng.randint(int(width * 0.28), int(width * 0.5))
        img = add(img, soft_circle(S, pal["primary"], r, r * 0.5, 150, (cx + wob, y)))
    img = add(img, soft_circle(S, pal["glow"], width, width * 0.4, 110, (cx, S // 2)))
    # bright leading edge
    edge = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(edge).rectangle([cx + width * 0.35, 14, cx + width * 0.5, S - 14], fill=pal["core"] + (190,))
    img = add(img, edge.filter(ImageFilter.GaussianBlur(6)))
    img = add(img, particles(pal, 8 + f * 4, cx, S // 2, width, rng, behind=False))
    return img


def frame_bolt(f, pal, rng):
    """Jagged lightning bolt that builds left->right then flashes."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rng.seed(7 + f)
    progress = [0.45, 0.8, 1.0, 1.0][f]
    x = 12
    y = S // 2
    pts = [(x, y)]
    while x < S * progress:
        x += rng.randint(20, 38)
        y = S // 2 + rng.randint(-58, 58)
        pts.append((min(x, S - 8), y))
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).line(pts, fill=pal["glow"] + (220,), width=16, joint="curve")
    img = add(img, glow.filter(ImageFilter.GaussianBlur(9)))
    ImageDraw.Draw(img).line(pts, fill=pal["primary"] + (240,), width=7, joint="curve")
    ImageDraw.Draw(img).line(pts, fill=pal["core"] + (255,), width=3, joint="curve")
    if f == 3:
        ex, ey = pts[-1]
        img = add(img, soft_circle(S, pal["glow"], 70, 24, 170, (ex, ey)))
        img = add(img, soft_circle(S, pal["core"], 30, 10, 235, (ex, ey)))
    return img


def frame_beam(f, pal, rng):
    """Straight radiant beam thickening across the frame."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cy = S // 2
    h = [10, 24, 40, 50][f]
    length = int(S * [0.5, 0.85, 1.0, 1.0][f])
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).rectangle([0, cy - h, length, cy + h], fill=pal["glow"] + (180,))
    img = add(img, glow.filter(ImageFilter.GaussianBlur(12)))
    ImageDraw.Draw(img).rectangle([0, cy - h * 0.55, length, cy + h * 0.55], fill=pal["primary"] + (220,))
    ImageDraw.Draw(img).rectangle([0, cy - h * 0.22, length, cy + h * 0.22], fill=pal["core"] + (245,))
    if f >= 2:
        img = add(img, soft_circle(S, pal["core"], 34, 12, 220, (length - 10, cy)))
        img = add(img, soft_circle(S, pal["glow"], 64, 22, 150, (length - 10, cy)))
    return img


def frame_ring(f, pal, rng):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S // 2, S // 2
    r = [22, 56, 92, 116][f]
    w = [16, 14, 11, 8][f]
    a = [230, 200, 160, 110][f]
    ring = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(ring).ellipse([cx - r, cy - r, cx + r, cy + r], outline=pal["glow"] + (a,), width=w)
    img = add(img, ring.filter(ImageFilter.GaussianBlur(5)))
    ring2 = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(ring2).ellipse([cx - r, cy - r, cx + r, cy + r], outline=pal["core"] + (min(255, a + 30),), width=max(2, w // 2))
    img = add(img, ring2)
    core_r = [20, 16, 12, 9][f]
    img = add(img, glow_orb(pal, cx, cy, core_r, 1.0))
    return img


def frame_cluster(f, pal, rng):
    """Stone chunks tumbling, then a dust burst. Solid (non-glow) bodies."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rng.seed(11 + f)
    cx, cy = S // 2, S // 2
    if f < 3:
        n = [3, 5, 6][f]
        spread = [30, 55, 75][f]
        for _ in range(n):
            px = cx + rng.randint(-spread, spread)
            py = cy + rng.randint(-spread, spread)
            sz = rng.randint(20, 40)
            rot = rng.uniform(0, math.pi)
            pts = []
            sides = rng.randint(5, 7)
            for s in range(sides):
                ang = rot + s * 2 * math.pi / sides
                rad = sz * rng.uniform(0.7, 1.0)
                pts.append((px + math.cos(ang) * rad, py + math.sin(ang) * rad))
            ImageDraw.Draw(img).polygon(pts, fill=pal["dark"] + (255,))
            hi = [(px + math.cos(rot + s * 2 * math.pi / sides) * sz * 0.6,
                   py + math.sin(rot + s * 2 * math.pi / sides) * sz * 0.6) for s in range(sides)]
            ImageDraw.Draw(img).polygon(hi[:sides], fill=pal["primary"] + (220,))
        img = add(img, particles(pal, 6 + f * 3, cx, cy, spread, rng, size=(2, 5)))
    else:
        # dust + impact burst
        img = add(img, soft_circle(S, pal["glow"], 86, 30, 140, (cx, cy)))
        for _ in range(22):
            ang = rng.uniform(0, 2 * math.pi)
            dist = rng.uniform(20, 100)
            px, py = cx + math.cos(ang) * dist, cy + math.sin(ang) * dist
            r = rng.randint(4, 12)
            img = add(img, soft_circle(S, rng.choice([pal["primary"], pal["glow"], pal["dark"]]), r, r * 0.6, 190, (px, py)))
    return img


def frame_cloud(f, pal, rng):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rng.seed(13 + f)
    cx, cy = S // 2, S // 2
    n = [6, 10, 14, 16][f]
    spread = [30, 48, 64, 72][f]
    for _ in range(n):
        px = cx + rng.randint(-spread, spread)
        py = cy + rng.randint(-spread, spread)
        r = rng.randint(22, 44)
        col = rng.choice([pal["primary"], pal["glow"], pal["dark"]])
        img = add(img, soft_circle(S, col, r, r * 0.7, 120, (px, py)))
    img = add(img, soft_circle(S, pal["core"], 26, 12, 170, (cx, cy)))
    img = add(img, particles(pal, 5 + f * 2, cx, cy, spread, rng, size=(3, 8)))
    return img


def frame_slash(f, pal, rng):
    """Dark-energy crescent slash that sweeps and bursts."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S // 2, S // 2
    if f < 3:
        scale = [0.55, 0.85, 1.05][f]
        bb = [cx - 90 * scale, cy - 90 * scale, cx + 90 * scale, cy + 90 * scale]
        start, end = -55, 55
        glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(glow).arc(bb, start, end, fill=pal["glow"] + (220,), width=int(26 * scale))
        img = add(img, glow.filter(ImageFilter.GaussianBlur(8)))
        ImageDraw.Draw(img).arc(bb, start, end, fill=pal["primary"] + (240,), width=int(12 * scale))
        ImageDraw.Draw(img).arc(bb, start, end, fill=pal["core"] + (250,), width=max(2, int(5 * scale)))
        img = add(img, particles(pal, 4 + f * 2, cx + 30, cy, 28, rng))
    else:
        img = add(img, soft_circle(S, pal["glow"], 84, 28, 150, (cx, cy)))
        for _ in range(12):
            ang = rng.uniform(-0.9, 0.9)
            dist = rng.uniform(30, 100)
            ex, ey = cx + math.cos(ang) * dist, cy + math.sin(ang) * dist
            ImageDraw.Draw(img).line([(cx, cy), (ex, ey)], fill=pal["primary"] + (210,), width=rng.randint(3, 6))
        img = add(img, soft_circle(S, pal["core"], 28, 10, 230, (cx, cy)))
    return img


def frame_rift(f, pal, rng):
    """Vertical jagged void tear that widens, then collapses to a burst."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rng.seed(17 + f)
    cx, cy = S // 2, S // 2
    if f < 3:
        width = [10, 26, 44][f]
        left, right = [], []
        steps = 14
        for i in range(steps + 1):
            y = int(S * i / steps)
            w = width * (1 - abs(i / steps - 0.5) * 1.4)
            w = max(2, w + rng.randint(-6, 6))
            left.append((cx - w, y))
            right.append((cx + w, y))
        poly = left + right[::-1]
        glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(glow).polygon(poly, fill=pal["glow"] + (200,))
        img = add(img, glow.filter(ImageFilter.GaussianBlur(12)))
        ImageDraw.Draw(img).polygon(poly, fill=pal["core"] + (235,))
        ImageDraw.Draw(img).polygon(poly, outline=pal["primary"] + (255,))
        img = add(img, particles(pal, 6 + f * 3, cx, cy, 40, rng))
    else:
        img = add(img, soft_circle(S, pal["glow"], 96, 32, 160, (cx, cy)))
        img = add(img, soft_circle(S, pal["primary"], 50, 16, 210, (cx, cy)))
        img = add(img, soft_circle(S, pal["core"], 24, 8, 240, (cx, cy)))
        img = add(img, particles(pal, 20, cx, cy, 100, rng, behind=False))
    return img


ARCHETYPES = {
    "projectile": frame_projectile,
    "shard": frame_shard,
    "wall": frame_wall,
    "bolt": frame_bolt,
    "beam": frame_beam,
    "ring": frame_ring,
    "cluster": frame_cluster,
    "cloud": frame_cloud,
    "slash": frame_slash,
    "rift": frame_rift,
}


def build_strip(move, archetype, element):
    pal = PAL[element]
    rng = random.Random(hash(move) & 0xffffffff)
    strip = Image.new("RGBA", (S * FRAMES, S), (0, 0, 0, 0))
    fn = ARCHETYPES[archetype]
    for f in range(FRAMES):
        frame = fn(f, pal, rng)
        strip.paste(frame, (f * S, 0), frame)
    return strip


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for move, (archetype, element) in MOVES.items():
        strip = build_strip(move, archetype, element)
        out = os.path.join(OUT_DIR, f"vfx_{move}.png")
        strip.save(out, format="PNG", optimize=True, compress_level=9)
        kb = os.path.getsize(out) // 1024
        print(f"  vfx_{move}.png  [{archetype}/{element}]  {kb} KB")
    print(f"Done -> {OUT_DIR}")


if __name__ == "__main__":
    main()
