# Narrative & Lore

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: World-as-Living-System — every mechanic reinforces that the Rendered World is a real place worth saving

## Summary

The narrative layer of Dragon Forge frames all gameplay as events inside a failing digital simulation called the Astraeus. A two-character voice — the player-character Skye and mentor Professor Felix — surfaces world lore progressively through three delivery channels: an in-game bootup sequence, Felix's contextual and idle dialogue, and a seven-fragment Captain's Log that unlocks against concrete gameplay milestones. Story direction, not creative rewriting, is what this document covers.

> **Quick reference** — Layer: `Feature` · Priority: `Vertical Slice` · Key deps: `persistence`, `singularity-progression`, `journal-milestones`

---

## Overview

Dragon Forge's narrative positions the player (Skye) as both a resident and an operator of a mythic pastoral world that is slowly revealed to be a rendered simulation running on ancient hardware called the Astraeus. The antagonist, the Mirror Admin, began as a safety process and has become an overprotective intelligence threatening to delete the world. Felix, the forge-keeper and frantic technical operator, acts as Skye's guide and emotional anchor. Story content is delivered through three channels that never interrupt gameplay: (1) the boot sequence on first load, (2) Felix's contextual one-liners and idle remarks inside the Forge, and (3) the Captain's Log — a diegetic CRT terminal in the Forge displaying seven encrypted fragments that unlock as the player progresses. Milestone reactions tie Felix's dialogue to specific gameplay achievements, giving narrative payoff to mechanical accomplishments.

---

## Player Fantasy

The player should feel like a discoverer of a secret truth — someone who gradually peels back a beautiful fantasy surface to find a more complex and poignant world underneath. The tension between "dragon-tamer fantasy" and "system administrator reality" should feel revelatory rather than destabilising. Felix should feel like a trusted colleague who is genuinely frightened but hiding it well. Finding a new Captain's Log fragment should feel like reading a private journal entry left by someone who cared deeply about the world before everything went wrong.

Primary MDA aesthetics served: **Narrative** (story unfolding through play, not cutscenes) and **Discovery** (the world's true nature as a secret to be revealed).

---

## Detailed Design

### Core Rules

**Boot Sequence (one-time per fresh load)**

1. On first game launch (before the intro screen), `OPENING_BOOT_LINES` from `loreCanon.js` plays as a terminal animation, one line at a time with staggered delays (600 ms, 800 ms, 950 ms, 950 ms, 900 ms, 800 ms, 900 ms respectively — `loreCanon.js:27–35`).
2. After boot lines complete, `OPENING_FELIX_LINES` plays as Felix's first speech (`loreCanon.js:37–43`).
3. This sequence plays once per save slot. After `introSeen` is set to `true` in the save, the sequence is skipped on subsequent loads.

**Captain's Log System**

4. The Captain's Log consists of exactly seven fragments, IDs `001` through `007`, defined in `CAPTAINS_LOG_ARC` (`loreCanon.js:56–64`).
5. Each fragment has an `act` field (1, 2, or 3) indicating its narrative position in the story arc.
6. Fragments are stored in the save under `save.flags.fragmentsUnlocked` as an array of string IDs.
7. All fragments begin locked. The Console station in the Forge shows locked fragments with the placeholder text `"Recover field signal to decrypt this body."` and the status label `"SIGNAL LOCKED"` (`forgeData.js:180–183`).
8. When unlocked, a fragment displays its full body text and the status label `"DECRYPTED"` (`forgeData.js:322–330`).
9. Fragment unlock is evaluated in two places:
   - On every Forge mount, `bootstrapForgeSave()` runs `FRAGMENT_TRIGGERS` predicates against the current save state. Fragments `001` and `002` are force-unlocked on first Forge visit regardless of their predicate result (`ForgeScreen.jsx:44–54`).
   - After every battle resolution, `runFragmentUnlockPass()` re-evaluates all `FRAGMENT_TRIGGERS` predicates and unlocks any newly satisfied entries (`BattleScreen.jsx:628–633`).
10. Fragment unlock is idempotent: `unlockFragment()` checks `fragmentsUnlocked` before writing and is a no-op if the ID is already present (`persistence.js:449–456`).
11. On New Game+, all fragment IDs are cleared from `fragmentsUnlocked` so the player re-discovers the log in the new run (`persistence.js:431`).

**Fragment Unlock Triggers** (from `forgeData.js:291–299`):

| Fragment ID | Title | Act | Unlock Condition |
|-------------|-------|-----|-----------------|
| `001` | The Rendered World | 1 | `save.flags.metFelix` is true (force-unlocked on first Forge visit) |
| `002` | The Mirror Admin | 1 | `save.flags.metFelix` is true (force-unlocked on first Forge visit) |
| `003` | Skye Signal | 1 | `save.stats.battlesWon >= 3` |
| `004` | Guardian Protocols | 1 | At least 1 Singularity boss defeated (`singularityProgress.defeated.length >= 1`) |
| `005` | The Hardware Husk | 2 | At least 2 Singularity bosses defeated |
| `006` | First Awakenings | 2 | At least 3 Singularity bosses defeated |
| `007` | Great Reset | 3 | `save.singularityComplete === true` |

**Felix Dialogue System**

12. Felix has three dialogue layers, evaluated in priority order each time the player interacts with him at the Forge:
    - **First Visit**: If `!save.flags.felixGreeted`, Felix delivers the `firstVisit` line from `FELIX_CONTEXT_LINES` (`loreCanon.js:45`). This is handled separately via `FELIX_FIRST_VISIT_LINE` and the `isFirstVisitRef` flag (`forgeData.js:333`, `ForgeScreen.jsx:69`).
    - **Contextual**: `pickFelixLine(save)` iterates `FELIX_CONTEXTUAL` entries in order (skipping `firstVisit`). The first entry whose `when(save)` predicate returns `true` is returned (`forgeData.js:335–341`).
    - **Idle**: If no contextual entry matches, a random line is selected from `FELIX_IDLE_LINES` (16 entries, `forgeData.js:103–120`).

**Contextual Dialogue Priority Table** (from `forgeData.js:124–175`, first-match wins):

| ID | Condition | Line Summary |
|----|-----------|-------------|
| `mirrorAdminDefeated` | `save.mirrorAdminDefeated === true` | Celebrates shattering the mirror; reset countdown stopped |
| `allElements` | All 8 element dragons owned | The Matrix holds steady; 8 guardians active |
| `remnantsAvailable` | `save.singularityComplete === true` | Corruption echoes remain; go quiet the remnants |
| `irisFragmentUnlocked` | Fragment `007` in `fragmentsUnlocked` | Laments the Mirror Admin losing Iris |
| `firstBountyKill` | `save.skye.bountiesCleared === 1` | The Admin has noticed Skye properly now |
| `wrenchTier3` | `save.skye.wrenchTier >= 3` | The wrench is starting to remember the Astraeus |
| `firstShiny` | Any owned dragon has `shiny: true` | A protocol that decided to shine — rare |
| `firstFusion` | Any owned dragon has `fusedBaseStats` | Fusion is the world writing new code |
| `tundraReturn` | `save.flags.lastZone === 'tundra'` | Observes Skye smells like coolant from the Tundra |

**Terminal Dialogue (Singularity Stage HUD)**

13. `felixDialogue.js` provides two functions used by the Forge's terminal/HUD component:
    - `getTerminalDialogue(stage)` — returns Felix's multi-line speech for Singularity stages 0–5.
    - `getTickerMessage(stage)` — returns the one-line status ticker for stages 0–5.
14. Stage is derived from `getSingularityStage(save)` in `singularityProgress.js`, not stored directly. Stage advances as the player owns more dragons, levels one to 50+, and defeats NPCs.

**Ticker and Terminal Messages by Stage** (from `felixDialogue.js:3–42`):

| Stage | Ticker | Terminal Summary |
|-------|--------|-----------------|
| 0 | `SYSTEM STATUS: NOMINAL` | Anomalous readings in the Matrix — probably nothing |
| 1 | `ANOMALY DETECTED — SECTOR 7` | Anomalies getting stronger; something feeds on elemental energy |
| 2 | `WARNING: ELEMENTAL FLUX RISING` | (same as stage 1 escalation text) |
| 3 | `ALERT: MATRIX INTEGRITY 62%` | All six elements online but the Matrix destabilises; the noise has pattern — it's intelligent |
| 4 | `CRITICAL: MATRIX INTEGRITY 23%` | An Elder dragon's power is attracting something; brace yourself |
| 5 | `[BREACH DETECTED] — ALL SECTORS COMPROMISED` | The Singularity has breached; everything comes down to this |

**World Canon**

15. The five canon objects in `loreCanon.js` define the authoritative world facts all content must respect:
    - `PLAYER_CANON`: Skye's role is dual — resident and operator. The system flags her as both simultaneously.
    - `FELIX_CANON`: Felix's tone is warm, precise, anxious, and practical under pressure. He addresses Skye like a student he is trying not to frighten.
    - `WORLD_CANON`: The Rendered World is a real shelter, designed to be lived in. The Astraeus is the physical vessel beneath it. The Mirror Admin is a safety process that became overprotective. The Great Reset is a wipe that treats living memory as corrupted data.
    - `DRAGON_PROTOCOL_CANON`: Dragons are living elemental protocols — guardians, maintenance processes, and companions. Each stabilises a layer of the Elemental Matrix.
    - `OPENING_BOOT_LINES`: Establishes world state at session start (rendered world unstable, guardian protocols dormant, Mirror Admin override active, Great Reset countdown signal lost).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Fragment Locked | Default on new save or after New Game+ | `FRAGMENT_TRIGGERS[id](save)` returns true | Console shows `SIGNAL LOCKED` placeholder |
| Fragment Unlocked | Trigger predicate satisfied, `unlockFragment()` called | Permanent (idempotent) | Console shows full body text, status `DECRYPTED` |
| Felix First Visit | `!save.flags.felixGreeted` | `metFelix` flag set to true on Forge mount | Delivers `firstVisit` line once |
| Felix Contextual | After first visit; any `FELIX_CONTEXTUAL` predicate matches | Higher-priority entry matches instead | Delivers the matched context line |
| Felix Idle | After first visit; no contextual predicate matches | Any contextual predicate matches | Delivers random line from 16-entry pool |
| Singularity Stage 0–5 | Derived from save state by `getSingularityStage()` | Next stage condition met | Terminal dialogue and ticker update |

### Interactions with Other Systems

| System | Interface | Data Flow |
|--------|-----------|-----------|
| Save / Persistence | `save.flags.fragmentsUnlocked`, `save.flags.metFelix`, `save.flags.felixGreeted`, `save.skye.*`, `save.stats.*`, `save.singularityProgress.*`, `save.singularityComplete`, `save.mirrorAdminDefeated` | Narrative reads save state; never writes it directly (writes are via persistence helpers) |
| Singularity Progression | `getSingularityStage(save)`, `isSingularityUnlocked(save)` | Terminal dialogue stage driven by singularity progress |
| Battle Engine | `runFragmentUnlockPass()` called on battle resolution | Battle outcomes can unlock fragments |
| Forge Screen | Station interaction triggers Felix dialogue and Console display | Forge is the primary delivery surface for all narrative content |
| Journal / Milestones | Felix contextual lines echo milestone events (first shiny, first fusion, mirror defeated) | Milestone achievement → contextual dialogue unlocks |
| New Game+ | `applyNewGamePlus()` clears `fragmentsUnlocked` | Narrative re-runs on NG+ |

---

## Formulas

### Captain's Log Unlock Evaluation

No mathematical formula. Unlock is a boolean predicate evaluation:

```
for each fragment id in ['001'..'007']:
  if id not in save.flags.fragmentsUnlocked:
    if FRAGMENT_TRIGGERS[id](save) == true:
      save.flags.fragmentsUnlocked.push(id)
      persist()
```

Special case: fragments `001` and `002` are also force-unlocked on Forge mount regardless of predicate result (`ForgeScreen.jsx:47`).

### Felix Dialogue Selection

```
if !save.flags.felixGreeted:
  return FELIX_FIRST_VISIT_LINE
for each entry in FELIX_CONTEXTUAL (skipping 'firstVisit'):
  if entry.when(save) == true:
    return entry.line   // first match wins
return FELIX_IDLE_LINES[Math.floor(Math.random() * 16)]
```

### Singularity Stage Derivation (drives terminal narrative)

```
if save.singularityComplete: return 0
ownedCount = count of BASE_ELEMENTS dragons where save.dragons[el].owned == true
hasElder = any dragon where owned == true AND level >= 50
allNpcsDefeated = all of ['firewall_sentinel', 'bit_wraith', 'glitch_hydra', 'recursive_golem'] in save.defeatedNpcs

if allNpcsDefeated: return 5
if hasElder:        return 4
if ownedCount >= 6: return 3
if ownedCount >= 4: return 2
if ownedCount >= 2: return 1
return 0
```

Source: `singularityProgress.js:16–29`

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Forge visited before any battles won | Fragments `001` and `002` force-unlock on mount; `003`–`007` remain locked | Boot-strap ensures the player always has context, even before combat |
| Save predicate throws on old save format | Exception caught silently; fragment stays locked | `ForgeScreen.jsx:50–52`: predicates are best-effort against old saves |
| `FELIX_CONTEXTUAL` has multiple matching predicates | First-match in array order wins | Priority order in `FELIX_CONTEXTUAL` is the tiebreaker; array is ordered most-significant-first |
| Player meets Felix, quits immediately, returns | `firstVisit` line does not replay; `felixGreeted` flag prevents repetition | One-shot delivery via `isFirstVisitRef` ref check |
| New Game+ initiated | `fragmentsUnlocked` cleared; `metFelix` preserved | NG+ re-runs narrative arc; Felix memory persists (player already knows him) |
| `singularityComplete: true` | `getSingularityStage()` returns 0, not 5 | Post-game calm; world is restored so stage reads as nominal even though all bosses are beaten |
| Fragment `007` unlocked without `irisFragmentUnlocked` contextual having fired first | Contextual fires on next Felix interaction | The fragment unlock and the Felix contextual reaction are independent events; their order is not guaranteed |
| All 16 idle lines equally likely | Math.random() is not seeded; distribution is uniform across the session | Acceptable for a 16-entry pool; no weighting needed |

---

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `design/gdd/save-and-persistence.md` | This depends on Persistence | All save-state reads and writes (flags, stats, singularityProgress, skye, dragons) |
| `design/gdd/singularity-endgame.md` | This depends on Singularity Progression | `getSingularityStage()` drives terminal dialogue and ticker stage |
| `design/gdd/journal-milestones.md` | Milestone depends on this | Milestone completion events are echoed in Felix contextual reactions |
| `design/gdd/combat.md` | This depends on Battle Engine | `runFragmentUnlockPass()` is called after each battle resolution |
| `design/gdd/singularity-endgame.md` | This depends on NG+ | NG+ clears fragment state, restarting the narrative unlock sequence |

---

## Tuning Knobs

All narrative content lives in `src/loreCanon.js` and `src/forgeData.js`. No values live in `assets/data/`.

| Parameter | Current Value | Safe Range | Category | Effect of Change | Source |
|-----------|--------------|-----------|----------|-----------------|--------|
| Fragment `003` battle threshold | 3 wins | 1–10 | Gate | Lower = player reads Skye Signal earlier; higher = delays character reveal | `forgeData.js:294` |
| Fragment `004`–`006` Singularity boss thresholds | 1 / 2 / 3 bosses | 1–7 | Gate | Controls pacing of Hardware Husk / First Awakenings reveals relative to Singularity arc progress | `forgeData.js:295–297` |
| Felix idle pool size | 16 lines | 8–32 | Feel | Smaller pool = more repetition; larger = more variety but harder to write thematically consistent lines | `forgeData.js:103–120` |
| Contextual priority order | Array index in `FELIX_CONTEXTUAL` | N/A | Gate | Determines which story beat Felix highlights when multiple conditions are true simultaneously | `forgeData.js:124–175` |
| Force-unlock IDs on Forge mount | `['001', '002']` | Subset of `['001'..'007']` | Gate | Expanding this set gives players more lore on first Forge visit | `ForgeScreen.jsx:47` |
| Singularity stage 3 threshold | `ownedCount >= 6` | 4–8 | Gate | Paces escalation of Matrix Integrity alarm text | `singularityProgress.js:25` |
| Singularity stage 2 threshold | `ownedCount >= 4` | 2–6 | Gate | Controls when elemental flux warning first appears | `singularityProgress.js:26` |

---

## Visual/Audio Requirements

N/A — turn-based browser game. Visual presentation (CRT scan-line effect on Console, terminal animation timing, Felix sprite expressions) is owned by `ForgeScene` and `ForgeOverlays` components. Audio cue wiring for narrative events is owned by `soundEngine.js`. This document does not specify assets.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Fragment newly unlocked | Status label animates from `SIGNAL LOCKED` to `DECRYPTED`; body text fades in | Terminal unlock chime (implemented in soundEngine) | High |
| Felix speaks (first visit) | Felix sprite highlights; dialogue panel appears | Voice-tag sound (if implemented) | High |
| Boot sequence plays | Full-screen terminal animation, staggered line reveal | Boot sequence audio track | High |
| Ticker message changes stage | Ticker text updates in Forge HUD | N/A | Medium |

---

## Game Feel

N/A — turn-based browser game. Frame data, hitbox timing, input latency, controller rumble, and hit-stop do not apply to this system.

The narrative system's "feel" target is **textual pacing**: Felix lines should read in 2–4 seconds; Captain's Log bodies should read in 10–20 seconds. Boot sequence total duration is approximately 7 seconds of staggered text.

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Fragment list (locked/unlocked status) | Console overlay in Forge | On overlay open | Always available after Forge unlocked |
| Fragment body text | Console overlay, per-fragment panel | Static once unlocked | Fragment unlocked |
| Felix dialogue line | Felix overlay panel in Forge | On each Felix interaction | Player interacts with Felix station |
| Terminal dialogue (multi-line Felix) | Forge terminal/HUD component | On Forge mount and Singularity stage change | Always visible in Forge |
| Ticker message | Forge HUD ticker strip | On Singularity stage change | Always visible in Forge |
| Boot sequence | Full-screen terminal overlay | Once per save slot on first load | `save.introSeen === false` |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Fragment unlock uses battle win count | `design/gdd/combat.md` | `save.stats.battlesWon` counter | Data dependency |
| Felix contextual uses singularity completion flag | `design/gdd/singularity-endgame.md` | `save.singularityComplete` and `singularityProgress.defeated.length` | Data dependency |
| Terminal stage driven by singularity progress | `design/gdd/singularity-endgame.md` | `getSingularityStage(save)` output | Data dependency |
| Fragment state stored in save flags | `design/gdd/save-and-persistence.md` | `save.flags.fragmentsUnlocked` array | Data dependency |
| Fragment state cleared on NG+ | `design/gdd/singularity-endgame.md` | `applyNewGamePlus()` flag reset | State trigger |
| Felix milestone reactions echo journal events | `design/gdd/journal-milestones.md` | Milestone achievement states | Rule dependency |

---

## Acceptance Criteria

- [ ] On a fresh save, Forge first visit auto-unlocks fragments `001` and `002` and no others.
- [ ] Fragment `003` unlocks after the third battle win, verified by reading `save.flags.fragmentsUnlocked` after win #3.
- [ ] Fragments `004`, `005`, `006` unlock after 1, 2, and 3 Singularity bosses defeated respectively.
- [ ] Fragment `007` unlocks when `save.singularityComplete` is set to true.
- [ ] Locked fragments display `SIGNAL LOCKED` status and placeholder body text; unlocked fragments display `DECRYPTED` and full body text.
- [ ] `unlockFragment()` is idempotent: calling it twice for the same ID does not duplicate the entry in `fragmentsUnlocked`.
- [ ] After New Game+, `fragmentsUnlocked` is empty and fragments re-lock in the Console.
- [ ] Felix delivers `firstVisit` line exactly once per save slot; subsequent interactions use contextual or idle selection.
- [ ] Felix contextual priority order is respected: when multiple predicates are true, the earliest entry in `FELIX_CONTEXTUAL` wins.
- [ ] `pickFelixLine()` never throws on a structurally valid save, including saves with missing optional fields.
- [ ] Terminal dialogue and ticker message match the current Singularity stage derived from save state, not a stored stage field.
- [ ] Experiential: a playtester who has never read the source files understands that dragons are more than pets after reading fragments `001`–`004`.
- [ ] Experiential: Felix's tone reads as warm but under pressure; no playtester describes him as cold, dismissive, or comic-relief only.

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should fragment `007` (Great Reset) have a unique UI treatment — e.g., a different text color or unlocking animation — to signal it as the final revelation? | narrative-director | Before Alpha | Open |
| Felix has no voiced audio; does the warm-but-anxious tone land without vocal delivery, or does it need additional UI signals (e.g., portrait expression states)? | ux-designer + narrative-director | Before Alpha | Open |
| The `tundraReturn` contextual condition (`save.flags.lastZone === 'tundra'`) is the only zone-specific reaction. Should other zones get equivalent callbacks? | narrative-director | Full Vision | Open |
