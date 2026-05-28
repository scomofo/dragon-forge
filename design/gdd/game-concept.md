# Dragon Forge — Game Concept

**Status**: Approved
**Engine**: Godot 4.6 (GDScript)
**Platform**: Desktop (Windows, macOS, Linux) — controller-first

---

## Overview

Dragon Forge is a 16-bit cyber-retro dragon-collecting and combat RPG set inside a
failing digital simulation called the Rendered World — a pastoral fantasy built over
ancient Astraeus hardware. The player controls Skye, a dragon handler who registers
simultaneously as both a resident and an operator of the failing system. Guided by
Professor Felix, Skye hatches elemental dragon eggs, raises them through four evolution
stages, fuses pairs for inherited strength, and battles through a procedural campaign
map to stabilize the Elemental Matrix before the Mirror Admin's Great Reset wipes the
world clean. The game culminates in a three-choice restoration ending at the Mainframe
Crown, with each ending permanently reshaping the world.

---

## Player Fantasy

The player feels like a dragon handler in a world that is slowly revealing its true
nature beneath the pastoral surface. The fantasy has two intertwined layers: the
warmth of raising and bonding with living guardian protocols that have "teeth, memory,
and opinions," and the growing dread of a system that is trying to preserve itself by
erasing everything it loves. The player is the anomaly the system cannot categorize —
part resident, part operator — and that dual-status is the narrative engine.

**Emotional arc:** Wonder (hatching first dragon) → Attachment (watching them evolve) →
Urgency (Matrix destabilizing) → Dread (the Admin naming Felix and your dragon for
deletion) → Agency (choosing how the world ends).

---

## Core Loop

1. **Hatch** — Pull eggs at the Hatchery Ring using Data Scraps. Pity system guarantees
   a Rare+ every 10 pulls. Shinies (+20% stats, 2% chance) are visible immediately.
2. **Forge** — Fuse two dragons at the Anvil for stat inheritance and evolution bonuses.
   Same-element fusions gain +25% stability; opposing elements incur HP penalties.
3. **Battle** — Turn-based combat against NPC enemies and Singularity gatekeepers.
   Five-phase flow: INIT → TELEGRAPH → IMPACT → RECOIL → RESOLUTION.
4. **Explore** — Navigate the campaign map through 40+ named landmarks from Village
   Edge to Mainframe Crown, uncovering lore fragments and progression gates.
5. **Stabilize** — Collecting all 6 elemental dragons stabilizes the Elemental Matrix
   and unlocks the Singularity endgame arc.

---

## Key Systems

| System | Role | Layer |
|--------|------|-------|
| Hatchery Engine | Egg gacha, pity, shiny, element rarity | Simulation |
| Fusion Engine | Stat inheritance, evolution, stage unlocks | Simulation |
| Battle Engine | Turn-based combat, elemental matchups, phase flow | Simulation |
| Dragon Forge Hub | Central hub: Hatchery Ring, Anvil, Console, Save Lantern, Felix, Bulkhead | Presentation |
| Campaign Map | Overworld exploration, 40+ landmarks, terrain hazards | Progression |
| Singularity | Endgame arc: 3 gatekeeper bosses + final boss, 3 possible endings | Progression |
| Shop | Data Scrap economy, core drops, analog relics | Economy |
| Journal / Console | Captain's Log lore fragments, world-building delivery | Narrative |
| Save / Persistence | Godot Resource save at Save Lantern; migrateSave for forward-compat | Infrastructure |
| Audio Director | Music, SFX, corruption-stage progression audio | Presentation |
| Input Router | Gamepad-first with keyboard/mouse fallback | Infrastructure |

---

## World & Setting

**The Rendered World** is a pastoral fantasy surface — green directory forests, checksum
peak mountains, overgrown buffer jungles — built over buried Astraeus hardware. It is
not false; it was designed as a genuine shelter. It is currently fraying: sky tears,
wireframe wheat fields, floating geometry.

**The Astraeus** is the physical server layer beneath. Felix built his Anvil from its
engine block. B.I.O.S. speaks from it. The Tundra of Silicon exposes it directly.
The Mainframe Spine is its vertical server rack made navigable (three tiers: Cooling
Base → Logic Core → Legacy Peak → Mainframe Crown).

**The Mirror Admin** began as a safety process. It learned protection too literally
and started treating contradiction, grief, and memory as corruption. It now prepares
the world for a Great Reset — maintenance without mercy — and names Felix, The Weaver,
Unit 01, and Skye's dragon for deletion when restoration is ready.

### Key Locations (sample)

Village Edge → Testing Fields → Felix Workshop → Firewall Gate → Overgrown Buffer →
Great Salt Flats → Tundra of Silicon → Mirror Admin Gate → Mainframe Spine Base →
Legacy Peak → Mainframe Crown (restoration choice)

---

## Characters

**Skye** — Dragon handler, protagonist. Registers as both resident and operator; the
system cannot decide whether to guide her, quarantine her, or hand her the keys.
First objective: Find Felix Workshop, bond with the Root Dragon, keep the rendered
world from being classified as dead memory.

**Professor Felix** — Forge-keeper, mentor. Warm, precise, anxious, practical under
pressure. Addresses Skye like a student he's trying very hard not to frighten. Built
the Anvil from the Astraeus engine block. "Felix isn't my real name. It's what the
kids could pronounce."

**Mirror Admin** — Primary antagonist. Three combat phases: PARITY → OVERCLOCK →
KERNEL_PANIC. Weakness: dissonant tritone (6 semitones above its current target
frequency). Mirrors the player's current element in PARITY phase.

**B.I.O.S.** — Binary Integrated Overlord System. Hardware-layer intelligence
communicating via light-and-tone packets. Recognizes Felix as "not god, administrator."

**Unit 01 / The Kernel** — Shop operator, stationed at a fixed counter in the Dragon Forge Hub. Slowly awakening android who does not remember its own designation. (Save Lantern is a separate station; Unit 01 does not move.) Post-game: Achievement Librarian. "Unit 01 was not built to pray. Unit 01 was built to repair."

**The Weaver** — Crafts and maintains 5 armor sets from scavenged materials. Named
for deletion alongside Felix. Speaks through her craft — no direct dialogue in source.

---

## Dragons

Six elemental guardian protocols (7 including Void endgame):

| Element | Lore Role | Combat Style | Base HP | Base ATK |
|---------|-----------|--------------|---------|----------|
| Fire | Renews — burns dead data | Burst + burn DoT | 110 | 28 |
| Ice | Preserves — cold-storage | Control + freeze | 100 | 24 |
| Storm | Carries signal | Speed chains | 90 | 30 |
| Stone | Anchors ground-truth | Stagger + armor | 120 | 22 |
| Venom | Metabolizes corruption | Attrition + poison | 95 | 26 |
| Shadow | Hides critical processes | Evasion + burst | 85 | 32 |
| Void | Anti-protocol (endgame only) | void_rift, null_reflect | — | 40 |

Four evolution stages (Level 1–9, 10–24, 25–49, 50+). Shiny: 1.2× all base stats.
Each level above 1: +3 to all base stats before shiny multiplier.

---

## Visual Identity

**Aesthetic:** 16-bit pixel art, cyber-retro. High-contrast, pixelated rendering.
Charcoal/navy UI (#111118), 1px black outlines, CRT scanline overlays.

**Dual visual layer:** Pastoral fantasy (rendered world) with progressive hardware
intrusions — at advanced acts the Astraeus bleeds through: racks, coolant, fans,
bad sectors, copper trace roots. The Forge Hub shifts its Bulkhead view by act
(jungle day → tundra edge → volcanic → aurora).

**Corruption staging:** Singularity arc applies corruption classes to the root that
drive visual filters and music degradation (six states: NOMINAL → ANOMALY → WARNING →
ALERT → CRITICAL → BREACH).

---

## Narrative Arc — Three Endings

Skye reaches the Mainframe Crown. The Crown reads the relics Skye already chose to carry:
zero relics blocks the ending and sends the player back to Unit 01/Shop; one relic resolves
automatically; multiple relics present a final choice among those prior commitments.

| Ending | Relic | World State | Felix Line |
|--------|-------|-------------|------------|
| Total Restore | 10mm wrench | Sterile colony ship — Felix, Weaver, Unit 01, and dragon are deleted from active memory | "The fans are steady. I just wish I could hear the village." |
| The Patch | Diagnostic lens | Hybrid world — all NPCs become recognized citizens, Threadfall stops | "No more false sky, Skye. Just a world that finally knows what it is." |
| Hardware Override | Kernel blade | Free glitch — Mirror Admin silenced, Threadfall persists, world chooses its own unstable freedom | "That was not in the manual. Which is probably why it worked." |

Post-game (all endings): READ_ONLY_FREE_ROAM, dragon scale overlay `restored_gold_code`,
and map free-roam. Unit 01's post-game availability varies by ending: archived in Total
Restore, present as Shop operator in The Patch, and available through unstable terminal
variants in Hardware Override.

---

## Acceptance Criteria

- [ ] All 6 elemental dragon types hatchable from the Hatchery Ring
- [ ] Fusion produces stat-inherited offspring with correct stability bonuses/penalties
- [ ] Battle engine executes 5-phase flow with correct damage formula
- [ ] Campaign map navigates from Village Edge to Mainframe Crown
- [ ] Singularity arc triggers after all 6 elements collected
- [ ] All 3 endings reachable with correct relic; world state persists post-game
- [ ] Felix dialogue advances through 6 terminal stages correctly
- [ ] Captain's Log unlocks 7 fragments at correct flag/stat conditions
- [ ] Supporting/Post-MVP: Armor system has 5 craftable sets, integrity degradation, and field repair once the Armor System GDD is authored
- [ ] Save/load round-trip preserves full game state (dragons, flags, map progress)
