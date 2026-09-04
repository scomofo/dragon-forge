#!/usr/bin/env python3
"""Boss attack-cell + Singularity idle-distinctness generator (P1).

Every boss in src/singularityBosses.js points idleSprite and attackSprite at the
same file — there are no real attack cells. For each of the 12 unique boss
sprites this generates a distinct attack cell via the seedream v4.5 EDIT
endpoint, anchored on the deployed idle so identity holds, and writes
public/assets/npc/<name>_attack.webp at the idle's exact dimensions.

It also regenerates the two Singularity idles that shipped as near-identical
purple vortices (surge / void) so each phase is structurally distinct:
  - surge: electric storm — branching violet-white lightning filaments
  - void:  black hole — hollow event-horizon core with a bright accretion ring

Format law: gatekeeper / singularity / remnant cells are RGBA -> magenta chroma
backdrop, keyed to alpha. mirror_admin cells are RGB on black -> keep black.

Usage: FAL_KEY=<key> python3 tools/asset_gen/gen_boss_attacks.py [name ...]
Omit names to run all 12 attack cells + the 2 singularity idle regens.
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
OUT_DIR = REPO / "public" / "assets" / "npc"
TMP_DIR = REPO / "assets" / "boss_cells" / "_tmp"

DEPLOY = "https://scomofo.github.io/dragon-forge"
EDIT_URL = "https://fal.run/fal-ai/bytedance/seedream/v4.5/edit"
T2I_URL = "https://fal.run/fal-ai/bytedance/seedream/v4.5/text-to-image"
FAL_KEY = os.environ.get("FAL_KEY", "")

# name -> (attack action, alpha?)  alpha=False keeps an opaque black backdrop.
ATTACKS = {
    "data_corruption_boss": ("rearing up to strike, corrupted molten fire erupting from its cracked core, claws extended, burning embers dripping from its maw, the background pure clean darkness with nothing else", True),
    "memory_leak_boss": ("swelling with absorbed ice energy and bursting it outward, glacier spikes erupting from its body, maw open exhaling freezing mist", True),
    "stack_overflow_boss": ("overloaded with crackling electricity, lightning arcs erupting from its whole body, lunging strike pose", True),
    "singularity_ignition_boss": ("erupting violently, the molten fire vortex flaring outward, embers and lava scattering in all directions", True),
    "singularity_surge_boss": ("discharging massive branching lightning bolts outward from its core, electric arcs overloading, violet-white storm energy", True),
    "singularity_void_boss": ("erupting void energy, the event horizon flaring violet-white, space visibly tearing around the black core", True),
    "mirror_admin_protocol": ("raising its greatsword high to strike, void-fire flaring along the blade, cape billowing, menacing lunge", False),
    "mirror_admin_warden": ("its core flaring bright, crystal spines extending outward, lunging forward to strike with both claws", False),
    "mirror_admin_reset": ("unleashing the Great Reset, radiant white-gold light beams erupting from the seal, wings of light spread wide", False),
    "remnant_data_corruption": ("erupting in denser corrupted flame, its magma core splitting open, fire tendrils lashing outward", True),
    "remnant_memory_leak": ("releasing everything it absorbed in one massive ice burst, glacier spikes and freezing mist erupting outward", True),
    "remnant_stack_overflow": ("overloading completely, recursion loops visible as stacked lightning rings, discharging a massive bolt storm", True),
}

# Singularity idle regens — the shipped surge/void are hue-twin purple vortices.
IDLE_REGENS = {
    "singularity_surge_boss": "a vast storm-energy vortex entity made of crackling branching violet-white lightning filaments and thunderhead plasma, electric arcs forking outward, dark tech-fantasy digital art, transparent background, no text",
    "singularity_void_boss": "a black-hole entity: a hollow pitch-black event-horizon core surrounded by a thin brilliant violet-white accretion ring, space bending and tearing around it, dark tech-fantasy digital art, transparent background, no text",
}

STYLE = "Keep the exact same character design, proportions, colours and painterly dark tech-fantasy art style as the reference image."
# Bosses are bright glowing cores on dark fields: ask for a plain dark backdrop
# and derive alpha from luminance (never chroma-key magenta, since these cells
# legitimately paint magenta/violet fire). Strictly ban glyphs — corruption
# bosses love rendering fake binary.
BG = " Isolated on a plain dark near-black background, absolutely no scenery, no text, no letters, no numbers, no binary, no glyphs, no runes, no symbols anywhere in the image."
NEG = "text, letters, numbers, binary, glyphs, runes, symbols, watermark, signature, border, frame, code, matrix rain"


def fal_post(url: str, payload: dict) -> str:
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"},
        method="POST",
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=240) as resp:
                data = json.load(resp)
            return data["images"][0]["url"]
        except Exception as e:  # noqa: BLE001 - transient 429/5xx: back off and retry
            if attempt == 3:
                raise
            wait = 2 ** attempt
            print(f"    retry {attempt + 1}/4 after: {e} (wait {wait}s)")
            time.sleep(wait)
    raise RuntimeError("unreachable")


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=120) as r, open(dest, "wb") as f:
        f.write(r.read())


def luminance_to_alpha(img: Image.Image, floor: int = 26) -> Image.Image:
    """Alpha from luminance for a glowing subject on a uniform backdrop.

    The boss cells are luminous energy creatures on a flat field. We detect the
    backdrop brightness from the corners: on a dark field, alpha = luminance
    (dark -> transparent); on a bright field, alpha = inverse luminance
    (bright -> transparent). The glowing subject reads against either.
    """
    rgb = img.convert("RGB")
    W, H = rgb.size
    src = rgb.load()

    def lum(x: int, y: int) -> int:
        r, g, b = src[x, y]
        return (r * 299 + g * 587 + b * 114) // 1000

    corner_lum = sum(lum(x, y) for x, y in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]) / 4
    bright_field = corner_lum > 128

    out = Image.new("RGBA", (W, H))
    opx = out.load()
    for y in range(H):
        for x in range(W):
            r, g, b = src[x, y]
            l = (r * 299 + g * 587 + b * 114) // 1000
            if bright_field:
                a = 0 if l >= 235 else min(255, int((235 - l) * 255 / (235 - floor)))
            else:
                a = 0 if l <= floor else min(255, int((l - floor) * 255 / (235 - floor)))
            opx[x, y] = (r, g, b, a)
    return out


def gen_attack(name: str, action: str, alpha: bool, force: bool) -> None:
    idle = OUT_DIR / f"{name}.webp"
    out = OUT_DIR / f"{name}_attack.webp"
    if out.exists() and not force:
        print(f"[skip] {name}_attack.webp exists")
        return
    idle_img = Image.open(idle)
    tmp = TMP_DIR / f"{name}_attack.png"
    if not tmp.exists() or force:
        print(f"[gen] {name}_attack")
        url = fal_post(EDIT_URL, {
            "prompt": f"Repaint this exact same boss character in a dramatic mid-attack pose: {action}. {STYLE}{BG}",
            "image_urls": [f"{DEPLOY}/assets/npc/{name}.webp"],
            "image_size": "square_hd",
            "num_images": 1,
            "enable_safety_checker": False,
            "negative_prompt": NEG,
        })
        download(url, tmp)
    img = Image.open(tmp)
    out_img = luminance_to_alpha(img) if alpha else img.convert("RGB")
    if out_img.size != idle_img.size:
        out_img = out_img.resize(idle_img.size, Image.LANCZOS)
    out_img.save(out, format="WEBP", quality=82, method=4)
    print(f"  -> {out.name} {out_img.size} {out.stat().st_size // 1024} KB")


def gen_idle_regen(name: str, prompt: str, force: bool) -> None:
    out = OUT_DIR / f"{name}.webp"
    if not force:
        print(f"[skip] {name} idle regen (pass --force to overwrite)")
        return
    idle_img = Image.open(out)  # capture dims before overwrite
    tmp = TMP_DIR / f"{name}_idle_regen.png"
    if not tmp.exists():
        print(f"[gen] {name} idle regen")
        url = fal_post(T2I_URL, {
            "prompt": f"{prompt}, dark tech-fantasy boss portrait, full body centered{BG}",
            "image_size": "square_hd",
            "num_images": 1,
            "enable_safety_checker": False,
            "negative_prompt": NEG,
        })
        download(url, tmp)
    out_img = luminance_to_alpha(Image.open(tmp))
    if out_img.size != idle_img.size:
        out_img = out_img.resize(idle_img.size, Image.LANCZOS)
    out_img.save(out, format="WEBP", quality=82, method=4)
    print(f"  -> {out.name} {out_img.size} {out.stat().st_size // 1024} KB (regen)")


def main() -> None:
    if not FAL_KEY:
        sys.exit("ERROR: FAL_KEY env var required")
    force = "--force" in sys.argv
    names = [a for a in sys.argv[1:] if not a.startswith("--")]
    targets = names or list(ATTACKS)
    for name in targets:
        if name not in ATTACKS:
            print(f"[skip] unknown boss '{name}'")
            continue
        action, alpha = ATTACKS[name]
        gen_attack(name, action, alpha, force)
    if not names:
        for name, prompt in IDLE_REGENS.items():
            gen_idle_regen(name, prompt, force)
    print("\nDone.")


if __name__ == "__main__":
    main()
