"""Mirror Admin — the title (Heartforge) motif at half-time.

design/gdd/music-identity.md:
  Title motif (C minor):  C4 Eb4 G4 Ab4 | G4 F4 Eb4 D4  (question)
                          Eb4 F4 G4 C5  | B3 C4 —        (answer)
  "Mirror Admin is this motif at half-time, flattened 6th in the bass,
   no percussion on the downbeat."

Half-time: every quarter of the title motif becomes a half note here.
Flattened 6th: Ab sits in the bass on the strong bars — the villain note
carrying the harmony, not just colouring the melody.
No percussion on the downbeat: kick lands only on beat 3, hats only on the
"and" of 4 — the bar never gets a hit on 1. A heartbeat off the beat.

20 bars @ 63 BPM ≈ 76s loop. Renders via tools/music/render.py.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _motif import QUESTION, ANSWER, W, H, E, octave, stretch  # noqa: E402

BARS = 20

# --- Lead: the motif at half-time (sine "flute", tragic) -------------------
# 4 bars rest (intro), 8-bar statement, 4-bar restatement an octave up on the
# question, then the unresolved question fragment hanging over the outro.
QUESTION_HT = stretch(QUESTION, 2)
ANSWER_HT = stretch(ANSWER, 2)
QUESTION_HI = stretch(octave(QUESTION, 1), 2)
FRAGMENT = [('C4', H), ('Eb4', H), ('G4', H), ('Ab4', H)]  # question, unanswered

lead = [('R', W * 4)] + QUESTION_HT + ANSWER_HT + QUESTION_HI + FRAGMENT + [('R', W * 2)]
assert sum(b for _, b in lead) == W * BARS, sum(b for _, b in lead)

# --- Bass: Ab (bVI) on the strong bars -------------------------------------
BASS_LINE = [
    'C2', 'C2', 'Ab1', 'Ab1',      # intro — the Ab arrives before the melody
    'C2', 'Ab1', 'C2', 'G1',       # question
    'F2', 'Ab1', 'G1', 'C2',       # answer
    'C2', 'Ab1', 'F2', 'G1',       # restatement
    'Ab1', 'Ab1', 'C2', 'C2',      # outro — the villain note holds the floor
]
bass = [(n, W) for n in BASS_LINE]
assert len(bass) == BARS

# --- Drone: open fifth under everything -------------------------------------
drone_c = [('C2', W)] * BARS
drone_g = [('G1', W)] * BARS

# --- Arp: the old procedural bed's colour (D Eb G Gb — Cm with a tritone) ---
ARP_SEQ = ['D3', 'Eb3', 'G3', 'Gb3']
arp_notes = []
for bar in range(BARS):
    in_arp = bar < 4 or 8 <= bar < 12 or bar >= 16  # intro, answer, outro
    for eighth in range(8):
        arp_notes.append((ARP_SEQ[(bar + eighth) % 4] if in_arp else 'R', E))
assert sum(b for _, b in arp_notes) == W * BARS

# --- Percussion: NOTHING on beat 1. Kick on 3, hat on the and-of-4. ---------
kick_steps, hat_steps = [], []
for _bar in range(BARS):
    for step in range(16):
        kick_steps.append(1 if step == 8 else 0)          # beat 3
        hat_steps.append(1 if step == 12 else 0)          # and-of-4

SCORE = {
    'bpm': 63,
    'voices': [
        {'wave': 'sine',     'gain': 0.66, 'echo': 0.35, 'vibrato': (5.2, 0.30), 'pan': 0.15, 'notes': lead},
        {'wave': 'triangle', 'gain': 0.38, 'pan': 0.0, 'legato': True, 'notes': bass},
        {'wave': 'sine',     'gain': 0.09, 'pan': -0.35, 'legato': True, 'notes': drone_c},
        {'wave': 'sine',     'gain': 0.07, 'pan': 0.35, 'legato': True, 'notes': drone_g},
        {'wave': 'pulse25',  'gain': 0.12, 'echo': 0.45, 'pan': -0.2, 'notes': arp_notes},
    ],
    'percussion': [
        {'type': 'kick', 'gain': 0.55, 'steps': kick_steps},
        {'type': 'hat',  'gain': 0.16, 'steps': hat_steps},
    ],
}
