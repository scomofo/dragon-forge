"""Hub (hatchery rewrite) — the title motif in MAJOR, warm and unhurried.

music-identity.md: "hub — keep hatchery until rewritten as motif-major."
This is that rewrite: the question and answer with E and A natural, on a
soft triangle lead over a slow C-major pulse bed. The home theme should feel
like the title theme with the sun out. 8 bars @ 84 BPM ≈ 23s loop.
Renders via tools/music/render.py.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _motif import QUESTION, ANSWER, W, H, Q, E, transpose_major  # noqa: E402

BARS = 8

Q_MAJ = transpose_major(QUESTION)   # C E G A | G F E D
A_MAJ = transpose_major(ANSWER)     # E F G C | B C —

# Two plain statements; warmth comes from the bed, not range.
lead = Q_MAJ + A_MAJ + Q_MAJ + A_MAJ

bass_seq = ['C3', 'G2', 'A2', 'G2', 'F2', 'G2', 'C3', 'G2']
bass = [(n, W) for n in bass_seq]
assert len(bass) == BARS

# Gentle root-position pad: C and G alternating whole notes.
pad_c = [('C3', W), ('R', W)] * (BARS // 2)
pad_g = [('G3', W), ('R', W)] * (BARS // 2)
pad_e = [('E3', W), ('R', W)] * (BARS // 2)

# Music-box arp on the off-eighths: C E G E.
arp = []
seq = ['C5', 'E5', 'G5', 'E5']
for bar in range(BARS):
    for eighth in range(8):
        arp.append((seq[eighth % 4] if eighth % 2 == 0 else 'R', E))
assert sum(b for _, b in arp) == W * BARS

SCORE = {
    'bpm': 84,
    'voices': [
        {'wave': 'triangle', 'gain': 0.5, 'echo': 0.3, 'vibrato': (5.0, 0.15), 'pan': 0.1, 'notes': lead},
        {'wave': 'triangle', 'gain': 0.4, 'pan': 0.0, 'legato': True, 'notes': bass},
        {'wave': 'sine',     'gain': 0.16, 'pan': -0.3, 'legato': True, 'notes': pad_c},
        {'wave': 'sine',     'gain': 0.12, 'pan': 0.25, 'legato': True, 'notes': pad_e},
        {'wave': 'sine',     'gain': 0.12, 'pan': -0.1, 'legato': True, 'notes': pad_g},
        {'wave': 'pulse12',  'gain': 0.10, 'echo': 0.45, 'pan': 0.3, 'notes': arp},
    ],
    # Home is safe: no drums.
}
