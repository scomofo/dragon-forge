# Audio

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: Juice and Feedback — every player action must land with weight and clarity

## Summary

The audio system provides all sound effects and music for Dragon Forge through a single module (`src/soundEngine.js`). It synthesises all SFX procedurally at runtime using the Web Audio API — there are no pre-recorded SFX files. Music is streamed from MP3 assets. The module manages per-screen music routing, element-tinted combat SFX, a low-HP heartbeat tension pulse, per-sound cooldown gates, and a persist-to-localStorage mute/volume preference.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Battle System, Hatchery, Fusion, Singularity, Navigation`

---

## Overview

`soundEngine.js` is a self-contained audio module imported by `App.jsx` and `BattleScreen.jsx`. It exposes two public APIs: `playSound(name, options?)` for one-shot SFX and `playMusic(trackName, immediate?)` for looping background music. All SFX are synthesised live from Web Audio API oscillators and noise buffers — no `.wav`/`.ogg` SFX files are shipped. Music is loaded as `<Audio>` elements playing MP3s from `public/assets/music/`. Volume preferences (SFX, music, mute flag) are written to `localStorage` under key `dragonforge_sound` and survive page reloads.

---

## Player Fantasy

Audio reinforces mastery and consequence. Every attack should feel like it *matters*. The element system is not just visual — each of the eight elements has a distinct sonic character so a player can close their eyes during a supereffective hit and still know which element struck. The heartbeat tells the player they are in danger before the HP bar finishes its animation. Victory should feel earned; defeat should feel final. The overall aesthetic target is **Challenge + Sensation** (MDA): punchy, readable feedback that raises stakes without obscuring information.

---

## Detailed Design

### Sound Categories

Six SFX categories and one alias table are defined in `SFX_SCHEMA` (soundEngine.js:209–278). Each entry records a `role`, a priority tier (0–5), and a per-sound `cooldownMs` guard.

| Category | Sounds | Purpose |
|----------|--------|---------|
| `ui` | buttonClick, buttonHover, navSwitch, screenTransition, journalUnlock, shopPurchase | Navigation and transactional feedback |
| `terminal` | terminalType, terminalOk, terminalWarning, terminalFail, terminalGlitch | Narrative text-crawl and hatchery terminal |
| `hatchery` | eggGlow, eggCrack, eggShake, hatchBurst, dragonReveal | Egg incubation and hatch sequence |
| `combat` | 18 sounds — see Combat SFX below | All in-battle events |
| `fusion` | fusionMerge, fusionBurst, fusionReveal | Dragon fusion ceremony |
| `singularity` | newGamePlusStart, singularityCorrupt, mirrorAdminSpawn | Endgame arc events |
| `world` | mapNodeReach, dragonSelect | Campaign map navigation |

**Aliases** (soundEngine.js:272–278): `uiConfirm → buttonClick`, `uiHover → buttonHover`, `commandSelect → combatCommandSelect`, `commandExecute → combatCommandExecute`, `combatMessage → combatFeedTick`. Callers may use either name.

### Priority and Cooldown System

Every sound carries a `cooldownMs` value. `playSound` reads `performance.now()` (falling back to `Date.now()`) and rejects a play call if the same sound was played within its cooldown window (soundEngine.js:720–728). This prevents audio spam from rapid UI interaction or fast battle-feed loops.

Priority values (0–5) are metadata only — they are not currently enforced at runtime beyond the cooldown gate. The values exist to guide future polyphony management if needed.

| Priority | Meaning | Example sounds |
|----------|---------|----------------|
| 0 | Ambient tick | buttonHover, terminalType, combatFeedTick |
| 1 | Standard feedback | navSwitch, combatCommandSelect, heartbeatThump |
| 2 | Action consequence | screenTransition, attackHit, defend |
| 3 | Significant event | criticalHit-adjacent, fusionBurst, singularityCorrupt |
| 4 | Major reward/threat | criticalHit, ko, levelUp, mirrorAdminSpawn |
| 5 | Session-level climax | victoryFanfare, defeatDrone, newGamePlusStart |

### Combat SFX Catalog

Full list with cooldowns:

| Sound | Role | Cooldown (ms) |
|-------|------|--------------|
| combatCommandSelect | command | 60 |
| combatCommandExecute | execute | 120 |
| combatFeedTick | message | 35 |
| attackLaunch | anticipation | 90 |
| lungeContact | contact | 65 |
| attackHit | hit | 70 |
| superEffective | strong-hit | 90 |
| criticalHit | critical-hit | 140 |
| resisted | weak-hit | 70 |
| miss | miss | 80 |
| defend | guard | 100 |
| shieldDeflectSting | reflect | 110 |
| heartbeatThump | danger-pulse | 140 |
| statusApply | status-apply | 110 |
| statusTick | status-tick | 70 |
| statusExpire | status-expire | 110 |
| ko | ko | 350 |
| victoryFanfare | victory | 1200 |
| defeatDrone | defeat | 1300 |
| xpGain | reward-small | 150 |
| levelUp | reward-major | 450 |
| scrapsEarned | currency | 120 |

### Element-Tinted SFX

Eight elements each receive a pitch offset applied to combat sounds (soundEngine.js:198–207):

| Element | Pitch Detune (cents) |
|---------|---------------------|
| fire | −100 |
| ice | +200 |
| storm | +100 |
| stone | −200 |
| venom | +50 |
| shadow | −150 |
| void | +300 |
| neutral | 0 |

The offset (`ELEMENT_PITCH`) is added to oscillator frequencies in `combatCommandSelect`, `combatCommandExecute`, `attackLaunch`, `attackHit`, `superEffective`, `criticalHit`, `statusApply`, `statusTick`, and `statusExpire`. A secondary synthesis burst — `elementColorBurst(element, delayMs, volume)` (soundEngine.js:316–343) — fires on execute/launch/hit events and uses element-specific waveform shapes:

- **fire**: bandpass noise burst + sawtooth bend
- **ice**: triangle arpeggio + highpass noise
- **storm**: square bend + highpass noise
- **stone**: triangle oscillator + lowpass noise burst (lowest frequencies)
- **venom**: sawtooth bend + bandpass noise
- **shadow**: sawtooth osc + triangle bend + bandpass noise
- **void / others**: square osc + bandpass noise

### Music Per Screen

Music routing lives in `App.jsx` and `BattleScreen.jsx`. Music tracks are enumerated in `MUSIC_TRACKS` (soundEngine.js:736–746):

| Track key | File | Mood | Used on |
|-----------|------|------|---------|
| title | music/theme.mp3 | mysterious | Win-credits screen (handleSingularityBattleEnd) |
| openingTense | music/music_battle_intense.mp3 | tense | Opening sequence alias |
| hatchery | music/music_hatchery.mp3 | warm | Hatchery, Fusion, Journal, Shop, Forge, Stats, Settings |
| select | music/music_select.mp3 | focused | Battle Select screen; post-battle return (non-map) |
| mapWander | music/music_hatchery.mp3 | wandering | Campaign Map screen; post-battle return (map) |
| singularity | music/music_battle_intense.mp3 | dread | Singularity hub; all Singularity battles (immediate=true) |
| battle | music/music_battle.mp3 | active | Standard battle (HP both ≥ 25 %) |
| battleTense | music/music_battle_intense.mp3 | tense | Battle entry (immediate=true) |
| battleIntense | music/music_battle_intense.mp3 | danger | Battle mid-fight when any combatant HP < 25 % |

Note: `mapWander` and `hatchery` both resolve to the same audio file (`music_hatchery.mp3`). `battleTense`, `battleIntense`, and `singularity` all resolve to `music_battle_intense.mp3`.

**`immediate` flag**: when `true`, the new track starts at full volume instantly, cutting the previous track. When `false` (default), a 350 ms crossfade occurs (20-step linear volume ramp, soundEngine.js:762–795). Singularity and boss entries always use `immediate = true` for dramatic effect.

**Same-track guard** (soundEngine.js:800): if the requested track is already playing, `playMusic` returns without action. This prevents music restarts during same-screen re-renders.

### Music During Battle

Battle music reacts dynamically to HP states at the end of each turn resolution (BattleScreen.jsx:1068–1080):

```
if (playerHpPct < 0.25 OR npcHpPct < 0.25):
    playMusic('battleIntense')   // escalates to intense track
else:
    playMusic('battle')          // standard battle track
```

At defeat: `stopMusic()` is called before `playSound('defeatDrone')` so the drone is not competed by looping battle music.

At victory: `playSound('victoryFanfare')`, then if a full-game win (Mirror Admin first kill), `playMusic('title', true)`. Otherwise post-battle routing plays `mapWander` or `select`.

### Heartbeat / Tension System

The heartbeat is an urgency signal triggered exclusively when the **player dragon's** HP falls below 25 % (BattleScreen.jsx:1075–1080). It is never triggered by enemy-only danger.

**Activation** (soundEngine.js:849–858): `startHeartbeat(intervalMs = 600)`. At the default 650 ms interval used in BattleScreen, two `heartbeatThump` pulses fire per cycle — the second at +180 ms after the first (soundEngine.js:852–855). This creates the classic double-thump cardiac rhythm.

**Deactivation** (`stopHeartbeat`): called at turn end when `playerHpPct ≥ 0.25`, on KO, and on win/defeat resolution. Also called on tactical swap (BattleScreen.jsx:624).

`heartbeatThump` synthesis: 85 Hz square wave (75 ms) + 260 Hz lowpass noise burst (55 ms) + 62 Hz triangle (105 ms). Net volume: `sfxVolume × 0.26` on the square, `sfxVolume × 0.34` on the noise.

The heartbeat interval is a single interval ID stored in the module-level `heartbeatInterval` variable. `startHeartbeat` is a no-op if the heartbeat is already running (guards with `if (heartbeatInterval) return`).

### Mute and Volume Preferences

Preferences are stored in `localStorage` key `dragonforge_sound` as JSON with three fields:

| Field | Default | Range | Description |
|-------|---------|-------|-------------|
| `sfxVolume` | 0.7 | 0.0–1.0 | Multiplied into all SFX synthesis volumes |
| `musicVolume` | 0.5 | 0.0–1.0 | Multiplied into `<Audio>` element volume |
| `muted` | false | boolean | Suppresses all output; stops music immediately |

`toggleMute()` flips `muted` and calls `stopMusic()` if the result is `true`. `getSfxVolume()` and `getMusicVolume()` both return 0 when `muted` is true, so synthesis functions bail early (soundEngine.js:46–61).

Volume values are clamped on write: `Math.max(0, Math.min(1, vol))` (soundEngine.js:55, 60).

### Synthesis Primitives

All SFX are assembled from five internal primitives:

| Primitive | Description |
|-----------|-------------|
| `osc(freq, duration, type, volume, detune)` | Single oscillator with exponential gain decay |
| `sweep(startFreq, endFreq, duration, type, volume)` | Frequency-ramped oscillator (pitch slide) |
| `bend(startFreq, midFreq, endFreq, duration, type, volume)` | Two-segment ramp; mid-point at 42 % of duration |
| `noise(duration, filterFreq, filterType, volume)` | White noise through a biquad filter |
| `noiseBurst(duration, filterFreq, filterType, volume, q)` | Noise with linear amplitude taper, variable Q |

Higher-level helpers:

| Helper | Description |
|--------|-------------|
| `arpeggio(notes, type, noteDuration, volume)` | Sequential oscillators offset by `noteDuration` ms each |
| `chord(freqs, duration, type, volume)` | Simultaneous oscillators with 5-cent detuning per partial |
| `delay(ms)` | Promise-based async pause (used in async SFX chains) |

All primitives apply `getSfxVolume()` as a multiplier to the passed `volume`. If the result is 0, the function returns without creating any AudioContext nodes.

### Core Rules

1. Call `playSound(name, options?)` to fire a one-shot SFX. `name` is resolved through `SOUND_ALIASES` first.
2. Per-sound cooldown is enforced before synthesis; a call within the cooldown window is silently dropped.
3. Call `playMusic(trackName, immediate?)` to change the background track. Track name is resolved through `MUSIC_ALIASES`. Same-track calls are no-ops.
4. Music transitions default to 350 ms crossfade. Pass `immediate = true` to cut immediately.
5. Music is always suppressed when `muted = true`; `playMusic` returns immediately.
6. `startHeartbeat(intervalMs)` begins the double-thump urgency pulse. It is idempotent — calling it while already running has no effect.
7. `stopHeartbeat()` cancels the interval and clears the handle. It is safe to call when no heartbeat is active.
8. Element pitch offsets (`ELEMENT_PITCH`) are added to oscillator frequencies in cents-equivalent Hz offsets (not true musical cents — they are raw Hz additions to the base synthesis frequency values).
9. `AudioContext` is created lazily on first use and resumed if suspended (browser autoplay policy handling).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| No music | Initial load, `stopMusic()` called | `playMusic()` called | Silence |
| Track playing | `playMusic()` with a new track name | `stopMusic()` or new track | Loop at `musicVolume`; crossfade out on change |
| Same track | `playMusic()` with current track name | Any new track name | No-op; continues unchanged |
| Heartbeat active | `startHeartbeat()` called | `stopHeartbeat()` called | Double thump every `intervalMs` ms, gated by mute |
| Muted | `toggleMute()` → true | `toggleMute()` → false | All getVolume calls return 0; music stops; SFX bail early |

---

## Formulas

### Synthesis Volume Scaling

```
synthesised_volume = primitive_base_volume * getSfxVolume()
getSfxVolume() = muted ? 0 : prefs.sfxVolume
```

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| primitive_base_volume | float | 0.10–0.95 | hardcoded per SFX definition |
| prefs.sfxVolume | float | 0.0–1.0 | localStorage / default 0.7 |
| synthesised_volume | float | 0.0–0.285 (typical) | computed |

The Web Audio gain node then applies `gain * 0.3` (for `osc`) or `gain * 0.25` (for `sweep`) as a further internal scale. Final perceived amplitude is the product of all three multipliers.

### Music Fade

```
volume_at_step_t = targetVol * (t / steps)      // fade-in
volume_at_step_t = startVol * (1 - t / steps)   // fade-out

steps = 20
stepTime = 350ms / 20 = 17.5ms per step
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| targetVol | float | 0.0–1.0 | `getMusicVolume()` at call time |
| steps | int | 20 | Fixed step count |
| stepTime | float | 17.5 ms | Interval between volume updates |

### Heartbeat Timing

```
cycle_period = intervalMs                          // default 650 ms in BattleScreen
first_thump  = 0 ms offset
second_thump = 180 ms offset
```

At `intervalMs = 650`, the pattern is: thump–thump (gap 180 ms)–silence (gap 470 ms)–repeat.

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| `playSound` called for unknown name | SFX lookup returns undefined; `fn` is falsy; call silently drops | Prevents runtime errors from typos or future removed sounds |
| `playMusic` called while muted | Returns immediately without creating `<Audio>` | Mute is respected at entry; no phantom audio objects |
| `playMusic` called with same track already playing | No-op (same-track guard, line 800) | Prevents music restart on same-screen re-renders |
| `startHeartbeat` called while heartbeat already running | No-op (guard: `if (heartbeatInterval) return`, line 851) | Prevents interval accumulation |
| `AudioContext` suspended (browser autoplay) | `getCtx()` calls `ctx.resume()` on every access | Recovers from suspended state on first user interaction |
| `sfxVolume * primitive_base_volume = 0` | Synthesis function returns before creating AudioContext nodes | Prevents silent no-op node chains accumulating in memory |
| Music `fadeOut` called on paused audio | Resolves the Promise immediately without stepping | Prevents NaN volume arithmetic on paused elements |
| `endFreq` approaches 0 in sweep/bend | `Math.max(endFreq, 20)` clamp applied | Prevents AudioParam error on zero/negative frequency target |
| `stopHeartbeat` called with no active heartbeat | `clearInterval(null)` — no-op in all browsers | Safe to call defensively at any battle state |
| Preferences JSON corrupted in localStorage | `loadPrefs` catch block returns defaults | Graceful degradation to `sfxVolume: 0.7, musicVolume: 0.5, muted: false` |

---

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Battle System (`BattleScreen.jsx`) | Battle depends on Audio | Calls `playSound`/`playMusic`/`startHeartbeat`/`stopHeartbeat` at every turn event |
| App Navigation (`App.jsx`) | Navigation depends on Audio | Calls `playSound`/`playMusic` on every screen transition and battle entry |
| Hatchery (`hatcheryEngine.js` / HatcheryScreen) | Hatchery depends on Audio | Calls hatchery-category SFX during egg and hatch sequences |
| Fusion Screen | Fusion depends on Audio | Calls `fusionMerge`, `fusionBurst`, `fusionReveal` |
| Singularity System | Singularity depends on Audio | Calls `singularityCorrupt`, `mirrorAdminSpawn`, `newGamePlusStart` |
| Persistence (`persistence.js`) | Audio depends on persistence indirectly | Audio prefs use their own `localStorage` key (`dragonforge_sound`), separate from save data |
| Element System (`gameData.js`) | Audio depends on Element System | `ELEMENT_PITCH` table maps element strings to pitch offsets; element strings must match those in gameData |

---

## Tuning Knobs

All values live in `src/soundEngine.js` unless noted.

| Parameter | Current Value | Location | Category | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|----------|----------|------------|-------------------|-------------------|
| Default SFX volume | 0.7 | line 20 | feel | 0.3–1.0 | Louder SFX | Quieter SFX |
| Default music volume | 0.5 | line 20 | feel | 0.2–0.8 | Louder music | Quieter music |
| Music fade duration | 350 ms | lines 762, 783 | feel | 100–800 ms | Slower, smoother transitions | Snappier cuts |
| Music fade steps | 20 | lines 765, 786 | feel | 10–40 | Smoother gradient | Stepped/audible gradient |
| Heartbeat interval | 650 ms | BattleScreen.jsx:1077 | feel | 400–900 ms | Slower tension pulse | Faster, more urgent pulse |
| Heartbeat double-thump gap | 180 ms | line 854 | feel | 80–280 ms | More separated thumps | Merged into single sound |
| Cooldown per sound | per-entry in SFX_SCHEMA | lines 211–269 | feel | see table above | Prevents more rapid repeats | Allows faster re-triggering |
| Element pitch offsets | see ELEMENT_PITCH | lines 198–207 | feel | ±400 cents | More distinct element voices | Flatter, less differentiated |
| `battleIntense` HP threshold | 0.25 (25 %) | BattleScreen.jsx:1070 | gate | 0.10–0.40 | Earlier music escalation | Later music escalation |
| `startHeartbeat` HP threshold | 0.25 (25 %) | BattleScreen.jsx:1076 | gate | 0.10–0.40 | Heartbeat triggers earlier | Heartbeat triggers later |

---

## Visual/Audio Requirements

This document describes the audio system itself. Audio requirements for other systems reference this document.

| Event | Audio Feedback | Priority |
|-------|---------------|----------|
| Any screen navigation | `navSwitch` SFX | 1 |
| Battle entry | `buttonClick` + `battleTense` music (immediate) | 2 |
| Boss entry | `mirrorAdminSpawn` or `buttonClick` + `singularity` music (immediate) | 5 |
| Player move selected | `combatCommandSelect` (element-tinted) | 1 |
| Player move executed | `combatCommandExecute` + `attackLaunch` + element burst | 2 |
| Lunge contact | `lungeContact` (+110 ms after launch) | 2 |
| Normal hit | `attackHit` (element-tinted) | 2 |
| Super-effective hit | `superEffective` (attackHit + bonus sweep) | 3 |
| Critical hit | `criticalHit` (heaviest impact + bell sweep) | 4 |
| Resisted hit | `resisted` | 1 |
| Miss | `miss` | 1 |
| Defend command | `defend` | 2 |
| Shield deflect | `shieldDeflectSting` | 3 |
| Status applied | `statusApply` (element-tinted) | 2 |
| Status tick | `statusTick` (element-tinted) | 1 |
| Status expire | `statusExpire` (element-tinted) | 1 |
| Dragon KO | `ko` | 4 |
| Player HP < 25 % | `startHeartbeat(650)` | 1 (continuous) |
| Player HP ≥ 25 % | `stopHeartbeat()` | — |
| Battle victory | `victoryFanfare` | 5 |
| Battle defeat | `stopMusic` + `defeatDrone` | 5 |
| XP gained | `xpGain` | 2 |
| Level up | `levelUp` (+400 ms after victory) | 4 |
| Scraps earned | `scrapsEarned` (+200 ms after victory) | 1 |
| Shop purchase | `shopPurchase` | 2 |
| Journal unlock | `journalUnlock` | 3 |
| Dragon hatch | `hatchBurst` + `dragonReveal` | 3–4 |
| Fusion complete | `fusionMerge` → `fusionBurst` → `fusionReveal` | 4 |
| Singularity corrupt | `singularityCorrupt` | 4 |
| New Game Plus start | `newGamePlusStart` | 5 |

---

## Game Feel

N/A — turn-based browser game. Frame-data, hitbox timing, input latency targets, controller rumble, and hit-stop are not applicable. The audio system replaces these kinesthetic feel targets with timing offsets between sequential synthesis calls (e.g., `lungeContact` at +110 ms after `attackLaunch`) and cooldown gates that prevent audio spam from degrading perceived impact.

The design goal analogous to "game feel" in this context: every high-stakes combat event should produce a distinct and recognisable sound that a player can identify correctly after 30 minutes of play, without looking at the screen.

---

## UI Requirements

| Information | Display Location | Condition |
|-------------|-----------------|-----------|
| Mute state | Settings screen toggle | Persisted; reflects `prefs.muted` |
| SFX volume | Settings screen slider | Persisted; reflects `prefs.sfxVolume` |
| Music volume | Settings screen slider | Persisted; reflects `prefs.musicVolume` |

The audio system does not own UI; it exposes `isMuted()`, `getSfxVolume()`, `getMusicVolume()`, `toggleMute()`, `setSfxVolume()`, and `setMusicVolume()` for the Settings screen to consume.

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Element strings used in ELEMENT_PITCH | `design/gdd/combat.md` | Element identifier constants (fire, ice, storm, stone, venom, shadow, void, neutral) | Rule dependency |
| HP percentage threshold for music/heartbeat | `design/gdd/combat.md` | Player HP / maxHP ratio | Data dependency |
| Battle turn resolution event sequence | `design/gdd/combat.md` | Turn resolution order (launch → contact → hit → status → KO) | State trigger |
| Singularity corruption stages | `design/gdd/singularity-endgame.md` | Corruption stage progression | State trigger |

---

## Acceptance Criteria

- [ ] `playSound('buttonClick')` produces an audible click within the `cooldownMs` window and is silently dropped if called again within 25 ms
- [ ] `playSound('criticalHit', { element: 'fire' })` produces a distinctly heavier and higher-pitched hit than `playSound('attackHit', { element: 'fire' })` — audible difference confirmed by blind listening test
- [ ] `playSound('criticalHit', { element: 'ice' })` and `playSound('criticalHit', { element: 'stone' })` sound recognisably different from each other — the pitch offset produces a perceptible tonal shift
- [ ] `playMusic('battle')` followed immediately by `playMusic('battleIntense')` produces a smooth crossfade, not an abrupt cut
- [ ] `playMusic('singularity', true)` cuts the previous track immediately with no fade artifact
- [ ] `startHeartbeat(650)` begins a double-thump pattern at approximately 650 ms intervals; the gap between the two thumps is approximately 180 ms
- [ ] `stopHeartbeat()` ends the heartbeat within one cycle period (≤ 650 ms)
- [ ] `toggleMute()` while music is playing stops the music within 350 ms (one fade cycle)
- [ ] After mute toggle, `playSound` calls produce no audio output
- [ ] After un-mute toggle, `playMusic` calls resume audio at the correct volume
- [ ] Preferences survive page reload: if sfxVolume is set to 0.3 and the page is reloaded, `getSfxVolume()` returns 0.3
- [ ] Calling `startHeartbeat()` twice in succession does not produce double-speed heartbeats
- [ ] With `sfxVolume = 0`, all SFX synthesis functions return before creating AudioContext nodes (no silent node accumulation)
- [ ] `playMusic` called with the currently-playing track name does not restart or glitch the track
- [ ] No hardcoded volume values outside `soundEngine.js`

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should priority values enforce polyphony limits (drop lowest-priority sounds when >N voices active)? | game-designer | — | Currently priority is metadata only |
| Should `battleIntense` and `heartbeat` thresholds be the same value (currently both 0.25) or split (e.g., music escalates at 0.30, heartbeat at 0.20)? | game-designer | — | Currently identical; splitting would add nuance |
| `mapWander` resolves to `music_hatchery.mp3` — intentional? Should map have a distinct track? | creative-director | — | Same file; no distinct map track exists |
