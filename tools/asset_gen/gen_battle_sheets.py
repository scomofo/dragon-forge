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


def anchor_url(actor_id: str) -> str:
    if actor_id in DRAGON_IDS:
        return f"{DEPLOY}/assets/dragons/{actor_id}_stage3.webp"
    return f"{DEPLOY}/assets/npc/{actor_id}_sprites.webp"


def generate_pose(actor_id: str, pose: str, dest_png: Path) -> None:
    """Call the edit endpoint for one pose keyframe and save the raw JPEG."""
    prompt = (
        f"Repaint this exact same character in a new pose: {POSE_ACTION[pose]}. "
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

    img = img.convert("RGB")
    W, H = img.size
    src = img.load()
    corners = [src[0, 0], src[W - 1, 0], src[0, H - 1], src[W - 1, H - 1]]

    # Chroma-key the requested magenta backdrop. A pixel counts as magenta when
    # red and blue both clearly dominate green — this catches the bright chroma
    # AND the darker muted magenta the model sometimes paints in interior pockets.
    # A dragon body (fire=orange, ice=cyan, stone=brown…) never has r>g AND b>g,
    # so this stays safe. Keyed GLOBALLY since pockets may not touch the border.
    def is_magenta(r: int, g: int, b: int) -> bool:
        return r > 100 and b > 100 and r > g + 50 and b > g + 50

    # Light, desaturated grey checkerboard squares.
    def is_checker(r: int, g: int, b: int) -> bool:
        return abs(r - g) < 16 and abs(g - b) < 16 and r > 165

    # Decide which global key applies by how much of the image matches. The
    # magenta chroma backdrop (and any interior magenta pocket the model paints)
    # is removed globally whenever magenta is meaningfully present — a dragon
    # body never carries it. Checkerboard is the model's other default.
    def image_fraction(pred, step=6) -> float:
        n = 0
        hit = 0
        for y in range(0, H, step):
            for x in range(0, W, step):
                n += 1
                hit += 1 if pred(*src[x, y]) else 0
        return hit / n if n else 0.0

    for key, thresh in ((is_magenta, 0.02), (is_checker, 0.20)):
        if image_fraction(key) > thresh:
            out = Image.new("RGBA", (W, H))
            opx = out.load()
            for y in range(H):
                for x in range(W):
                    r, g, b = src[x, y]
                    opx[x, y] = (r, g, b, 0) if key(r, g, b) else (r, g, b, 255)
            return out

    # Flat backdrop: flood-fill from each corner toward the background colour.
    out = img.convert("RGBA")
    opx = out.load()

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


def build_strip(keyframe_png: Path, pose: str, out_webp: Path) -> None:
    """Hold the keyframe across the pose's frame count at 96px cells."""
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
    strip = Image.new("RGBA", (CELL * frames, CELL), (0, 0, 0, 0))
    for i in range(frames):
        strip.paste(cell_img, (i * CELL, 0), cell_img)

    out_webp.parent.mkdir(parents=True, exist_ok=True)
    strip.save(out_webp, format="WEBP", quality=80, method=4)


def process_actor(actor_id: str, force: bool = False) -> None:
    tmp = REPO / "assets" / "battle-sets" / "_tmp" / actor_id
    tmp.mkdir(parents=True, exist_ok=True)
    print(f"[{actor_id}]")
    for pose in FRAMES:
        out_webp = OUT_DIR / f"{actor_id}_{pose}.webp"
        if out_webp.exists() and not force:
            print(f"  {pose}: exists, skip")
            continue
        keyframe = tmp / f"{pose}.png"
        if not keyframe.exists() or force:
            print(f"  {pose}: generating keyframe...")
            generate_pose(actor_id, pose, keyframe)
        build_strip(keyframe, pose, out_webp)
        kb = out_webp.stat().st_size // 1024
        print(f"  {pose}: {out_webp.name} ({FRAMES[pose]}x{CELL}px, {kb} KB)")


def main() -> None:
    if not FAL_KEY:
        sys.exit("ERROR: FAL_KEY env var required (https://fal.ai/dashboard/keys)")
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    force = "--force" in sys.argv
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
        process_actor(actor, force)
    print("\nDone.")


if __name__ == "__main__":
    main()
