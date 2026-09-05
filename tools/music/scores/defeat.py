"""Defeat sting — the villain wins: the question sinks to Ab and stays there.

The question phrase in the low register, collapsing downward; the flattened
6th (Ab) takes the final word over a low C drone. A sting, not a dirge:
~4.5s. Renders via tools/music/render.py.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _motif import QUESTION, W, H, E, octave  # noqa: E402

# Question an octave down at eighth-note pace, then the collapse: Ab3 held.
phrase = [(n, E) for n, _ in octave(QUESTION, -1)]  # 4 beats
collapse = [('Ab3', W)]

lead = phrase + collapse
bass = [('C2', W), ('Ab1', W)]  # the flattened 6th gets the last word
drone = [('C2', W * 2)]

SCORE = {
    'bpm': 100,
    'voices': [
        {'wave': 'sine',     'gain': 0.5,  'echo': 0.4, 'vibrato': (4.8, 0.22), 'pan': 0.1, 'notes': lead},
        {'wave': 'triangle', 'gain': 0.42, 'pan': 0.0, 'legato': True, 'notes': bass},
        {'wave': 'sine',     'gain': 0.14, 'pan': -0.3, 'legato': True, 'notes': drone},
    ],
    # No percussion. Defeat is silent but for the fall.
}
# 8 beats @ 100bpm = 4.8s + echo tail — a sting, not a dirge.
