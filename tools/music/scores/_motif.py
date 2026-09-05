"""The Heartforge title motif — single source of truth for P2 composed tracks.

From design/gdd/music-identity.md (C minor; the Ab is the flattened 6th —
"that flattened 6th is the villain"):

    Bar 1–2 (question):  C4  Eb4  G4  Ab4 | G4  F4  Eb4  D4
    Bar 3–4 (answer):    Eb4 F4 G4 C5   | B3  C4  —

Every composed track (mirror_admin, victory, defeat, hub, credits) derives
from these two phrases so the whole score shares one melodic identity.
"""

W, H, Q, E, S = 4, 2, 1, 0.5, 0.25

QUESTION = [('C4', Q), ('Eb4', Q), ('G4', Q), ('Ab4', Q),
            ('G4', Q), ('F4', Q), ('Eb4', Q), ('D4', Q)]
ANSWER = [('Eb4', Q), ('F4', Q), ('G4', Q), ('C5', Q),
          ('B3', Q), ('C4', H), ('R', Q)]

MAJOR = {'Eb': 'E', 'Ab': 'A'}  # C minor -> C major (motif-major)


def transpose_major(notes):
    """Rewrite a motif phrase in the parallel major (E and A natural)."""
    out = []
    for name, beats in notes:
        if name == 'R':
            out.append((name, beats))
            continue
        for flat, natural in MAJOR.items():
            if name.startswith(flat):
                name = natural + name[len(flat):]
                break
        out.append((name, beats))
    return out


def octave(notes, shift):
    """Shift every note by whole octaves."""
    out = []
    for name, beats in notes:
        if name == 'R':
            out.append((name, beats))
            continue
        head, octv = name[:-1], int(name[-1])
        out.append((f'{head}{octv + shift}', beats))
    return out


def stretch(notes, factor):
    """Half-time (factor=2) etc. — scale every duration."""
    return [(name, beats * factor) for name, beats in notes]
