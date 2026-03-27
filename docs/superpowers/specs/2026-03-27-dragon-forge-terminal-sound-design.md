# Dragon Forge: Terminal Intro & Sound System Design Spec

## Overview

Two features in one spec: (1) a full fake terminal boot sequence replacing the current title screen, and (2) a complete sound system with synthesized SFX via Web Audio API and HTML5 Audio for music tracks with per-screen music and combat intensity crossfading.

---

## 1. Terminal Intro Boot Sequence

Replaces the current `TitleScreen.jsx` with a full terminal simulation.

### 1.1 Sequence (~20-25 seconds total)

```
[BLACK SCREEN]

> DRAGON FORGE SYSTEMS v2.7.1
> INITIALIZING KERNEL...                    [OK]
> LOADING ELEMENTAL MATRIX...               [OK]
> CALIBRATING QUANTUM RESONANCE...          [OK]
> SCANNING FOR DRAGON SIGNATURES...         [WARNING]
> STABILITY INDEX: 23% — CRITICAL           [FAIL]

[SCREEN GLITCH FLICKER]

> ==========================================
> EMERGENCY BROADCAST — DR. FELIX
> ==========================================
>
> [Felix portrait appears]
>
> "The Elemental Matrix is collapsing.
>  Something is draining it from the inside.
>  I've traced the source... The Singularity.
>  It's consuming dragon energy faster than
>  we can stabilize it."
>
> "I need a Dragon Forger. Someone who can
>  hatch, train, and fight. That's you."
>
> [INITIALIZE_SIMULATION.EXE] ← button appears
```

### 1.2 Timing & Effects

- Each system line types at ~50ms per character
- Status tags [OK]/[WARNING]/[FAIL] appear after the line finishes with a brief delay
- [OK] in green (#44ff44), [WARNING] in yellow (#ffcc00), [FAIL] in red (#ff4444)
- Progress bar animates for longer operations (CSS width transition)
- Full-screen glitch effect (hue-rotate + jitter, 300ms) flashes before Felix's message
- Felix portrait (240px) fades in from the left
- Felix's dialogue types character by character at ~40ms per character
- INITIALIZE_SIMULATION.EXE button pulses with orange glow

### 1.3 Skip Behavior

- Clicking anywhere during boot sequence skips to Felix's message
- Clicking during Felix's message reveals all text instantly
- Clicking after all text shown does nothing (must click the button)

### 1.4 Visual Style

- Full black (#000000) background (darker than game's #111118 for terminal feel)
- Green monospace text (#44ff44) for system lines
- White text for Felix's dialogue
- Blinking cursor (█) after the current typing position
- CRT scanline overlay still active
- Terminal container has a subtle border (#333) and padding

---

## 2. Sound Engine (`src/soundEngine.js`)

Single module with two subsystems.

### 2.1 SFX Synthesizer (Web Audio API)

All sound effects generated in real-time using Web Audio API primitives. No audio files needed.

**API:** `playSound(name, options?)` — e.g., `playSound('attackHit', { element: 'fire' })`

**Sound Catalog:**

| Category | Sound Name | Recipe |
|---|---|---|
| UI | `buttonHover` | Square wave 800Hz, 20ms, very quiet |
| UI | `buttonClick` | Square wave 800Hz, 30ms decay |
| UI | `screenTransition` | Filtered noise sweep, 200ms |
| UI | `navSwitch` | Sine tick 600Hz, 15ms |
| Hatchery | `eggGlow` | Rising sine 200Hz→400Hz, 200ms |
| Hatchery | `eggCrack` | Noise burst + sine pop 200Hz, 50ms |
| Hatchery | `eggShake` | Filtered noise rumble, 80ms |
| Hatchery | `hatchBurst` | Noise explosion + ascending sine sweep, 300ms |
| Hatchery | `dragonReveal` | Major chord (C5+E5+G5), square wave, 300ms |
| Combat | `attackLaunch` | Noise whoosh + sine, element-shifted pitch |
| Combat | `attackHit` | Noise thud (100Hz lowpass) + sine impact |
| Combat | `superEffective` | Hit sound + high sine sting 1200Hz, 200ms |
| Combat | `resisted` | Dull noise thud, lowpass filtered, 100ms |
| Combat | `miss` | Descending filtered noise whoosh, 200ms |
| Combat | `defend` | Metallic sine chord (300Hz+450Hz), 150ms |
| Combat | `ko` | Descending sawtooth 200Hz→60Hz, 800ms |
| Combat | `victoryFanfare` | Ascending major arpeggio C5→E5→G5→C6, 80ms each note |
| Combat | `defeatDrone` | Low sawtooth drone 60Hz, filtered, 800ms fade |
| Progression | `xpGain` | Sine tinkle 1000Hz, 40ms |
| Progression | `levelUp` | Ascending arpeggio C5→E5→G5→C6, square wave, 80ms each |
| Progression | `scrapsEarned` | Metallic sine 1400Hz, 30ms, two quick hits |
| Terminal | `terminalType` | Square wave 400Hz, 5ms (per character) |
| Terminal | `terminalOk` | Sine 600Hz, 50ms |
| Terminal | `terminalWarning` | Sawtooth 400Hz, 100ms |
| Terminal | `terminalFail` | Noise burst + low sine 150Hz, 150ms |
| Terminal | `terminalGlitch` | Noise + random frequency oscillator, 300ms |

**Element pitch shifting:** When `options.element` is provided, shift base frequency:
- Fire: -100Hz (deeper, rumbling)
- Ice: +200Hz (higher, crystalline)
- Storm: +100Hz + distortion
- Stone: -200Hz (very low, earth)
- Venom: +50Hz + slight detune
- Shadow: -150Hz + heavy lowpass

### 2.2 Music Player (HTML5 Audio)

Loads and crossfades music tracks.

**Track mapping:**

| Screen | Track File | Behavior |
|---|---|---|
| Title/Terminal | `music_title.mp3` | Starts on boot, atmospheric/dark |
| Hatchery | `music_hatchery.mp3` | Curious/hopeful, loops |
| Battle Select | `music_select.mp3` | Building anticipation, loops |
| Combat (normal) | `music_battle.mp3` | Intense, loops |
| Combat (low HP) | `music_battle_intense.mp3` | Crossfade when player OR enemy below 25% HP |

**Crossfade behavior:**
- Screen transitions: 1 second crossfade
- Combat → intense: 1 second crossfade when HP drops below 25%
- Intense → normal: 1 second crossfade when HP recovers above 25%
- Battle start: immediate cut (no fade) for dramatic effect
- Victory/defeat: stop battle music, play SFX fanfare/drone instead

**Music gracefully degrades:** If a track file isn't found, no error — music simply doesn't play. SFX works independently.

### 2.3 Volume Control

**Stored in localStorage:**
```json
{ "sfxVolume": 0.7, "musicVolume": 0.5, "muted": false }
```

**UI:** Small speaker icon in the NavBar (right side, next to scraps). Click toggles mute. The title screen also shows the icon in the top-right corner.

---

## 3. Integration Points

### 3.1 Music Transitions

```
Title screen loads     → fade in music_title
INITIALIZE_SIMULATION  → fade out title, fade in music_hatchery
Nav to BATTLES         → crossfade to music_select
BEGIN BATTLE           → cut to music_battle
HP drops below 25%     → crossfade to music_battle_intense
HP recovers above 25%  → crossfade back to music_battle
Victory                → stop music, play victoryFanfare SFX
Defeat                 → stop music, play defeatDrone SFX
CONTINUE/TRY AGAIN     → fade in music_select
Nav to HATCHERY        → crossfade to music_hatchery
```

### 3.2 SFX Trigger Points

| Location | Trigger | Sound |
|---|---|---|
| TitleScreen | Each character typed | `terminalType` |
| TitleScreen | [OK] appears | `terminalOk` |
| TitleScreen | [WARNING] appears | `terminalWarning` |
| TitleScreen | [FAIL] appears | `terminalFail` |
| TitleScreen | Glitch effect | `terminalGlitch` |
| NavBar | Tab click | `navSwitch` |
| HatcheryScreen | Pull button click | `buttonClick` |
| HatcheryScreen | Egg glow frame | `eggGlow` |
| HatcheryScreen | Egg crack frames | `eggCrack` |
| HatcheryScreen | Egg shake frames | `eggShake` |
| HatcheryScreen | Hatch burst frame | `hatchBurst` |
| HatcheryScreen | Dragon revealed | `dragonReveal` |
| BattleSelectScreen | Card click | `buttonClick` |
| BattleSelectScreen | BEGIN BATTLE click | `buttonClick` |
| BattleScreen | Player selects move | `buttonClick` |
| BattleScreen | Attack telegraph | `attackLaunch` (with element) |
| BattleScreen | Damage applied | `attackHit` / `superEffective` / `resisted` / `miss` |
| BattleScreen | Defend chosen | `defend` |
| BattleScreen | KO animation | `ko` |
| BattleScreen | Victory overlay | `victoryFanfare` |
| BattleScreen | Defeat overlay | `defeatDrone` |
| BattleScreen | XP awarded | `xpGain` |
| BattleScreen | Level up | `levelUp` |
| BattleScreen | Scraps awarded | `scrapsEarned` |

---

## 4. New Files

| File | Responsibility |
|---|---|
| `src/soundEngine.js` | SFX synthesis + music player + volume control |
| `src/SoundToggle.jsx` | Mute/volume icon component |
| `assets/music/` | Directory for user-provided music tracks |

## Modified Files

| File | Changes |
|---|---|
| `src/TitleScreen.jsx` | Complete rewrite — terminal boot sequence |
| `src/App.jsx` | Pass music transition callbacks |
| `src/NavBar.jsx` | Add SoundToggle component |
| `src/HatcheryScreen.jsx` | Add SFX calls to egg animation |
| `src/BattleScreen.jsx` | Add SFX calls to combat + music intensity switching |
| `src/BattleSelectScreen.jsx` | Add SFX to card/button clicks |
| `src/styles.css` | Terminal styles, sound toggle styles |

---

## 5. Music File Delivery

User provides 5 tracks as MP3 files in `handoff/music/`:
- `music_title.mp3`
- `music_hatchery.mp3`
- `music_select.mp3`
- `music_battle.mp3`
- `music_battle_intense.mp3`

These are copied to `assets/music/` during integration. The system works fully without them — SFX plays regardless.

---

## Out of Scope

- Custom volume slider UI (just mute toggle for now)
- Positional/spatial audio
- Audio sprite sheets
- Dynamic music generation
