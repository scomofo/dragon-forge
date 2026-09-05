#!/usr/bin/env python3
"""Battle-set sheet generator (P1) — keyframe approach.

For one actor, generate 4 pose keyframes (idle / attack / hurt / faint) via the
seedream v4.5 EDIT endpoint, anchored on the actor's existing stage-3 portrait /
NPC sprite so identity holds. The model returns fake-transparency checkerboard
JPEGs; we composite that onto true alpha, then assemble one horizontal strip per
pose (<frames> cells of 96px, keyframe held across the strip) and write webp.

Output: public/assets/battle-sets/<actorId>_<pose>.webp
        (dragon keyframes also land in assets/battle-sets/ for the local master)

Usage:
  FAL_KEY=<key> python3 tools/asset_gen/gen_battle_sheets.py <actorId> [--force]
  FAL_KEY=<key> python3 tools/asset_gen/gen_battle_sheets.py --all-dragons

Reads anchors from the deployed site so fal can fetch them over HTTPS.
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.request
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("ERROR: Pillow not installed. Run: uv run --with pillow python ...")

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "public" / "assets" / "battle-sets"
LOCAL_MASTER = REPO / "assets" / "battle-sets"

DEPLOY = "https://scomofo.github.io/dragon-forge"
EDIT_URL = "https://fal.run/fal-ai/bytedance/seedream/v4.5/edit"
FAL_KEY = os.environ.get("FAL_KEY", "")

# Art bible cell + frame contract (src/artBible.js). Mid cell for all P1 sets.
CELL = 96
FRAMES = {"idle": 4, "attack": 6, "hurt": 2, "faint": 3}

# 9 journal dragons (stage-3 anchor) + 9 NPCs (sprite anchor).
DRAGON_IDS = ["fire", "ice", "storm", "stone", "venom", "shadow", "void", "light", "synthesis"]
NPC_IDS = [
    "firewall_sentinel", "bit_wraith", "glitch_hydra", "recursive_golem",
    "buffer_overflow", "crypto_crab", "logic_bomb", "phishing_siren", "protocol_vulture",
]

# Per-pose action. Kept element-agnostic; the anchor image carries the design.
POSE_ACTION = {
    "idle": "standing calm and alert in a neutral battle-ready idle stance, breathing, facing left toward the opponent",
    "attack": "lunging forward mid-attack, aggressive strike pose, mouth open, energy of its element flaring, dynamic motion, facing left",
    "hurt": "recoiling backward from a hit, flinching, pained expression, body twisted defensively, facing left",
    "faint": "collapsed on the ground defeated, eyes closed, wings/limbs limp, lying on its side, knocked out",
}

NEG = (
    "blurry, watermark, text, letters, numbers, border, frame number, photorealistic, "
    "3D render, extra limbs, multiple heads, different character, changed colors, background scene"
)

STYLE = (
    "16-bit pixel art, 2D side-view, clean pixel outlines, dark tech-fantasy aesthetic, "
    "full body visible, centered, on a SOLID flat bright magenta #ff00ff background, "
    "no gradient, no scene, no text no borders no frame numbers"
)

# P1 polish: the first pass left these dark-on-dark (dark violet body on the
# dark battle backdrop reads muddy in-game). Same design, but force readable
# separation — brighter rim light and lighter accent highlights.
ACTOR_PROMPT_OVERRIDE = {
    "void": "Add strong cool violet-white rim lighting along the silhouette and noticeably lighter lavender accent highlights on the wings, chest, and crest, so the dark body reads clearly against dark backgrounds. ",
    "protocol_vulture": "Add strong bright cyan-white rim lighting along the silhouette and noticeably lighter silver-lavender highlights on the wings, neck, and head, so the dark body reads clearly against dark backgrounds. ",
}


def anchor_url(actor_id: str) -> str:
    if actor_id in DRAGON_IDS:
        return f"{DEPLOY}/assets/dragons/{actor_id}_stage3.webp"
    return f"{DEPLOY}/assets/npc/{actor_id}_sprites.webp"


def generate_pose(actor_id: str, pose: str, dest_png: Path) -> None:
    """Call the edit endpoint for one pose keyframe and save the raw JPEG."""
    prompt = (
        f"Repaint this exact same character in a new pose: {POSE_ACTION[pose]}. "
        f"{ACTOR_PROMPT_OVERRIDE.get(actor_id, '')}"
        f"Keep the identical character design, silhouette, scale/skin pattern, and color "
        f"palette exactly — do not change the design. {STYLE}."
    )
    payload = json.dumps({
        "prompt": prompt,
        "image_urls": [anchor_url(actor_id)],
        "image_size": "square_hd",
        "num_images": 1,
        "enable_safety_checker": False,
    }).encode()

    req = urllib.request.Request(
        EDIT_URL,
        data=payload,
        headers={
            "Authorization": f"Key {FAL_KEY}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                data = json.load(resp)
            url = data["images"][0]["url"]
            dest_png.parent.mkdir(parents=True, exist_ok=True)
            with urllib.request.urlopen(url, timeout=120) as r, open(dest_png, "wb") as f:
                f.write(r.read())
            return
        except Exception as e:  # noqa: BLE001 - transient 429/5xx: back off and retry
            if attempt == 3:
                raise
            wait = 2 ** attempt
            print(f"    retry {attempt + 1}/4 for {pose} after error: {e} (wait {wait}s)")
            time.sleep(wait)


def checkerboard_to_alpha(img: Image.Image) -> Image.Image:
    """Composite the model's background onto real alpha.

    We request a solid magenta chroma backdrop (never on a dragon body), which
    keys cleanly. Fallbacks handle the model ignoring that: a light-grey
    checkerboard key, then a border-connected flat-backdrop flood fill.
    """
    from collections import deque

    import numpy as np

    img = img.convert("RGB")
    W, H = img.size
    arr = np.asarray(img, dtype=np.int16)
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]

    # Global keys (vectorized): the magenta chroma backdrop — including darker
    # muted magenta pockets the model sometimes paints inside — keys whenever
    # red AND blue clearly dominate green. A dragon body (fire=orange,
    # ice=cyan, stone=brown…) never has r>g AND b>g, so this stays safe.
    magenta = (r > 100) & (b > 100) & (r > g + 50) & (b > g + 50)
    # Light, desaturated grey checkerboard squares.
    checker = (np.abs(r - g) < 16) & (np.abs(g - b) < 16) & (r > 165)

    for mask, thresh in ((magenta, 0.02), (checker, 0.20)):
        if float(mask[::6, ::6].mean()) > thresh:
            alpha = np.where(mask, 0, 255).astype(np.uint8)
            return Image.fromarray(np.dstack([arr.astype(np.uint8), alpha]), "RGBA")

    # Flat backdrop: flood-fill from each corner toward the background colour.
    out = img.convert("RGBA")
    opx = out.load()
    src = img.load()

    # Tolerance scaled to the backdrop brightness: a near-black backdrop next to
    # a near-black dragon body must use a TIGHT tolerance so we only strip the
    # uniform border and never diffuse into the subject.
    for cx, cy in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        bg = src[cx, cy]
        lum = (bg[0] + bg[1] + bg[2]) / 3
        tol = 10 if lum < 60 else 40  # dark backdrop: strict; bright: lenient

        def close_to(c):
            return all(abs(c[i] - bg[i]) <= tol for i in range(3))

        if opx[cx, cy][3] == 0:
            continue
        seen = bytearray(W * H)
        dq = deque([(cx, cy)])
        while dq:
            x, y = dq.popleft()
            if x < 0 or y < 0 or x >= W or y >= H:
                continue
            idx = y * W + x
            if seen[idx]:
                continue
            seen[idx] = 1
            r, g, b, a = opx[x, y]
            if a == 0 or not close_to((r, g, b)):
                continue
            opx[x, y] = (r, g, b, 0)
            dq.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return out


def _bbox(img: Image.Image) -> tuple[int, int, int, int]:
    bbox = img.getchannel("A").getbbox()
    return bbox if bbox else (0, 0, img.width, img.height)


def transform_cell(cell_img: Image.Image, dx: float = 0.0, dy: float = 0.0,
                   sy: float = 1.0, shear: float = 0.0) -> Image.Image:
    """Squash-and-stretch in-between: translate/scale/shear the cell content,
    anchored at the sprite's bottom-center so the feet stay planted. Shear is
    used for leans (not rotation) — it keeps pixel rows crisp at 96px.

    These programmatic in-betweens are the SNES sprite-translation technique:
    the authored keyframe is carried; motion comes from per-frame transforms.
    """
    x0, y0, x1, y1 = _bbox(cell_img)
    content = cell_img.crop((x0, y0, x1, y1))
    w, h = content.size
    new_h = max(1, round(h * sy))
    out = content.resize((w, new_h), Image.LANCZOS) if sy != 1.0 else content
    if shear:
        nw = max(1, round(w + abs(shear) * new_h))
        out = out.transform((nw, new_h), Image.AFFINE, (1, -shear, 0, 0, 1, 0), resample=Image.BICUBIC)
    cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    # bottom-center anchor, then per-frame offset
    px = (CELL - out.width) // 2 + round(dx)
    py = (CELL - out.height) - (CELL - y1) + round(dy)  # preserve original bottom margin
    cell.paste(out, (px, py), out)
    return cell


# Per-pose in-between programs. The keyframe (index 0 posture) is transformed
# per frame: idle breathes, attack lunges (wind-up -> strike -> recover),
# hurt recoils, faint settles. Values are px/scale/shear per frame index.
INBETWEENS = {
    "idle":   [{}, {"dy": 1, "sy": 1.025}, {}, {"dy": -1, "sy": 0.98}],
    "attack": [{"dx": 5}, {"dx": 2}, {}, {"dx": -6, "shear": -0.06}, {"dx": -3, "shear": -0.03}, {}],
    "hurt":   [{}, {"dx": 5, "shear": 0.07}],
    "faint":  [{}, {"dy": 1, "sy": 0.97}, {"dy": 2, "sy": 0.94}],
}


def build_strip(keyframe_png: Path, pose: str, out_webp: Path) -> None:
    """Build the pose strip at 96px cells: keyframe + programmatic in-betweens."""
    img = Image.open(keyframe_png)
    rgba = checkerboard_to_alpha(img)
    # Downscale the keyframe to one cell, preserving aspect (letterbox into cell).
    cell_img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    fitted = rgba.copy()
    fitted.thumbnail((CELL, CELL), Image.LANCZOS)
    ox = (CELL - fitted.width) // 2
    oy = (CELL - fitted.height) // 2
    cell_img.paste(fitted, (ox, oy), fitted)

    frames = FRAMES[pose]
    program = INBETWEENS.get(pose, [])
    strip = Image.new("RGBA", (CELL * frames, CELL), (0, 0, 0, 0))
    for i in range(frames):
        t = program[i % len(program)] if program else {}
        frame_img = transform_cell(cell_img, **t) if t else cell_img
        strip.paste(frame_img, (i * CELL, 0), frame_img)

    out_webp.parent.mkdir(parents=True, exist_ok=True)
    strip.save(out_webp, format="WEBP", quality=80, method=4)


def process_actor(actor_id: str, force: bool = False, rebuild: bool = False) -> None:
    tmp = REPO / "assets" / "battle-sets" / "_tmp" / actor_id
    tmp.mkdir(parents=True, exist_ok=True)
    print(f"[{actor_id}]")
    for pose in FRAMES:
        out_webp = OUT_DIR / f"{actor_id}_{pose}.webp"
        keyframe = tmp / f"{pose}.png"
        if rebuild:
            # Rebuild strips from cached keyframes only — no API spend.
            if not keyframe.exists():
                print(f"  {pose}: no cached keyframe, skip")
                continue
            build_strip(keyframe, pose, out_webp)
            print(f"  {pose}: rebuilt {out_webp.name}")
            continue
        if out_webp.exists() and not force:
            print(f"  {pose}: exists, skip")
            continue
        if not keyframe.exists() or force:
            print(f"  {pose}: generating keyframe...")
            generate_pose(actor_id, pose, keyframe)
        build_strip(keyframe, pose, out_webp)
        kb = out_webp.stat().st_size // 1024
        print(f"  {pose}: {out_webp.name} ({FRAMES[pose]}x{CELL}px, {kb} KB)")


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    force = "--force" in sys.argv
    rebuild = "--rebuild" in sys.argv  # strips from cached keyframes, no API
    if not rebuild and not FAL_KEY:
        sys.exit("ERROR: FAL_KEY env var required (https://fal.ai/dashboard/keys)")
    if "--all-dragons" in sys.argv:
        targets = DRAGON_IDS
    elif "--all-npcs" in sys.argv:
        targets = NPC_IDS
    elif "--all" in sys.argv:
        targets = DRAGON_IDS + NPC_IDS
    else:
        targets = args
    if not targets:
        sys.exit("ERROR: give an actor id, or --all-dragons / --all-npcs / --all")
    for actor in targets:
        if actor not in DRAGON_IDS + NPC_IDS:
            print(f"  [skip] unknown actor '{actor}'")
            continue
        process_actor(actor, force, rebuild=rebuild)
    print("\nDone.")


if __name__ == "__main__":
    main()
