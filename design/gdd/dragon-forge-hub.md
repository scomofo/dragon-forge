# Dragon Forge Hub

> **Status**: In Design
> **Author**: Scott + agents
> **Last Updated**: 2026-05-22
> **Implements Pillar**: Presentation — Core Loop Container

## Overview

Dragon Forge Hub is the central interactive space of Dragon Forge — the room Skye returns to between every battle, every expedition, and every choice. It is simultaneously Felix's workshop, an Astraeus hardware node, and the operational floor of the game's core loop. Seven stations define the Hub's function: the **Hatchery Ring**, where Data Scraps are spent to pull elemental dragon eggs from the Rendered World's remaining reserves; the **Anvil**, where two dragons are placed into permanent fusion; the **Roster**, the living ledger of every dragon in Skye's care; the **Forge Console**, where the Captain's Log delivers recovered lore fragments as conditions are met; **Unit 01**, the Hub's resident shop and relic counter; the **Save Lantern**, where progress is committed to persistent memory; and the **Bulkhead**, a viewport into the state of the world outside the Hub. And there is **Felix** — not a station, but the architect of the Anvil, the keeper of the ring, the person who knows more than he says. The Hub does not partition its stations behind loading screens — the player navigates the floor directly, every station visible at all times, switching between them as the situation demands. As the game progresses through its acts, the exterior view through the Bulkhead shifts: jungle canopy and diffused light at Village Edge; tundra shelf with geometric horizon; volcanic skyline with cooling-tower silhouettes; aurora filtering through Astraeus infrastructure directly above. The Hub's layout does not change. The world the player can see through it does. From the player's perspective, the Dragon Forge Hub is where everything that matters is decided — where dragons are brought into existence, where their futures are compressed or sacrificed, where the lore of a dying world surfaces in fragments, and where the silence Felix keeps accumulates into something the player comes to understand without being told.

## Player Fantasy

The Dragon Forge Hub is the room Skye returns to. The Anvil hums at the same pitch it hummed at in the first act. The Save Lantern's light is steady. Felix is at his station, doing work the player cannot quite see — a panel open under the Anvil, a recalibration on the Ring that takes hours and is never announced. He does not look up. The room is intact because he is keeping it intact.

Through the Bulkhead, the world has changed again. The jungle is gone. The tundra is gone. There is a wireframe seam in the sky that was not there last act, and the geometry of the mountains has started coming loose at the edges. The Hub does not change. The view through it does.

***The Hub is not a menu. It is the room Felix is still keeping.***

Every dragon Skye hatches, every fusion she commits, every fragment of the Captain's Log she recovers, every save she lays down — they all happen on this floor, in this light, with him in the corner. The player comes to understand, without being told, that the silence is the work. Felix is not quiet because he has nothing to say. He is quiet because the Anvil needs calibration, the Ring needs tuning, the Lantern needs tending, and he has known since the first act that the Mirror Admin has already begun writing the deletion order with his name on it. He keeps the room anyway. That is the only statement he makes.

When Felix speaks — once, when an Elder rises from the Anvil — the room reorganizes itself around the sentence. The rest of the time, his attention to the floor *is* the floor.

The dread does not enter the room. It accumulates outside the Bulkhead and waits.

> **Designer test:** A Hub feature serves this fantasy if it makes the room feel *held*. A station that draws attention to itself fails. A station that lets the player feel Felix's hand in its calibration passes. A Bulkhead change that telegraphs an act transition passes; an in-Hub animation that interrupts the player's pace fails. If a feature makes the player feel like they are operating a machine rather than standing in a room someone is maintaining for them, it is drifting.

## Detailed Design

### Core Rules

**Hub Access and Navigation**

1. The Dragon Forge Hub is accessible from the Campaign Map via the Bulkhead. It is the player's persistent base of operations throughout the entire game.

2. Seven stations are arranged in a **linear row** across the Hub floor, navigable left/right by d-pad: **Hatchery Ring → Anvil → Roster → Bulkhead → Forge Console → Unit 01 → Save Lantern**. The cycle wraps — d-pad left from Hatchery Ring reaches Save Lantern, and vice versa. Maximum 3 presses from any station to reach any other.

3. All seven stations are visible at all times. No station is hidden behind another screen. No loading screens occur between stations.

4. Felix occupies a fixed position near the Anvil. He is **not** in the d-pad navigation cycle and cannot be targeted, activated, or interacted with during normal play. He is an ambient inhabitant of the room.

5. The **passive HUD** always displays two values without requiring any station activation: (a) current Data Scrap count, (b) total owned dragon count. No other information is shown on the hub floor.

6. There is no party size cap. The player may own an unlimited number of dragons.

**Station Rules**

7. **Hatchery Ring** — Hosts the Hatchery Engine pull flow. Costs 50 Data Scraps (PULL_COST) per pull. When the player has fewer than PULL_COST Scraps, the station can be focused but appears dimmed. Confirm press produces a denial SFX; no text label is shown. The Ring communicates availability through its visual state — at full brightness when a pull is ready, dimmed when it is not. It does not announce its limitation in words.

8. **Anvil** — Hosts the Fusion Engine's full state flow (PARENT_SELECTED → PREVIEW → CONFIRM → RESOLVING → COMPLETE). When the player has fewer than 2 dragons, confirm shows a "Need 2 dragons to fuse" indicator. The Anvil is always visually active (hums, animates) regardless of availability — quieting it when empty would contradict the Player Fantasy.

9. **Roster** — Opens a read-only list of all owned dragons. Each entry shows: element, stage, level, current XP, XP-to-next-level, current HP/ATK/DEF stats, and `is_elder` flag. Dragons listed in acquisition order by default. The Roster provides **sort** options (by element, stage, or level) and **filter** options (by element, by elder status), navigable by d-pad. No management actions (release, rename, trade) are in scope for this GDD. Roster is always available; it displays an empty state before any dragons are owned.

10. **Bulkhead** — The exit point to the Campaign Map. Also displays the current act's exterior view (see Act Views below). Interaction sequence:
    - (a) Player confirms on Bulkhead → **Loadout screen** opens. Player selects which dragon(s) to bring (count and rules governed by Campaign Map GDD — forward contract with this Hub GDD).
    - (b) Loadout confirm → scene transitions to Campaign Map. Loadout cancel → returns to HUB_FLOOR with Bulkhead focused.
    - If the player has 0 dragons, the Bulkhead confirm shows "No dragon selected" — the loadout screen cannot proceed with an empty party.
    - There is no secondary confirmation prompt. Completing the loadout IS the deliberate act of leaving the Forge.

11. **Forge Console** — Delivers Captain's Log lore fragments. Exists in two states:
    - *Neutral*: Console idles. Player may focus and open the log to read prior entries.
    - *Glow*: A subtle glow indicator signals a pending entry. Activating the Console in this state presents the new fragment. After the player reads it, Console returns to Neutral.
    - The `journal_entry_available(fragment_id)` signal from the Journal/Console system triggers the Neutral → Glow transition. The Hub GDD owns the two Console states and the signal interface. The Journal/Console GDD owns all trigger conditions and content.

12. **Unit 01** — Hosts the Shop system. Always activatable — browsing is available at 0 Data Scraps; purchase actions are disabled when insufficient currency is present. Unit 01's dialogue is governed by the Shop GDD.

13. **Save Lantern** — Initiates a save to the current save slot. Save is a background (non-blocking) operation. Confirm on the Lantern starts the save immediately and returns the player to HUB_FLOOR with no navigation lock. The Lantern enters a **Glow** state during the save operation; when the save completes successfully, the Lantern briefly brightens before returning to its steady light. If the save fails, the Lantern displays an error indicator visible from the Hub floor. The player may interact with any other station while a save is in progress. Always available.

**Felix Rules**

14. Felix's looping idle animation depicts maintenance work on the Anvil or Hatchery Ring — the specific content is deferred to art direction. Felix does not acknowledge the player's station selections or actions. Felix's idle has **act-aware posture variants**: his animation reflects the act's state (posture more tense, tools working faster in later acts, as if the room's own urgency has reached him without his acknowledging it). Felix also emits **ambient non-verbal sounds** at low frequency — metal on metal, a sharp exhale, the click of a calibration dial — that make his maintenance audible but never intrusive. These sounds are not tied to player actions. They are the sound of the room being kept.

15. When the Fusion Engine emits `elder_emerged(child_data)`, the Hub queues Felix's Elder dialogue sequence in a **depth-1 queue** — only one pending sequence is stored; subsequent signals before the queue is consumed are silently discarded. The sequence fires the first time the Hub enters HUB_FLOOR state after the signal is received: Felix's one spoken line plays after ELDER_DIALOGUE_DELAY has elapsed from HUB_FLOOR entry. The Hub owns the trigger timing; the dialogue content is owned by the Journal/Console or Dialogue system (forward contract). This is the only time Felix speaks words. The depth-1 queue ensures that if the player somehow triggers two Elder fusions before returning to the Hub floor, Felix speaks once — the second Elder emerges into his silence.

**Bulkhead Act Views**

16. On Hub scene entry, the Hub reads `current_act` (int, 1–4) from save data. The Bulkhead displays the corresponding looping animated sprite:

| Act | Exterior View | Palette |
|-----|---------------|---------|
| 1 | Jungle canopy, diffused light, bioluminescent undergrowth | Green, gold |
| 2 | Tundra shelf, geometric horizon, sparse geometry | Silver, pale blue |
| 3 | Volcanic skyline, cooling-tower silhouettes, thermal haze | Amber, deep red |
| 4+ | Aurora-lit Astraeus infrastructure directly overhead | Blue-violet, white |

The view switches silently on Hub entry — no in-Hub transition animation. The Bulkhead is a looping animated sprite asset (not a live rendered SubViewport). Who writes `current_act` when an act boundary is crossed is a forward contract owned by the Campaign Map GDD.

### States and Transitions

| State | Description | Player Can Act | Exit |
|-------|-------------|----------------|------|
| HUB_FLOOR | Default. D-pad cycles between 7 stations. Save Lantern confirm starts ambient save and stays in HUB_FLOOR. | Yes | Confirm on most stations → STATION_ACTIVE; Confirm on Bulkhead (with 1+ dragons) → LOADOUT |
| STATION_ACTIVE | Station sub-screen open (Hatchery Ring, Anvil, Roster, Forge Console, Unit 01). Each station manages its own internal states. | Within station | B button → HUB_FLOOR (focus restores to last station) |
| LOADOUT | Bulkhead loadout screen open. Player selects campaign dragon(s). | Yes | Confirm loadout → TRANSITIONING / Cancel → HUB_FLOOR (Bulkhead focused) |
| TRANSITIONING | Scene transition in progress (to/from Campaign Map). | No | Scene load complete → HUB_FLOOR (Hatchery Ring focused) |

**Return focus policy:** On return from STATION_ACTIVE → focus restores to the last-active station. On return from Campaign Map or battle result → focus defaults to Hatchery Ring. Save Lantern confirm does not change focus — the Hub stays in HUB_FLOOR with Save Lantern focused throughout the save operation.

**Station availability summary:**

| Station | Unavailable when |
|---------|-----------------|
| Hatchery Ring | Scraps < 50 |
| Anvil | Fewer than 2 dragons owned |
| Bulkhead (exit) | 0 dragons owned |
| All others | Never unavailable |

### Interactions with Other Systems

| System | Direction | Data In | Data Out |
|--------|-----------|---------|----------|
| Hatchery Engine | Downstream | — | Pull request |
| Hatchery Engine | Upstream | Dragon reveal result (element, shiny, new/duplicate); `scraps_changed(new_total)`; `dragon_count_changed(new_total)` | — |
| Fusion Engine | Downstream | Parent IDs, primary designation, confirmation signal | — |
| Fusion Engine | Upstream | `fusion_complete(child_data)`, `elder_emerged(child_data)` | — |
| Journal/Console | Upstream | `journal_entry_available(fragment_id)` → Forge Console glow state | — |
| Save/Persistence | Downstream | — | Save trigger (non-blocking; Save Lantern confirm) |
| Campaign Map | Downstream | — | Scene transition + loadout selection |
| Campaign Map | Upstream | `current_act` value (read on Hub entry from save data) | — |
| Shop | Bidirectional | `scraps_changed(new_total)` (on purchase) | Unit 01 activation signal |
| Dragon Progression | Upstream | Dragon stat data for Roster display | — |
| Battle Engine | Upstream (indirect) | `scraps_changed(new_total)` (on battle reward, via Battle Engine or Campaign Map) | — |
| Audio Director | Upstream (soft) | `audio_event_complete(event_id)` → Felix Elder sequence timing | Station activation cues, Anvil hum, Felix ambient sounds |

> **ADR flags (not GDD decisions):** (1) Whether simulation engines (HatcheryEngine, FusionEngine) are Autoloads or scene-local nodes — affects signal routing and testability. (2) Whether the project uses a global EventBus Autoload for inter-system signals (`elder_emerged`, `fusion_complete`, `journal_entry_available`) or direct node connections. Both must be decided before Hub implementation begins.

## Formulas

The Dragon Forge Hub is a presentation and navigation layer. It contains no simulation formulas of its own — all damage, stat, probability, and XP calculations are delegated to the systems the Hub hosts: Hatchery Engine, Fusion Engine, Battle Engine, and Dragon Progression.

Two derived values are computed by the Hub's display logic:

### Formula 1: Station Focus Cycle Position

The d-pad navigation cycle is a linear index into the ordered station array.

**Variables:**
- `current_index` — integer (0–6), current focused station (0 = Hatchery Ring, 6 = Save Lantern)
- `STATION_COUNT` = 7

```
d-pad right: next_index = (current_index + 1) % STATION_COUNT
d-pad left:  next_index = (current_index - 1 + STATION_COUNT) % STATION_COUNT
```

*Output range:* Always an integer in [0, 6]. No degenerate values possible.

---

### Formula 2: Passive HUD Dragon Count

The dragon count displayed in the passive HUD is a simple count of records in the dragon registry.

```
if save_data == null or not save_data.has("dragons"):
    displayed_dragon_count = 0
else:
    displayed_dragon_count = len(save_data.dragons)
```

*Output range:* Non-negative integer. 0 at game start (including before save_data is first written); unbounded above (no party cap). The HUD never shows a negative count. The null guard prevents a crash on first-session load before save_data is initialized.

### Formula 3: HUD Dragon Count Display String

The passive HUD shows the dragon count as a string, clamped at HUD_OVERFLOW_THRESHOLD.

```
if displayed_dragon_count >= HUD_OVERFLOW_THRESHOLD:
    hud_display_string = str(HUD_OVERFLOW_THRESHOLD - 1) + "+"
else:
    hud_display_string = str(displayed_dragon_count)
```

With HUD_OVERFLOW_THRESHOLD = 1000: count ≤ 999 shows the exact number; count ≥ 1000 shows "999+".

*Note:* HUD_OVERFLOW_THRESHOLD = 1000 (not 999). The previous tuning knob default was stated as 999 — this is corrected here: the threshold is the first value that triggers truncation, not the last value shown normally.

## Edge Cases

### 1. Input Validation

**EC-HUB-01:** Station becomes unavailable while focused — availability evaluated at confirm-press time, not focus time; station does not self-defocus.

**EC-HUB-02:** Station sub-screen completes a flow that changes availability — in-progress flow completes; unavailability gates on next confirm attempt; focus restores to the now-unavailable station.

**EC-HUB-03:** Dragon count changes during Fusion Engine flow — owned by Fusion Engine GDD's data guard at CONFIRM time.

### 2. Navigation Edge Cases

**EC-HUB-04:** D-pad press during STATION_ACTIVE — consumed by sub-screen or ignored; cycle index not modified.

**EC-HUB-05:** Wrap at cycle boundaries — Formula 1 governs: (0−1+7)%7=6 and (6+1)%7=0; wraps in one frame.

**EC-HUB-06:** D-pad input during TRANSITIONING — all input ignored; on Hub re-entry focus resets to Hatchery Ring.

**EC-HUB-07:** B-button in HUB_FLOOR — no-op; no parent screen exists.

**EC-HUB-22:** Focus-restore to unavailable station — focus still restores; unavailability fires at confirm, not focus.

### 3. Bulkhead / Exit Flow

**EC-HUB-08:** Bulkhead confirm with 0 dragons — "No dragon selected" indicator; LOADOUT never entered.

**EC-HUB-09:** Cancel during Loadout — returns to HUB_FLOOR with Bulkhead focused.

**EC-HUB-10:** Loadout confirm — transitions immediately to TRANSITIONING; no secondary confirmation prompt exists.

**EC-HUB-24:** Double input during TRANSITIONING — all input ignored; only one scene transition can be in flight.

### 4. Felix Event Edge Cases

**EC-HUB-12:** elder_emerged during STATION_ACTIVE — deferred until HUB_FLOOR re-entered; signal queued in a depth-1 queue, not dropped.

**EC-HUB-13:** Multiple elder_emerged before Felix speaks — depth-1 queue means only the first signal is stored; subsequent signals are discarded. Felix speaks exactly once per queue drain.

**EC-HUB-23:** Felix mid-idle when elder_emerged fires — completes current idle cycle; Elder sequence begins only in HUB_FLOOR.

### 5. Forge Console State

**EC-HUB-14:** journal_entry_available fires while Console is Glow — Console stays Glow; Journal system owns the queue.

**EC-HUB-15:** journal_entry_available fires while player is reading Console — Hub re-evaluates state on sub-screen exit; re-enters Glow if Journal reports pending entries.

### 6. Save Flow

**EC-HUB-16:** Save Lantern confirm — save is non-blocking; save_data is captured at trigger moment. If the HUD updates while the save is in flight (e.g., a pull completes), the captured save_data reflects the state at confirm-press time, not the in-flight state.

**EC-HUB-17:** Save fails — Lantern's glow clears; an error indicator appears on the Lantern visible from HUB_FLOOR. Player can navigate freely; no retry logic in Hub; recovery and retry strategy owned by Save/Persistence GDD.

### 7. Zero-State / First Entry

**EC-HUB-19:** Hub first entry (0 dragons, 0 Scraps) — HUB_FLOOR defaults to Hatchery Ring focus; Ring and Anvil unavailable; Bulkhead blocked; Roster shows empty state; Unit 01 open (purchases disabled); Save Lantern available; not soft-locked.

**EC-HUB-20:** Roster with 0 dragons — explicit empty-state message; no crash or null entry.

**EC-HUB-11:** Hatchery Ring at exactly 50 Scraps — available (unavailable condition is fewer than 50, not ≤ 50); documented as common implementation bug boundary.

### 8. Return from Campaign Map / Battle

**EC-HUB-18:** current_act > 4 — Hub defaults to Act 4 view (the "4+" row covers all post-Act-4 values).

**EC-HUB-21:** Dragon count at large numbers — HUD displays minimum 4 digits; overflow shows "999+" truncation indicator.

**EC-HUB-25:** current_act missing or malformed in save data — Hub defaults to Act 1 view; not an error surfaced to the player.

## Dependencies

### Hard Dependencies

The Hub cannot operate without these systems. Each must exist before Hub implementation is complete.

| System | Direction | Hub Receives | Hub Sends | Interface |
|--------|-----------|-------------|-----------|-----------|
| Hatchery Engine | Bidirectional | Dragon reveal result (element, shiny, new/duplicate) | Pull request | Hatchery Ring station activates pull flow |
| Fusion Engine | Bidirectional | `fusion_complete(child_data)`, `elder_emerged(child_data)` | Parent IDs, primary designation, confirmation signal | Anvil station activates full fusion state flow |
| Save/Persistence | Downstream | — | Save trigger (Save Lantern confirm) | Lantern confirm invokes save; Hub displays "Saving…" then confirmation |
| Campaign Map | Bidirectional | `current_act` (int, 1–4) read from save data on Hub entry | Scene transition + loadout selection | Bulkhead → Loadout → Confirm → transition |
| Dragon Progression | Upstream | Per-dragon: element, stage, level, XP, XP-to-next, HP/ATK/DEF stats, `is_elder` flag | — | Roster display reads from dragon registry |
| Input Router | Downstream | — | D-pad direction events, confirm (A), back (B) | Hub navigation and station activation depends on Input Router mapping hardware to in-game actions |

### Soft Dependencies / Forward Contracts

Hub has stub states for these — they are safe to omit during early development, but must be resolved before the game ships.

| System | Direction | Hub Receives | Hub Sends | Stub Behavior Without It |
|--------|-----------|-------------|-----------|--------------------------|
| Journal/Console | Upstream | `journal_entry_available(fragment_id)` signal | — | Forge Console idles in Neutral state indefinitely |
| Shop | Downstream | — | Unit 01 activation signal | Unit 01 station is visible and focusable; all purchase actions no-op |
| Audio Director | Bidirectional | Audio event completion signal for `elder_emerged` cue | Station activation cues, Anvil ambient, Bulkhead per-act soundscape | Hub plays no audio; Felix Elder sequence begins immediately without waiting |
| Battle Engine | Upstream (indirect) | Battle results (XP, Scraps earned) arrive via Campaign Map / Dragon Progression, not directly | — | No direct Hub–Battle Engine interface |

### Data Contracts

**Inherited from other GDDs:**
- `is_elder` flag on dragon data — established by Fusion Engine GDD (must be present in dragon schema)
- `current_act` (int, 1–4) in save data — written by Campaign Map GDD (forward contract; Hub reads this field and defaults to Act 1 if absent or malformed)
- `child_data` schema in `elder_emerged(child_data)` and `fusion_complete(child_data)` — the dragon record: `{id, element, stage, level, base_hp, base_atk, base_def, base_spd, is_elder, is_shiny}`. Defined by Fusion Engine GDD. Hub routes `child_data` to the Narrative/Dialogue system for the Elder line; Hub does not inspect the payload beyond routing.

**Owned by this GDD:**
- `PULL_COST` = 50 (Data Scraps) — Hub's availability gate for Hatchery Ring; Hatchery Engine GDD is already consistent with this value

**Signal contracts required from upstream systems:**

The Hub's passive HUD and availability gates must stay current throughout a session. The following signals must be defined and emitted by the responsible systems:

| Signal | Emitted by | Hub handler |
|--------|-----------|-------------|
| `scraps_changed(new_total: int)` | Hatchery Engine (on pull), Shop (on purchase), Battle Engine (on battle reward) | Update HUD Scrap count; re-evaluate Hatchery Ring availability |
| `dragon_count_changed(new_total: int)` | Hatchery Engine (new dragon added), Fusion Engine (via `fusion_complete`) | Update HUD dragon count; re-evaluate Anvil and Bulkhead availability |
| `fusion_complete(child_data)` | Fusion Engine | Update dragon count (net −1), re-evaluate Anvil gate, check elder queue |
| `elder_emerged(child_data)` | Fusion Engine | Queue Felix Elder sequence (depth-1); discard if queue already occupied |
| `journal_entry_available(fragment_id)` | Journal/Console system | Transition Forge Console Neutral → Glow |

**Forward contracts established by this GDD:**
- Journal/Console GDD must emit `journal_entry_available(fragment_id)` when a new entry is ready; Hub owns only the Neutral/Glow state transition on receipt
- Shop GDD must define Unit 01's dialogue and purchase flows; Hub owns only the activation signal
- Campaign Map GDD must write `current_act` to save data when an act boundary is crossed; Hub owns only the read
- Audio Director GDD must define an `audio_event_complete(event_id)` signal that the Hub can use to confirm the `elder_emerged` audio cue has finished; ELDER_DIALOGUE_DELAY is the Hub's fallback if no completion signal is available
- Hatchery Engine must emit `scraps_changed` on each pull deduction; Shop must emit `scraps_changed` on each purchase; Battle Engine must emit `scraps_changed` on each battle reward

### ADR Flags

Two architectural decisions must be made before Hub implementation begins:

1. **Autoload vs. scene-local for simulation engines** — affects whether HatcheryEngine and FusionEngine are globally accessible Autoloads or nodes added to the Hub scene. Impacts signal routing and test isolation.
2. **Global EventBus vs. direct node connections** — affects how `elder_emerged`, `fusion_complete`, and `journal_entry_available` signals route between systems. A global EventBus simplifies cross-scene communication but introduces a hidden coupling surface; direct connections are explicit but require node references at startup.

## Tuning Knobs

The Dragon Forge Hub is a presentation and navigation layer; its tuning knobs govern feel and availability thresholds, not simulation balance.

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| PULL_COST | 50 | 10–200 | Data Scraps required per Hatchery Ring pull; also the availability gate (Ring unavailable when scraps < PULL_COST) |
| STATION_COUNT | 7 | Fixed | Number of navigable stations; drives Formula 1 modulo operand |
| HUB_ENTRY_FOCUS | 0 (Hatchery Ring) | 0–6 | Station index focused on Hub entry from Campaign Map or post-battle return |
| ELDER_DIALOGUE_DELAY | 1.0s | 0.5–2.0s | Time between `elder_emerged` audio event settling and Felix beginning his line |
| SAVE_INDICATOR_DURATION | 1.5s | 0.5–3.0s | Duration of "Saving…" indicator before confirmation is shown |
| HUD_OVERFLOW_THRESHOLD | 1000 | 100–9999 | First dragon count value that triggers "999+" truncation; counts below this display exactly. See Formula 3. |

**Ordering constraints:**

1. **PULL_COST is shared with Hatchery Engine GDD** — if this value changes, Hatchery Engine's pull validation must update in sync. Neither GDD may change PULL_COST unilaterally.

2. **STATION_COUNT must not be changed without updating Formula 1** — the modulo operand in the station cycle formula is STATION_COUNT; a mismatch between the GDD constant and implementation produces an out-of-bounds cycle index. Changes require simultaneous GDD revision and implementation update.

## Visual/Audio Requirements

### Visual

- Hub floor is a persistent layout; all 7 stations and Felix are visible at all times from a single fixed camera angle.
- Station focus indicator clearly marks the active station without obscuring adjacent stations.
- Unavailable stations show a distinct visual state when focused — not hidden, visible but gated.
- Anvil ambient animation loops continuously; visually distinguishable from a hypothetical inactive state.
- Forge Console Glow state: subtle indicator (glow, pulse, or shimmer) that is noticeable in the peripheral view but does not interrupt player flow.
- Bulkhead displays a looping animated sprite per act (4 assets total); the view switches silently on Hub entry, no in-Hub transition animation.
- Felix: looping idle animation depicting maintenance work on the Anvil or Hatchery Ring; specific content deferred to art direction. Felix has act-aware posture variants — the same maintenance tasks, but the body language of the later acts reflects the world's urgency without Felix ever acknowledging it verbally. Posture variant switches silently on Hub entry.
- Save Lantern has two visual states visible from HUB_FLOOR: **Steady** (normal, save complete), **Glow** (save in progress). On save completion, Lantern briefly brightens before returning to Steady. On save failure, Lantern shows an error indicator.
- Passive HUD: unobtrusive but always legible; minimum 4-character field width for the dragon count display.

### Audio

- Hub floor ambient: persistent music/atmosphere track; loops seamlessly throughout the Hub session.
- Anvil hum: low persistent SFX kept separate from the ambient music track; stops only when the Hub is exited.
- Felix ambient sounds: low-frequency non-verbal SFX (metal on metal, calibration clicks, a sharp exhale) at irregular intervals. These are diegetic maintenance sounds — never timed to player actions, never frequent enough to become rhythm.
- D-pad navigation: distinct SFX fires on each station focus change.
- Station confirm: activation SFX fires when a station sub-screen opens.
- Station unavailable: distinct denied SFX (differentiated from confirm) fires when confirm is pressed on an unavailable station.
- Save Lantern: soft SFX on confirm (save begins); brief brightening tone on save completion. No blocking audio.
- Forge Console Glow: subtle notification SFX when `journal_entry_available` triggers the Neutral → Glow transition.
- Elder sequence: `elder_emerged` audio event fires first (owned by Fusion Engine / Audio Director); Felix's line plays after ELDER_DIALOGUE_DELAY on HUB_FLOOR entry (or immediately if already in HUB_FLOOR); Hub waits for `audio_event_complete(event_id)` signal from Audio Director if available, otherwise uses ELDER_DIALOGUE_DELAY as fallback timer.
- Bulkhead exit confirm: transition-out SFX fires when Loadout confirm triggers TRANSITIONING.

## UI Requirements

- All 7 stations are navigable by d-pad and face button (A = confirm, B = back). No hover-only interactions.
- Focus indicator is visible without requiring any additional input — the currently-focused station is always marked.
- Station sub-screens inherit the same d-pad/face-button navigation model; no station introduces mouse-required interactions.
- Unavailability indicator text is displayed at the station level when confirm is pressed while unavailable — not as a separate screen or modal.
- Roster must be scroll-safe: with unlimited dragons owned, the list must support long-press d-pad scroll or hold-to-scroll; no item count ceiling that produces an overflow crash.
- Roster sort/filter controls are accessible at the top of the Roster sub-screen via d-pad left/right; d-pad up/down navigates entries. Sort and filter state resets to acquisition-order/no-filter on Roster open.
- Passive HUD displays Data Scrap count and dragon count simultaneously, independently of any station focus; minimum 4-character field width for dragon count; "999+" truncation at HUD_OVERFLOW_THRESHOLD (≥ 1000).
- Forge Console Glow indicator must be readable in the peripheral view — motion-based or brightness-based rather than color-only (accessibility requirement: not color-exclusive signaling).
- Save Lantern does NOT block navigation — save is a background operation; the Lantern's visual state communicates progress without locking the player.
- Hatchery Ring unavailability is communicated through visual dimming only; no text indicator label is shown. Denial SFX on confirm-press while unavailable is the only active feedback.
- Bulkhead exit uses a single confirmation (Loadout selection). No secondary "Leave the Forge?" prompt.
- No loading screens occur between stations on the Hub floor.

## Acceptance Criteria

### Navigation

**AC-HUB-01:** D-pad right from Hatchery Ring → Anvil becomes focused.

**AC-HUB-02:** D-pad right from Save Lantern → Hatchery Ring becomes focused (wrap).

**AC-HUB-03:** D-pad left from Hatchery Ring → Save Lantern becomes focused (wrap).

**AC-HUB-04:** Any station is reachable within 3 d-pad presses from any other station.

**AC-HUB-05:** D-pad input while STATION_ACTIVE → cycle index unchanged; sub-screen handles or ignores input.

**AC-HUB-06:** Exiting STATION_ACTIVE → focus restores to the station that was active when the sub-screen opened.

**AC-HUB-07:** Hub entry from Campaign Map or post-battle → focus defaults to Hatchery Ring (index 0).

**AC-HUB-08:** B-button pressed in HUB_FLOOR → no state change; no crash.

### Station Availability

**AC-HUB-09:** Hatchery Ring with exactly 49 Scraps → confirm press produces denial SFX; no text indicator shown; no pull initiated; Ring visual remains dimmed.

**AC-HUB-10:** Hatchery Ring with exactly 50 Scraps → confirm opens pull flow.

**AC-HUB-11:** ~~REMOVED — redundant with AC-HUB-10. If 50 Scraps opens the pull flow, 51 does by the same rule. No separate boundary exists above 50.~~

**AC-HUB-12:** Anvil with 1 dragon owned → confirm shows "Need 2 dragons to fuse" indicator.

**AC-HUB-13:** Anvil with 0 dragons owned → confirm shows "Need 2 dragons to fuse" indicator.

**AC-HUB-14:** Anvil with 2+ dragons owned → confirm opens fusion flow.

### Bulkhead Exit Flow

**AC-HUB-15:** Bulkhead confirm with 0 dragons → "No dragon selected" indicator; LOADOUT screen does not open.

**AC-HUB-16:** Bulkhead confirm with 1+ dragons → LOADOUT screen opens.

**AC-HUB-17:** Cancel during LOADOUT → returns to HUB_FLOOR with Bulkhead focused.

**AC-HUB-18:** LOADOUT confirm → Hub enters TRANSITIONING state; scene transition to Campaign Map begins. No secondary confirmation prompt appears.

**AC-HUB-19:** ~~REMOVED — "Leave the Forge?" no longer exists. AC-HUB-18 covers loadout-confirm-to-transition.~~

**AC-HUB-20:** ~~REMOVED — "Leave the Forge? No" no longer exists. Loadout cancel (AC-HUB-17) is the only exit path back to HUB_FLOOR from the Bulkhead flow.~~

**AC-HUB-21:** All input ignored during TRANSITIONING state.

### Felix

**AC-HUB-22:** Pressing d-pad left or right from any of the 7 stations never produces focus on Felix. Felix's model never receives a selection indicator under any d-pad input sequence.

**AC-HUB-23a:** With no STATION_ACTIVE event for at least 60 seconds, Felix's idle animation loops continuously without stopping or freezing; animation playback position advances monotonically.

**AC-HUB-23b:** Felix's idle animation continues playing during any STATION_ACTIVE state; frame counter or animation playback position advances while a station sub-screen is open.

**AC-HUB-23c:** Felix's idle posture variant matches the current act: Act 1 uses the Act 1 posture asset; Act 4 uses the Act 4 posture asset. Variant is applied on Hub entry; a mismatch between current_act and displayed posture is a test failure.

**AC-HUB-24:** `elder_emerged` received while Hub is in HUB_FLOOR → Felix dialogue sequence begins no sooner than ELDER_DIALOGUE_DELAY (1.0s) and no later than ELDER_DIALOGUE_DELAY + 0.5s after HUB_FLOOR state entry. If `audio_event_complete` signal is received before that window elapses, the sequence begins on receipt of that signal instead.

**AC-HUB-25:** `elder_emerged` received during STATION_ACTIVE → signal is stored in depth-1 queue; Felix sequence begins between ELDER_DIALOGUE_DELAY and ELDER_DIALOGUE_DELAY + 0.5s after the next HUB_FLOOR entry.

**AC-HUB-26:** Two `elder_emerged` signals received before Felix speaks → Felix speaks exactly once; no second sequence plays after the first completes unless a new `elder_emerged` arrives after the queue is drained.

### Bulkhead Act Views

**AC-HUB-27:** `current_act` = 1 → Bulkhead sprite node displays the Act 1 asset (jungle/bioluminescent loop); Act 2, 3, and 4 assets are not visible. *Visual sign-off required: art-director approval against reference screenshot in `production/qa/evidence/hub-act1-bulkhead.png`.*

**AC-HUB-28:** `current_act` = 2 → Bulkhead sprite displays Act 2 asset (tundra/geometric loop); no other act assets visible. *Visual sign-off: `production/qa/evidence/hub-act2-bulkhead.png`.*

**AC-HUB-29:** `current_act` = 3 → Bulkhead sprite displays Act 3 asset (volcanic/cooling-tower loop); no other act assets visible. *Visual sign-off: `production/qa/evidence/hub-act3-bulkhead.png`.*

**AC-HUB-30:** `current_act` = 4 or greater → Bulkhead sprite displays Act 4 asset (aurora/Astraeus loop); no other act assets visible. Verified at current_act = 4 AND current_act = 5 (confirming clamping behavior). *Visual sign-off: `production/qa/evidence/hub-act4-bulkhead.png`.*

**AC-HUB-31:** `current_act` absent or malformed in save data → Bulkhead defaults to Act 1 view; no player-visible error.

### Passive HUD

**AC-HUB-32:** HUD Scrap count is visible and reflects the correct data model value in the following states: HUB_FLOOR (idle), HUB_FLOOR (any station focused), and STATION_ACTIVE (any station open). Station activation does not hide the HUD.

**AC-HUB-33:** HUD dragon count is visible and reflects the correct data model value in the following states: HUB_FLOOR (idle), HUB_FLOOR (any station focused), and STATION_ACTIVE (any station open). Station activation does not hide the HUD.

**AC-HUB-34:** Dragon count of 0 → HUD displays "0".

**AC-HUB-35:** Dragon count of 999 → HUD displays "999".

**AC-HUB-36:** Dragon count ≥ 1000 → HUD displays "999+" (overflow truncation indicator). Dragon count of 999 displays "999" (exact). Dragon count of 1000 displays "999+" (truncated). This boundary matches HUD_OVERFLOW_THRESHOLD = 1000.

**AC-HUB-37:** Dragon count and Scrap count each update within one rendered frame of the corresponding data model change. After a Hatchery Ring pull flow closes, the HUD Scrap count reflects the post-deduction value (N − 50); the HUD dragon count reflects the post-pull value. Stale values from before the pull are a test failure.

### Forge Console

**AC-HUB-38:** Console initialises in Neutral state on Hub entry.

**AC-HUB-39:** `journal_entry_available(fragment_id)` received → Console transitions to Glow state.

**AC-HUB-40:** Console in Glow state activated → presents new fragment; Console returns to Neutral after player reads it (absent further pending entries).

**AC-HUB-41:** Console in Neutral state activated → opens log to read prior entries; Console remains Neutral.

**AC-HUB-42:** `journal_entry_available` received while Console is already Glow → Console stays Glow; no duplicate transition or crash.

### Unit 01 / Shop

**AC-HUB-43:** Unit 01 confirm with any Scrap count ≥ 0 → Unit 01 shop screen opens. No locked-state indicator or "Insufficient" message appears at the station entry point.

**AC-HUB-44:** Unit 01 activated with 0 Scraps → browsing available; purchase actions disabled with an "Insufficient Scraps" indicator.

### Roster

**AC-HUB-45:** Roster with 0 dragons → shows explicit empty-state message; no crash or null-entry rendering.

**AC-HUB-46:** Roster with 1+ dragons → each entry displays element, stage, level, current XP, XP-to-next-level, HP/ATK/DEF stats, and `is_elder` indicator. All six fields present for each entry; any missing field is a test failure.

**AC-HUB-47:** Roster entries appear in dragon acquisition order.

**AC-HUB-48:** Roster is read-only — no release, rename, or trade actions are present or accessible.

### Save Lantern

**AC-HUB-49:** Save Lantern confirm → Lantern immediately enters Glow state; Hub remains in HUB_FLOOR; player can navigate to any other station without waiting.

**AC-HUB-50:** Save completes successfully → Lantern briefly brightens (completion pulse), then returns to Steady state. Player receives no modal or blocking confirmation.

**AC-HUB-51:** Save fails → Lantern Glow clears; error indicator appears on the Lantern visible from HUB_FLOOR. Player can navigate freely; no retry logic is present in the Hub.

**AC-HUB-52:** Player can focus and activate any other station while a save is in progress; d-pad navigation is not locked during the save operation. Test by pressing d-pad immediately after Save Lantern confirm — navigation must respond.

### Anvil Visual

**AC-HUB-53:** Anvil ambient animation loop observable at 2+ dragons is the same loop observable at 0 dragons — same animation asset, same playback speed, same glow/particle state. The animation is not paused, stopped, or replaced with an alternate idle asset when the dragon count is below 2.

### New ACs from Revision

**AC-HUB-54:** D-pad right pressed from each station in sequence produces focus on the next station in documented order: Hatchery Ring → Anvil → Roster → Bulkhead → Forge Console → Unit 01 → Save Lantern → Hatchery Ring (wrap). All 7 transitions tested; any out-of-order result is a test failure.

**AC-HUB-55:** TRANSITIONING state ends when the target scene (Campaign Map) is fully loaded; input is accepted in the target scene. If the Hub is entered again (returning from Campaign Map), TRANSITIONING ends and Hub enters HUB_FLOOR with Hatchery Ring focused.

**AC-HUB-56:** Felix Elder dialogue sequence completes (either through natural end of audio or player dismiss input, whichever applies per Dialogue system spec) → Hub returns to normal HUB_FLOOR operation; all stations remain navigable; no input lock persists after the sequence ends.

**AC-HUB-57:** After Felix Elder sequence fires and completes (queue drained), opening and closing 3 consecutive STATION_ACTIVE sub-screens without a new `elder_emerged` signal does not re-trigger the Felix sequence. Queue is consumed exactly once per signal.

**AC-HUB-58:** Hatchery Ring pull completes successfully with N Scraps → HUD Scrap count displays N − 50 after the pull flow closes. Pre-pull count is not displayed post-pull; any value other than N − 50 is a test failure.

**AC-HUB-59:** Forge Console in Glow state with 2 pending journal entries → player reads first entry → Console remains in Glow state (second entry pending). Console transitions to Neutral only after all pending entries have been read.

**AC-HUB-60:** While save is in progress (Lantern in Glow state), d-pad inputs, station confirms, and cancel inputs are all accepted normally. B-button from a STATION_ACTIVE entered during a save correctly returns to HUB_FLOOR; save continues in background.

**AC-HUB-61:** A dragon with `is_elder = true` → Roster entry displays a visible elder indicator (art-director specifies the exact visual — badge, label, or glow) that is absent on entries where `is_elder = false`. Test requires at least one elder and one non-elder in roster. *Visual sign-off required: `production/qa/evidence/roster-elder-indicator.png`.*

**AC-HUB-62:** Roster sort function: selecting "Sort by level" → entries reorder so each entry's level is ≥ the level of the entry above it (ascending). Selecting "Sort by element" → entries group by element (all Fire together, all Ice together, etc.). Default sort (acquisition order) shows entries in the order they were acquired; newly hatched dragon appears at the bottom.

## Open Questions

**OQ-HUB-01 (RESOLVED — Campaign Map GDD):** Loadout screen scope is now specified by Campaign Map. Max expedition party = 1–3 dragons; slot 1 = active/lead; slots 2–3 = benched; no element/stage restriction; mid-expedition swaps are permitted only among the current expedition loadout at landmark nodes, not during battle. The Hub GDD owns the screen shell and must reference Campaign Map for loadout rules.

**OQ-HUB-02 (Non-blocking — Narrative/Dialogue GDD):** Felix's Elder dialogue line content is a forward contract to the Narrative/Dialogue system. The Hub owns the trigger timing (ELDER_DIALOGUE_DELAY, depth-1 queue, HUB_FLOOR re-entry gate). Content has not been authored.

**OQ-HUB-03 (Partially resolved):** Roster sort/filter has been added to the spec (sort by element/stage/level, filter by element/elder status). Long-scroll pagination mechanism (whether to use infinite scroll or page-based navigation) is still deferred to UI implementation phase.

**OQ-HUB-04 (Non-blocking — Audio Director GDD):** Anvil hum pitch stability across acts. The current spec defines the hum as constant throughout the game. The question of whether the hum's pitch or character should shift as the world degrades (act-by-act audio deterioration) is deferred to the Audio Director GDD.

**OQ-HUB-05 (Non-blocking — Shop GDD / Audio Director GDD):** Unit 01 ambient presence. When Felix is silent and no stations are active, does Unit 01 produce ambient sound or react to player focus? Deferred to the Shop GDD and Audio Director GDD.
