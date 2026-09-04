# Music Identity

> **Status**: Binding (commission list). Runtime uses 5 MP3s, remaining procedural beds, and a sequenced Mirror Admin arrangement. P2 is still in progress.
> **Code twins**: `src/musicScores.js` (authored note data), `src/scorePlayer.js` (playback), `src/soundEngine.js` (routing and preferences).

## P2 first delivery — 2026-09-04

- **The Caretaker** replaces Mirror Admin's four-note procedural bed in its existing boss entry point. It is a fixed 16-bar arrangement at **56 BPM**, with the documented melody, an opening A-flat bass, a contrasting bridge, a return, and a resolving phrase. Percussion leaves beat one empty.
- **Heartforge — Motif Study** provides a 16-bar **112 BPM** reference for auditioning the same melody. Both arrangements are available in **Settings → Sound Room**; Play auditions, Stop restores the previous screen's music, and navigation replaces the audition.
- The original `theme.mp3` is preserved and now actually used on the title screen. Its correspondence to the written motif has **not** been established by transcription or listening in this pass. The Motif Study is a reference, not a silent replacement of that asset.
- Scores use a bounded Web Audio scheduler, fixed note data, simple synthesized voices, and no new audio assets or packages. The note arrangement fits an eight-voice budget. This is an arrangement draft for listening review, **not a mastered sampled-instrument soundtrack**.
- Live volume, mute/resume, navigation while muted, rapid cached-track changes, and note disposal have regression coverage. Pending: real-browser listening, balance against SFX, loop seam audition, and comparison with the original title recording.

## Title motif (Heartforge theme)

Write in C minor for documentation. Do not lose the Ab — that flattened 6th is the villain.

```
Bar 1–2  (question):   C4  Eb4  G4  Ab4 | G4  F4  Eb4  D4
Bar 3–4  (answer):     Eb4  F4  G4  C5  | B3  C4  —
```

Mirror Admin is this motif at half-time, flattened 6th in the bass, no percussion on the downbeat. If the budget buys one composer week, spend it there.

## The 12 tracks

1. `title` — keep `theme.mp3`
2. `hub` — keep hatchery until rewritten as motif-major
3. `mapWander` — commission
4. `battleA` — keep `music_battle.mp3`
5. `battleB` — split; stop using intense for opening + low-HP + every fight
6. `battleElite` — commission
7. `singularity` — commission
8. `boss` — commission
9. `mirrorAdmin` — sequenced first arrangement implemented; listening, instrument design, and mastering pending
10. `victory` — sting ≤ 6s
11. `defeat` — sting
12. `credits` — full title arrangement

Acceptance: a 0–credits run plays at least six different authored loops, and the Mirror Admin theme is recognizably the title motif at half-time.

This first delivery does not satisfy the six-loop run criterion. The remaining beds and reused battle tracks still require composition. Do not mark all twelve tracks complete because the runtime can now play a score.
