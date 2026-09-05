# Music Identity

> **Status**: Binding. The 12-track commission has landed (see below).
> **Runtime**: `src/soundEngine.js` — `MUSIC_COMMISSION` is the code twin of the 12-track list; every entry is an authored file under `public/assets/music/`.
> **Owner**: the dedicated music pipeline (agent-composed, confirmed 2026-09-04 — "separately" meant separate from the gameplay/presentation agents). Motif-critical tracks (mirrorAdmin, hub, victory, defeat, credits) are composed note-for-note from the written motif and rendered offline (`tools/music/`); atmospheric tracks (mapWander, battleB, battleElite, singularity, boss) are fal.ai Lyria 2 commissions (`tools/asset_gen/gen_music.py`). Gameplay agents must not replace tracks without this owner.

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
9. `mirrorAdmin` — **commission first**
10. `victory` — sting ≤ 6s
11. `defeat` — sting
12. `credits` — full title arrangement

Acceptance: a 0–credits run plays at least six different authored loops, and the Mirror Admin theme is recognizably the title motif at half-time.
