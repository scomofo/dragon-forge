#!/usr/bin/env python3
"""Atmospheric music generator (P2) — fal.ai text-to-music for the 5 tracks
that don't need the written motif: mapWander, battleB, battleElite,
singularity, boss.

Prompts aim at 16-bit SNES JRPG instrumental loops, each with a distinct
tempo/mood so no two battles share a feel (the "battleB split" fix).

Usage: FAL_KEY=<key> python3 tools/asset_gen/gen_music.py [track ...]
Omit names to generate all 5. Existing files are skipped (delete to regen).
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / 'public' / 'assets' / 'music'
LYRIA_URL = 'https://fal.run/fal-ai/lyria2'
FAL_KEY = os.environ.get('FAL_KEY', '')

STYLE = ('16-bit SNES JRPG instrumental, chiptune-tinged, seamless loop, '
         'no vocals, no lyrics, no speech')

TRACKS = {
    # mapWander — calm exploration for the world map
    'map_wander': 'calm exploratory overworld map theme, gentle plucked melody, soft string pad, curious wandering mood, slow 70 BPM, ' + STYLE,
    # battleB — tense: opening crawl + mid-fight escalation (NOT the same as standard or elite)
    'battle_tense': 'tense driving battle theme, urgent staccato strings and synth brass, rising chromatic bass, 140 BPM, ' + STYLE,
    # battleElite — critical / elite fights: faster, aggressive
    'battle_elite': 'intense dramatic elite boss battle theme, fast pounding drums, aggressive synth brass stabs, driving bass, 150 BPM, minor key, ' + STYLE,
    # singularity — cosmic dread for the Singularity phases
    'singularity': 'ominous cosmic dread final dungeon theme, dissonant dark drones, slow pulsing sub bass, eerie high glassy pads, 60 BPM, ' + STYLE,
    # boss — gatekeepers and remnants
    'boss': 'heavy dramatic boss battle theme, pounding war drums, ominous low brass, relentless driving rhythm, 135 BPM, minor key, ' + STYLE,
}


def fal_post(url: str, payload: dict) -> dict:
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={'Authorization': f'Key {FAL_KEY}', 'Content-Type': 'application/json'},
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        return json.load(resp)


def gen_track(name: str, prompt: str) -> None:
    out = OUT_DIR / f'music_{name}.mp3'
    if out.exists():
        print(f'[skip] {out.name} exists')
        return
    print(f'[gen] {out.name}')
    data = fal_post(LYRIA_URL, {
        'prompt': prompt,
        'negative_prompt': 'vocals, singing, lyrics, speech, noise, distortion',
    })
    audio_url = data['audio']['url']
    tmp = OUT_DIR / f'_tmp_{name}.wav'
    with urllib.request.urlopen(audio_url, timeout=300) as r, open(tmp, 'wb') as f:
        f.write(r.read())
    subprocess.run(
        ['ffmpeg', '-y', '-i', str(tmp), '-codec:a', 'libmp3lame', '-b:a', '128k', str(out)],
        check=True, capture_output=True,
    )
    tmp.unlink()
    print(f'  -> {out.name}  {out.stat().st_size // 1024} KB')


def main() -> None:
    if not FAL_KEY:
        sys.exit('ERROR: FAL_KEY env var required')
    names = sys.argv[1:] or list(TRACKS)
    for name in names:
        if name not in TRACKS:
            print(f'[skip] unknown track {name}')
            continue
        gen_track(name, TRACKS[name])
    print('\nDone.')


if __name__ == '__main__':
    main()
