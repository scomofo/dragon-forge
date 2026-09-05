"""Victory sting (<= 6s) — the motif's question, answered in MAJOR.

The battle is won: the question phrase runs at double speed, then resolves
upward to a bright C-major stab (the minor key's shadow lifted). Must stay
<= 6 seconds per the commission list. Renders via tools/music/render.py.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _motif import QUESTION, W, H, Q, E, transpose_major, octave  # noqa: E402

# Question as a major-key eighth-note run, an octave up; C-major arpeggio stab.
run = octave(transpose_major([(n, E) for n, _ in QUESTION]), 1)  # 4 beats
stab = [('C5', E), ('E5', E), ('G5', E), ('C6', H + Q)]          # 4.5 beats
tail = [('R', W)]                                                # pad to 3 bars

lead = run + stab + tail
harmony = [('R', Q * 2 + E * 3), ('C4', H + Q), ('R', W)]
bass = [('C3', Q), ('F3', Q), ('G3', Q), ('Ab3', E), ('G3', E), ('C3', H + Q), ('R', W)]

arp = []
seq = ['C4', 'E4', 'G4', 'C5']
for i in range(int((sum(b for _, b in lead)) * 2)):
    arp.append((seq[i % 4], E))

# One hit, on the stab (beat 4 = sixteenth step 16 of 48).
STEPS = 48
kick = [1 if i == 16 else 0 for i in range(STEPS)]
snare = [1 if i == 16 else 0 for i in range(STEPS)]

SCORE = {
    'bpm': 146,
    'voices': [
        {'wave': 'pulse25', 'gain': 0.5, 'echo': 0.3, 'pan': 0.1, 'notes': lead},
        {'wave': 'pulse50', 'gain': 0.3, 'pan': -0.25, 'notes': harmony},
        {'wave': 'triangle', 'gain': 0.45, 'pan': 0.0, 'notes': bass},
        {'wave': 'pulse12', 'gain': 0.14, 'echo': 0.4, 'pan': 0.3, 'notes': arp},
    ],
    'percussion': [
        {'type': 'kick', 'gain': 0.6, 'steps': kick},
        {'type': 'snare', 'gain': 0.4, 'steps': snare},
    ],
}
# 12 beats @ 138bpm = 5.2s including tail — under the 6s cap.
