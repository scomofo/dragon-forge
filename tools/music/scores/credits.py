"""Credits — the full title (Heartforge) motif arrangement.

music-identity.md: "credits — full title arrangement." The motif in its
original C minor at full tempo with a complete chiptune arrangement: pulse
lead, triangle bass, arp harmony, and drums — the title theme played out in
full after the run is done. 12 bars @ 112 BPM ≈ 26s loop.
Renders via tools/music/render.py.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _motif import QUESTION, ANSWER, W, H, Q, E, octave  # noqa: E402

BARS = 12

# 2-bar intro (arp alone), question+answer, question+answer with the lead
# up an octave and fuller drums, then the answer again to close on C.
intro = [('R', W * 2)]
body = QUESTION + ANSWER + octave(QUESTION, 1) + octave(ANSWER, 1)
close = octave(ANSWER, 1)[:5] + [('C5', H), ('R', Q)]  # resolve, hold, rest
lead = intro + body + close
assert sum(b for _, b in lead) == W * BARS, sum(b for _, b in lead)

bass_seq = ['C2', 'G2', 'Ab2', 'G2',   # question  (Ab: the villain turns up)
            'F2', 'C3', 'G2', 'C2',    # answer
            'C2', 'G2', 'Ab2', 'G2']   # restatement
bass = [(n, W) for n in bass_seq] + [('C2', W * (BARS - len(bass_seq)))]
assert sum(b for _, b in bass) == W * BARS

# Sixteenth arp: C Eb G Ab — the question compressed into a color.
arp = []
seq = ['C4', 'Eb4', 'G4', 'Ab4']
for step in range(BARS * 8):
    arp.append((seq[step % 4], E))
assert sum(b for _, b in arp) == W * BARS

# Drums enter after the intro: kick 1+3, snare 2+4, hat eighths.
kick_steps, snare_steps, hat_steps = [], [], []
for bar in range(BARS):
    for step in range(16):
        active = bar >= 2
        kick_steps.append(1 if active and step in (0, 8) else 0)
        snare_steps.append(1 if active and step in (4, 12) else 0)
        hat_steps.append(1 if active and step % 2 == 0 else 0)

SCORE = {
    'bpm': 112,
    'voices': [
        {'wave': 'pulse25',  'gain': 0.5, 'echo': 0.3, 'vibrato': (5.5, 0.2), 'pan': 0.1, 'notes': lead},
        {'wave': 'triangle', 'gain': 0.45, 'pan': 0.0, 'notes': bass},
        {'wave': 'pulse12',  'gain': 0.13, 'echo': 0.4, 'pan': -0.25, 'notes': arp},
    ],
    'percussion': [
        {'type': 'kick',  'gain': 0.6,  'steps': kick_steps},
        {'type': 'snare', 'gain': 0.42, 'steps': snare_steps},
        {'type': 'hat',   'gain': 0.16, 'steps': hat_steps},
    ],
}
