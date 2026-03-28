# Dragon Forge — SFX Generation Guide

## Overview

Instructions for generating sound effects for Dragon Forge. The game currently uses procedural Web Audio API synthesis (oscillators, noise buffers) — these instructions are for generating replacement/additional SFX as audio files if desired.

## Current SFX List

These are the sounds the game uses (defined in `src/soundEngine.js`):

### UI Sounds
| Key | Description | Style |
|---|---|---|
| `buttonClick` | Generic button press | Short click/tap, 8-bit blip |
| `navSwitch` | Tab navigation switch | Quick swoosh/slide, digital |
| `screenTransition` | Major screen change | Whoosh or warp sound, 0.3s |

### Battle SFX
| Key | Description | Style |
|---|---|---|
| `attackLaunch` | Attack initiated (telegraph phase) | Rising tone, energy charging |
| `attackHit` | Normal damage dealt | Impact thud, meaty hit |
| `superEffective` | 2x damage hit | Louder impact + sparkle/shatter |
| `resisted` | 0.5x damage hit | Dull thud, muffled |
| `miss` | Attack missed | Whoosh, air swing |
| `defend` | Defend action | Shield clang, metallic ring |
| `ko` | Dragon knocked out | Heavy collapse, dramatic fall |
| `victoryFanfare` | Battle won | Short triumphant melody, 2-3s |
| `defeatDrone` | Battle lost | Low drone, somber, 2-3s |
| `xpGain` | XP awarded | Ascending chime arpeggio |
| `levelUp` | Level up notification | Bright ascending fanfare, shorter than victory |
| `scrapsEarned` | DataScraps earned | Coin/crystal collect sound |

### Status Effect SFX
| Key | Description | Style |
|---|---|---|
| `statusApply` | Status effect applied to target | Debuff sound — dark whoosh or hex cast |
| `statusTick` | DOT damage tick (burn/poison) | Sizzle or bubbling, brief |
| `statusExpire` | Status effect wears off | Release sound — light chime, dispel |

### Hatchery SFX
| Key | Description | Style |
|---|---|---|
| `eggGlow` | Egg starts glowing | Warm hum, gentle resonance |
| `eggCrack` | Egg cracking | Crack/snap sound, ceramic breaking |
| `eggShake` | Egg shaking | Rattle, short wobble |
| `hatchBurst` | Egg bursts open | Explosion/burst, bright and dramatic |
| `dragonReveal` | Dragon revealed from egg | Magical reveal, sparkle + roar |

### Fusion SFX
| Key | Description | Style |
|---|---|---|
| `fusionMerge` | Two dragons merging | Energy convergence, building power |
| `fusionBurst` | Fusion flash | Bright explosion, energy release |
| `fusionReveal` | Fusion result revealed | Similar to dragonReveal but deeper, more powerful |

### Terminal SFX
| Key | Description | Style |
|---|---|---|
| `terminalType` | Single character typed | Keyboard click, very short |
| `terminalOk` | System check OK | Positive beep/blip |
| `terminalWarning` | System check WARNING | Warning tone, slightly dissonant |
| `terminalFail` | System check FAIL | Error buzz, harsh |
| `terminalGlitch` | Glitch/static burst | Digital noise burst, 0.3s |

## Audio Specifications

- **Format:** MP3 or WAV (MP3 preferred for web delivery)
- **Sample Rate:** 44100 Hz
- **Channels:** Mono
- **Duration:** 0.1-0.5s for UI/combat SFX, 2-3s for fanfares
- **Style:** 8-bit / 16-bit retro, consistent with the game's cyber-retro aesthetic
- **Volume normalization:** Normalize to -3dB peak

## Generation Prompts

If using AI music tools (Suno, Udio, etc.), use these prompt patterns:

**For combat sounds:**
> "8-bit retro game sound effect, [description], short, punchy, pixel art game style, no music"

**For UI sounds:**
> "retro game UI sound, [description], very short blip/click, 8-bit style"

**For fanfares:**
> "8-bit victory fanfare, triumphant, short 2-3 second melody, retro game style, chiptune"

**For ambient/status:**
> "dark retro game sound effect, [description], synthesizer, 8-bit style"

## Delivery

Drop completed audio files into `assets/sfx/` with filenames matching the keys above (e.g., `assets/sfx/attackHit.mp3`). Update `src/soundEngine.js` to load from files instead of procedural generation.

## Music Tracks

The game also uses procedural music. Music tracks can be replaced with audio files:

| Track Key | Screen | Mood |
|---|---|---|
| `title` | Terminal intro | Mysterious, tense, building |
| `hatchery` | Hatchery + Fusion + Journal | Calm, wonder, discovery |
| `select` | Battle select | Anticipation, preparation |
| `battle` | Normal battle | Energetic, aggressive |
| `battleIntense` | Battle (low HP) | Same energy but more urgent/faster |

A theme song has been provided: `2026_03_28_03_18_56_949_Before_We_Ignite.mp3` — this can be used as the title screen music.
