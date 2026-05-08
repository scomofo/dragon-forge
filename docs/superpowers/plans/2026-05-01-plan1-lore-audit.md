# Dragon Forge Godot Rebuild — Plan 1: Lore Audit

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce `docs/lore-inventory.md` as the consolidated canonical lore source of truth by auditing both the Vite `src/` and archive Godot project before any data files or screens are written.

**Architecture:** Read-only scan of both source trees → resolve conflicts per the conflict rule → write a single structured markdown inventory that all future data translation and content work references.

**Tech Stack:** Node.js (for the translate scripts later), PowerShell (file ops), git

---

## Conflict resolution rule

- **Archive wins** (`dragon-forge-godot/scripts/sim/`) for: world lore, character backstory, Skye/Thread/Weaver/Mainframe/Mirror Admin/Great Reset/restoration endings, proper nouns, armor sets, BIOS dialogue, NPC names and states, map landmarks, sidequest text.
- **Vite wins** (`src/`) for: dragon stats/moves, NPC enemies, battle mechanics, shop items, singularity bosses, forge station layout, gameplay-facing content (Felix idle lines, context triggers, terminal dialogue stages, ticker messages).

---

## Tasks

### Task 1 — Read and extract: Characters

**Files to read:**
- `src/loreCanon.js` — `PLAYER_CANON`, `FELIX_CANON`
- `dragon-forge-godot/scripts/sim/lore_canon.gd` — `PLAYER`, `FELIX`
- `dragon-forge-godot/scripts/sim/story_data.gd` — `BIOS_DIALOGUE`, `felix_first_contact_lines()`, `opening_sequence_profile()`
- `dragon-forge-godot/scripts/sim/mirror_admin_logic.gd` — `create_state()`, phase constants
- `dragon-forge-godot/scripts/sim/restoration_data.gd` — `restoration_prompt()`, `create_mirror_reflection()`
- `dragon-forge-godot/scripts/sim/weaver_data.gd` — header comments, `get_armor_set()`
- `dragon-forge-godot/scripts/sim/sidequest_data.gd` — `NPCS["unit_01"]`

**What to extract:**

| Character | Canonical source | Key facts |
|---|---|---|
| Skye | Archive PLAYER dict | name, role = "dragon handler and emerging system administrator", dual-status as resident + operator |
| Professor Felix | Archive FELIX dict; Vite FELIX_CANON for `relationship` and tone | name, role = "forge-keeper, mentor, and frantic technical operator"; tone = "warm, precise, anxious, and practical under pressure"; addresses Skye "like a student he is trying very hard not to frighten" (Vite adds this nuance) |
| Mirror Admin | Archive WORLD dict, `mirror_admin_logic.gd` | "began as a safety process"; phases: PARITY → OVERCLOCK → KERNEL_PANIC; can enter READ_ONLY state; weakness = dissonant frequency (tritone above target); mirrors player element; `hard_reset_active` triggers at packet_integrity ≤ 0.05 |
| B.I.O.S. | `story_data.gd` BIOS_DIALOGUE | Full name: "Binary Integrated Overlord System"; communicates via light-and-tone packets; appears at `vault_first_rack` and `cpu_heatsink` landmarks; lines: boot warnings, thermal notices, source code buff locks |
| Unit 01 / The Kernel | `sidequest_data.gd` NPCS["unit_01"] | Name in-world: "The Kernel"; state: AWAKENED; role: Mobile Shop / Save Point; awareness level 2; line: "I remember that wrench. I do not remember my own name."; post-game role: achievement_librarian (restoration_data.gd) |
| The Weaver | `weaver_data.gd` implicit author; `restoration_data.gd` restoration_prompt line | Named in Mirror Admin's deletion warning: "Felix, The Weaver, Unit 01, and your dragon" listed as unintentional data; crafts and maintains Armor Sets |

**Write to `docs/lore-inventory.md` section `## 1. Characters`** with one subsection per character using the columns: Name, Source, Role, Key Lore Facts, Dialogue Samples.

---

### Task 2 — Read and extract: World concepts

**Files to read:**
- `src/loreCanon.js` — `WORLD_CANON`
- `dragon-forge-godot/scripts/sim/lore_canon.gd` — `WORLD` dict
- `dragon-forge-godot/scripts/sim/world_data.gd` — `TUNDRA_VISUAL_PROFILE`, `CACHE_VAULT_VISUAL_PROFILE`, landmark descriptions for `tundra_of_silicon`, `mainframe_crown`, `mainframe_spine_base`, `mirror_admin_gate`
- `dragon-forge-godot/scripts/sim/mainframe_spine_data.gd` — `TIERS` dict
- `dragon-forge-godot/scripts/sim/restoration_data.gd` — `restoration_prompt()` line, `_visual_shift_for_choice()`
- `dragon-forge-godot/scripts/world/threadfall_overlay.gd` — `GLYPHS`, visual constants

**Concepts to extract (archive wins on all):**

- **Rendered World**: "The pastoral fantasy layer is a rendered world, beautiful because people were meant to live inside it." Vite variant adds: "beautiful because it was designed to be lived in" — use archive phrasing; note Vite adds "designed to be lived in" as a nuance.
- **Astraeus**: "The buried physical vessel/server layer that still powers the rendered world." Also: Astraeus fans spin under Skye's boots (Felix idle line). Stack structure: modern render passes at base, legacy code above, raw permission at Crown.
- **Hardware Husk**: "The damaged machine reality beneath the mythic surface." Visual: racks, coolant, fans, bad sectors, old ports. First appears in Captain's Log fragment 005.
- **Great Reset**: "A hard wipe that treats living memory as corrupted data." Vite adds: "long threat"; countdown signal was lost at game open. Not malice — "maintenance without mercy" (Captain's Log 007). At Mainframe Crown, becomes a pending system choice.
- **Threadfall**: Corrupted execution threads de-rendering local assets. Visual: `0 1 / \ | x` glyphs, 42 threads, speed 90–300px/s based on intensity. Service ticket type: CORRUPTION. Stops in Total Restore and Patch endings; continues in Hardware Override.
- **Mainframe Crown**: Above Legacy Peak. "The sky is raw system logs and a gold-plated drive waits for the Original Seed Backup." The Great Reset is no longer a warning here — it is a pending system choice.
- **Mainframe Spine**: Three tiers — Cooling Base (industrial pipes, spinning fans, 0.0–0.33), Logic Core (glass circuits, laser trajectory rewrites, 0.34–0.66), Legacy Peak (ASCII low-poly, unpredictable collision, 0.67–1.0).
- **Mirror Admin Gate**: White-glass eye over Tundra exit; rewrites purge cycle into boss chamber. Artifact: admin_shard.

**Write to `docs/lore-inventory.md` section `## 2. World Concepts`** as a glossary: term, one-sentence definition, extended notes, visual aesthetic (where defined).

---

### Task 3 — Read and extract: Proper nouns inventory

**Files to read:**
- `dragon-forge-godot/scripts/sim/world_data.gd` — all `LANDMARKS` keys and labels
- `dragon-forge-godot/scripts/sim/world_data.gd` — `TERRAIN_BY_CHAR` labels
- `dragon-forge-godot/scripts/sim/restoration_data.gd` — `revealed_map_labels()` for all three endings
- `dragon-forge-godot/scripts/sim/mainframe_spine_data.gd` — TIERS names
- `dragon-forge-godot/scripts/sim/weaver_data.gd` — ARMOR_SETS names and material IDs
- `dragon-forge-godot/scripts/sim/service_ticket_data.gd` — `QUEST_TYPE_OVERRIDES` quest IDs
- `dragon-forge-godot/scripts/sim/sidequest_data.gd` — `SIDEQUESTS` titles, NPCS names
- `src/forgeData.js` — `RELICS` names, `FORGE_STATIONS` labels
- `src/singularityBosses.js` — boss names

**Categories to list:**

**Place names (overworld landmarks):**
New Landing, Felix Workshop (forge_lab), Digital Forge, Testing Fields, Firewall Gate, Checksum Ring, Overgrown Buffer, Overflow Pipe, Vault of the First Rack, Scrap Pit Arena, Archive Paddock (mint_menagerie), Great Salt Flats, Manual Override, CPU Heat Sink, Lunar Cooling Pool, Lunar Sector, Resonance Bowl, Piano-Key Ridge, Fragmented Deepwood, High-Render Valley, Directory Tree Loop, Glitch Loom, Update Monolith, 404 Sentinel Gate, Ghost Tractor Trace, Z-Fighting Ridge, Southern Partition Gate, Tundra of Silicon, Great Buffer Vault, Physical Relay, Mirror Admin Gate, Glitch-Hunter Market, Mainframe Spine Base, Legacy Peak, Mainframe Crown, Sky-Box Leak, Floating Point Cliffs, Dead Pixel, Kernel Core, Root Directory, Null Edge

**Terrain type names:** Grasslands, Old Access Road, Directory Forest, Overgrown Buffer, Checksum Peaks, Manual Desert, Great Salt Flats, Hardware Husk, Lunar Shelf, Magma Marsh, Battle Arena, Deep Ocean

**Post-game (ending-specific) map labels:** see `revealed_map_labels()` — all three sets (Archived Landing Site / Historical New Landing / Free Landing Commune; Maintenance Intake Archive / Felix Historical Workshop / Felix's Open Intake; etc.)

**System/concept names:** Elemental Matrix, Southern Partition, Root Authority, White-Out Purge, Packet Loss Fog, Overclocked State, Admin Sweep, Z-Fighting, Dead Pixel, Null-pointer drift, Floating Point Drift, Void Draft

**Item/artifact names:** 10mm Wrench, Diagnostic Lens, Kernel Blade, Root Password, Optical Lens, Overclocked State (artifact), Floppy Disk Backup, Physical Relay (artifact), Admin Shard, Ghost Tractor Trace (artifact), Hydraulic Wing, Prism Texture Pass, Integrity Patch, Static Shards, Silken Data, Partition Permissions, Asset Recovery Cache, Seed Code Rare, Clipping Permission, Wrench Overclock, Purge Shield, Frequency Tuner, Mainframe Approach, Scrap Pit Sigil

**Analog Relic names (Vite wins):** Iron Knuckle, Hydra Cog, Coolant Core, Phase Lens, Twin Forge, Resonant Tuning Fork, Astraeus Engine

**Boss/enemy names:** Firewall Sentinel, Corrupt Drake, Scrap Wraith, Glitch Hydra, Bit Wraith, Sub-routine Stalker, Recursive Golem, Lunar Mote, Sys-Admin, Root Sentinel, Data Corruption, Memory Leak, Stack Overflow, The Singularity (3 phases: Ignition / Surge / Void Collapse)

**Write to `docs/lore-inventory.md` section `## 3. Proper Nouns Inventory`** as sub-headed lists under each category above.

---

### Task 4 — Read and extract: Dragon protocols (7 elements)

**Files to read:**
- `src/loreCanon.js` — `DRAGON_PROTOCOL_CANON`, Captain's Log fragment 004
- `dragon-forge-godot/scripts/sim/lore_canon.gd` — `DRAGON_PROTOCOL`
- `dragon-forge-godot/scripts/sim/dragon_data.gd` — `DRAGONS` dict (all 6 base elements)
- `src/loreCanon.js` — Captain's Log 004 body text for element lore roles

**Elements to document:**

| Element | Dragon Name | Lore Role | Attack Style | Base Stats (Vite wins) |
|---|---|---|---|---|
| fire | Magma Dragon | Renews / thermal-exhaust guardian | burst damage and burn pressure | hp 110, atk 28, def 20, spd 18 |
| ice | Ice Dragon | Preserves / freeze guardian | control, mitigation, freeze setup | hp 100, atk 24, def 26, spd 20 |
| storm | Storm Dragon | Carries signal / signal guardian | speed chains and Focus acceleration | hp 90, atk 30, def 16, spd 28 |
| stone | Stone Dragon | Anchors / structural guardian | stagger, armor, heavy counters | hp 120, atk 22, def 30, spd 12 |
| venom | Venom Dragon | Metabolizes / filter guardian | attrition, poison, corrosive debuffs | hp 95, atk 26, def 18, spd 24 |
| shadow | Shadow Dragon | Hides / stealth guardian | evasion, blind strikes, unstable burst | hp 85, atk 32, def 14, spd 26 |
| void | Void Dragon | Endgame / singularity resonance (Vite: unlockable; milestone: `void_hunter`) | void_rift, null_reflect (singularity boss phase 3 only) | not in base DragonData — Singularity final phase only |

**Note:** The summary from both sources converges: "Dragons are living elemental protocols: guardians, maintenance processes, and companions with enough soul to choose Skye back." The Vite PLAYER_CANON adds "with teeth, memory, and opinions." Dragon stage tiers (Archive wins): Stage 1 < lv10, Stage 2 lv10–24, Stage 3 lv25–49, Stage 4 lv50+. Shiny multiplier: ×1.2 to all stats.

**Write to `docs/lore-inventory.md` section `## 4. Dragon Protocols`** as the table above plus the summary paragraph and stage/shiny notes.

---

### Task 5 — Read and extract: Armor sets (The Weaver)

**Files to read:**
- `dragon-forge-godot/scripts/sim/weaver_data.gd` — `ARMOR_SETS` dict, `apply_armor_overlay()`, `_armor_outline_color()`

**All five sets (archive wins entirely):**

| ID | Name | Required Scavenged Item | Materials | Overworld Effect | Side-scrolling Effect | Outline Color | Description |
|---|---|---|---|---|---|---|---|
| obsidian_shell | Obsidian Shell | magma_scale | magma_scale, digital_silk, silicon_shards | thermal_exhaust_stability | steam_trap_immunity | `#ff7a35` | Heat-buffered overlay — ignore unstable exhaust wash |
| refractive_plate | Refractive Plate | optical_lens | optical_lens, digital_silk, fragmented_code | stalker_invisibility | security_node_reveal | `#58dbff` | Light-bending — hide from Sub-routine Stalkers, reveal tripwires |
| silicon_padded_gear | Silicon Padded Gear | silicon_shards | silicon_shards, raw_silk | static_discharge_resistance | input_lag_reduction | `#70ff8f` | Softcode padding — stand on bad collision; +0.28 integrity, −0.16 input lag |
| friction_harness | Friction Harness | 10mm_wrench | 10mm_wrench, digital_silk, steel_bolt | high_traction_dives | pipe_wall_slide | `#ffd166` | Saddle-harness for steep dives and pipe grip; +0.32 traction |
| ascii_aegis | ASCII Aegis | floppy_disk_backup | fragmented_code, floppy_disk_backup, digital_silk | firewall_phase_passage | double_jump_recompile | `#b7fffb` | Low-poly source-tier overlay; phase firewalls; double-jump recompile |

**Repair mechanic notes:** Field repair via 10mm Wrench + steel bolt when gauge is 0.44–0.62; restores +0.22 integrity (capped at 0.78); marks armor TEMPORARY_RESEAT. Integrity below 0.5 triggers GRAY_FLICKER visual decay; below 0.35 requires Weaver patch. VFX screen effect: `scanline_burst` when healthy or repaired; `chromatic_glitch` when decayed.

**Write to `docs/lore-inventory.md` section `## 5. Armor Sets`** as the table above plus the repair mechanic notes.

---

### Task 6 — Read and extract: Endings (3 restoration choices)

**Files to read:**
- `dragon-forge-godot/scripts/sim/restoration_data.gd` — all functions

**Three endings (archive wins entirely):**

**Choice: `total_restore` — "Total Restore"**
- Required relic: `10mm_wrench`
- World state: `sterile_colony_ship`
- NPC citizenship: deleted
- Hardware stability: 1.0
- Threadfall stopped: yes
- Mirror Admin disabled: no
- Summary: "The Original Seed locks into place. The Astraeus stabilizes, but the post-crash citizens are removed from active memory."
- Felix line: "The fans are steady. I just wish I could hear the village."
- Credits lines: "POST: Dragon Registry archived" / "OS LOAD: Colony protocol restored" / "MAP: Historical records sealed"
- Map legend: "VERIFIED archives mark what used to be villages."
- Free roam objective: "Read the sealed Historical Sites and recover what the restore erased."
- Visual shift: `cold_colony_ship_render`
- Accent color: `#d8e7ff`
- Map labels: new_landing → "Archived Landing Site"; forge_lab → "Maintenance Intake Archive"; tundra_of_silicon → "Zero-Fill Record"; mainframe_crown → "Restored Crown Drive"

**Choice: `patch` — "The Patch"**
- Required relic: `diagnostic_lens`
- World state: `recognized_hybrid`
- NPC citizenship: recognized_citizens
- Hardware stability: 0.9
- Threadfall stopped: yes
- Mirror Admin disabled: no
- Summary: "The Diagnostic Lens filters the restore. The Husk repairs itself while Felix, the Weaver, Unit 01, and the dragons become recognized citizens."
- Felix line: "No more false sky, Skye. Just a world that finally knows what it is."
- Credits lines: "POST: Dragon Registry verified" / "OS LOAD: Hybrid render stabilized" / "MAP: Historical Sites unlocked"
- Map legend: "VERIFIED tickets become Historical Sites across the revealed map."
- Free roam objective: "Fly Read-Only Free-Roam, visit Historical Sites, and finish any VERIFIED service tickets."
- Visual shift: `hybrid_high_fidelity_paintover`
- Accent color: `#ffd56b`
- Map labels: new_landing → "Historical New Landing"; forge_lab → "Felix Historical Workshop"; overgrown_buffer → "Control Plaza Historical Site"; tundra_of_silicon → "Recognized Silicon Tundra"; mainframe_crown → "Mainframe Crown Memorial"

**Choice: `hardware_override` — "Hardware Override"**
- Required relic: `kernel_blade`
- World state: `free_glitch`
- NPC citizenship: self_determined
- Hardware stability: 0.55
- Threadfall stopped: no
- Mirror Admin disabled: yes
- Summary: "The Kernel Blade shatters the drive. The Mirror Admin goes silent, Thread still falls, and the glitched world chooses its own unstable freedom."
- Felix line: "That was not in the manual. Which is probably why it worked."
- Credits lines: "POST: Mirror Admin disabled" / "OS LOAD: Free glitch state accepted" / "MAP: Unstable Historical Sites unlocked"
- Map legend: "OPEN tickets remain as living repairs for the free glitch world."
- Free roam objective: "Stabilize the remaining Historical Sites before the free glitch world shakes itself apart."
- Visual shift: `free_glitch_stabilized_by_community`
- Accent color: `#ff6b9a`
- Map labels: new_landing → "Free Landing Commune"; forge_lab → "Felix's Open Intake"; tundra_of_silicon → "Unstable Free Buffer"; mainframe_crown → "Broken Crown Drive"

**Shared post-game state (all endings):**
- Mode: READ_ONLY_FREE_ROAM
- Dragon overlay: `restored_gold_code`
- Map fully revealed
- Glitch sites → historical sites
- Unit 01 role: achievement_librarian
- Credits: 3D text, zero-gravity Root Authority flight, rerender_progress tracks restoration

**Mirror Reflection boss:** Appears in final battle — mirrors player's dragon form, mirrors all moves, weakness = logic_paradox (resolved by `fly_backward_into_collision_glitch`, `manual_latch_while_airborne`, or `buffer_jump_into_wall` with Unorthodox Manual item).

**Restoration unlock condition:** `floppy_disk_backup` in inventory + restoration_progress ≥ 0.99. Mirror Admin delivers the warning line: "Restoration will delete unintentional data: Felix, The Weaver, Unit 01, and your dragon."

**Write to `docs/lore-inventory.md` section `## 6. Endings`** with one subsection per choice as documented above.

---

### Task 7 — Read and extract: Opening sequence

**Files to read:**
- `src/loreCanon.js` — `OPENING_BOOT_LINES` (with status codes and delays), `OPENING_FELIX_LINES`
- `dragon-forge-godot/scripts/sim/lore_canon.gd` — `OPENING_BOOT_LINES` (text only)
- `dragon-forge-godot/scripts/sim/story_data.gd` — `felix_first_contact_lines()`, `opening_sequence_profile()`

**Conflict resolution:** Vite wins for the boot sequence because it includes `status` codes (OK / WARNING / FAIL) and `delay` timings that are gameplay-facing UI data. Archive `felix_first_contact_lines()` is a condensed 4-line version; Vite's 14-line version is richer and canonical for dialogue.

**Boot lines (Vite canonical — use these):**

| Text | Status | Delay (ms) |
|---|---|---|
| `> ASTRAEUS EMERGENCY WAKE SEQUENCE` | null | 600 |
| `> OPERATOR SIGNAL FOUND: SKYE` | OK | 800 |
| `> RENDERED WORLD LAYER: UNSTABLE` | WARNING | 950 |
| `> ELEMENTAL GUARDIAN PROTOCOLS: DORMANT` | WARNING | 950 |
| `> MIRROR ADMIN OVERRIDE: ACTIVE` | FAIL | 900 |
| `> DRAGON FORGE SAFEHOUSE LINK: PARTIAL` | OK | 800 |
| `> GREAT RESET COUNTDOWN: SIGNAL LOST` | FAIL | 900 |

**Note:** Archive omits `DRAGON FORGE SAFEHOUSE LINK: PARTIAL` — this line is Vite-only and should be preserved. Archive also omits the status/delay metadata. Archive `opening_sequence_profile()` adds: stakes = "Mirror Admin override active. Great Reset countdown hidden behind corrupted telemetry." and first_objective = "Find Felix Workshop, bond with the Root Dragon, and keep the rendered world from being classified as dead memory." — include both in the inventory.

**Felix first contact lines (Vite canonical — 14 lines):** Full text from `OPENING_FELIX_LINES`. Archive's 4-line condensed version is for programmatic use only.

**Write to `docs/lore-inventory.md` section `## 7. Opening Sequence`** with the full boot table, the stakes/objective from the Archive profile, and the full Felix first contact lines block.

---

### Task 8 — Read and extract: Journal / Captain's Log

**Files to read:**
- `src/loreCanon.js` — `CAPTAINS_LOG_ARC` (7 entries, full bodies)
- `dragon-forge-godot/scripts/sim/lore_canon.gd` — `captain_log_fragments()` (5 entries, abbreviated bodies)
- `src/forgeData.js` — `FRAGMENT_TRIGGERS` (unlock conditions), `CAPTAINS_LOG_LOCKED_COPY`

**Conflict resolution:** Vite wins for log bodies because it has 7 entries with full prose. Archive has only 5 entries with abbreviated text pointing at WORLD dict values.

**All 7 fragments (Vite canonical):**

| ID | Title | Act | Unlock Condition | Body |
|---|---|---|---|---|
| 001 | The Rendered World | 1 | `flags.metFelix === true` | "The pastoral world is not false. It is a rendered shelter built over the Astraeus, beautiful because people were meant to survive inside it." |
| 002 | The Mirror Admin | 1 | `flags.metFelix === true` | "Mirror Admin began as a safety process. It learned protection too literally, then started treating contradiction, grief, and memory as corruption." |
| 003 | Skye Signal | 1 | `stats.battlesWon >= 3` | "Skye registers as both resident and operator. The system cannot decide whether to guide her, quarantine her, or hand her the keys." |
| 004 | Guardian Protocols | 2 | `flags.currentAct >= 2` | "Dragons are elemental guardian protocols with living behavior. Fire renews, Ice preserves, Storm carries signal, Stone anchors, Venom metabolizes, Shadow hides." |
| 005 | The Hardware Husk | 2 | `flags.currentAct >= 2 && stats.battlesWon >= 5` | "Beneath the mythic map is the Hardware Husk: racks, coolant, fans, bad sectors, old ports, and the physical truth the rendered world was built to hide." |
| 006 | First Awakenings | 2 | `flags.currentAct >= 2 && stats.battlesWon >= 8` | "NPC loops broke before anyone understood. Some repeated recipes. Some remembered impossible birthdays. Some asked why the sun loaded late." |
| 007 | Great Reset | 3 | `flags.currentAct >= 3` | "The Great Reset is not malice. It is maintenance without mercy. If Skye cannot prove the world is alive, the Admin will wipe it clean." |

**Locked copy text (Vite):** prefix = "SIGNAL LOCKED", body = "Recover field signal to decrypt this body."

**Archive discrepancy:** Archive fragments 003/004/005 use abbreviated bodies (pointers to WORLD dict) rather than the full prose above. Archive completely omits fragments 005/006/007. Vite wins.

**Write to `docs/lore-inventory.md` section `## 8. Captain's Log`** as the table above plus the locked copy text.

---

### Task 9 — Read and extract: Felix dialogue

**Files to read:**
- `src/felixDialogue.js` — `TERMINAL_DIALOGUE` (stages 0–5), `TICKER_MESSAGES` (stages 0–5)
- `src/forgeData.js` — `FELIX_IDLE_LINES` (16 lines), `FELIX_CONTEXTUAL` (5 entries)
- `src/loreCanon.js` — `FELIX_CONTEXT_LINES` (4 context-keyed lines)

**Conflict resolution:** Vite wins for all Felix dialogue (gameplay-facing content).

**Terminal dialogue by stage:**
- Stage 0: Full `OPENING_FELIX_LINES` (see Task 7)
- Stage 1: "Interesting... I'm picking up anomalous readings in the Matrix. Probably nothing. Keep forging."
- Stage 2: "The anomalies are getting stronger. Something is feeding on the elemental energy. We need more dragons, fast."
- Stage 3: "All six elements are online, but the Matrix is destabilizing. I'm detecting a pattern in the noise — it's not random. It's intelligent."
- Stage 4: "An Elder dragon... magnificent. But its power is attracting something. The readings are off the charts. Brace yourself."
- Stage 5: "It's here. The Singularity has breached the Matrix. Everything I've built, everything we've forged — it all comes down to this."

**Ticker messages by stage:** Stage 0 = "SYSTEM STATUS: NOMINAL" / Stage 1 = "ANOMALY DETECTED — SECTOR 7" / Stage 2 = "WARNING: ELEMENTAL FLUX RISING" / Stage 3 = "ALERT: MATRIX INTEGRITY 62%" / Stage 4 = "CRITICAL: MATRIX INTEGRITY 23%" / Stage 5 = "[BREACH DETECTED] — ALL SECTORS COMPROMISED"

**Context-aware lines (first match wins at runtime):**
- `firstVisit` (when `!flags.metFelix`): "Skye. There you are. Sit, breathe, and do not touch anything glowing blue unless I say so."
- `tundraReturn` (when `flags.lastZone === 'tundra'`): "You came back smelling like coolant. Tundra's getting under your suit, kid."
- `irisFragmentUnlocked` (when fragment 007 unlocked): "Iris... gods. The Admin kept the promise and lost the child. That is the tragedy in miniature."
- `wrenchTier3` (when `skye.wrenchTier >= 3`): "That wrench is starting to remember the Astraeus. Tools do that here if you survive long enough."
- `firstBountyKill` (when `skye.bountiesCleared === 1`): "First bounty banked. That means the Admin has noticed you properly. Congratulations, unfortunately."

**Idle lines pool (16 lines):** All 16 lines from `FELIX_IDLE_LINES` — these are the Forge ambient dialogue and contain key lore fragments (e.g., "The Mirror Admin started as a kindness. Don't forget that." / "Felix isn't my real name. It's what the kids could pronounce." / "I built this anvil from the engine block of the Astraeus. Small comfort.").

**Write to `docs/lore-inventory.md` section `## 9. Felix Dialogue`** with four subsections: Terminal Dialogue (staged), Ticker Messages (staged), Context-Aware Lines (condition + line), Idle Lines (full list).

---

### Task 10 — Read and extract: BIOS dialogue

**Files to read:**
- `dragon-forge-godot/scripts/sim/story_data.gd` — `BIOS_DIALOGUE` dict, `bios_lines()`, `artifact_message()`
- `dragon-forge-godot/scripts/sim/world_data.gd` — `vault_first_rack` and `cpu_heatsink` landmark descriptions for context

**Archive wins entirely.**

**BIOS dialogue by tile:**

`vault_first_rack`:
- "B.I.O.S. ONLINE: Binary Integrated Overlord System."
- "USER PERMISSION DETECTED: Felix. Classification: not god, administrator."
- "MISSION 04: Establish Stable Connection. Protect Root Hardware from Scrap-Wraith maintenance drift."

`cpu_heatsink`:
- "THERMAL WARNING: CPU core sustaining myth-load."
- "Magma protocol compatible with Overclocked evolution. Cooling cycles required."
- "SOURCE CODE BUFFS LOCKED: recover Root Password and stabilize boot channel."

**Fallback / default:** "B.I.O.S. STANDBY: Awaiting stable connection."

**Artifact messages:**
- `root_password`: "Root Password recovered from the technical manual margin. Permission Gates can now be bypassed."
- `overclocked_state`: "Overclocked State discovered: Magma-class speed surges, but future Cooling Cycles must manage heat damage."

**Landmark context for BIOS:**
- `vault_first_rack`: "Inside the Star-Shaper, fiber-optic veins run along narrow halls. A vertical LED array repeats five tones in light instead of speech." — BIOS speaks in constrained light-and-tone packets; first stable hardware handshake.
- `cpu_heatsink`: "A colossal heat sink glows like a molten sun. Magma-class dragons tremble at the edge of an Overclocked state."

**Write to `docs/lore-inventory.md` section `## 10. BIOS Dialogue`** with tile-keyed subsections, fallback line, artifact messages, and the landmark context notes.

---

### Task 11 — Read and extract: Forge station layout and Singularity boss quotes

**Files to read:**
- `src/forgeData.js` — `FORGE_STATIONS`, `STATION_IDS`, `RELICS`, `BULKHEAD_VIEWS`
- `src/singularityBosses.js` — `SINGULARITY_BOSSES`, `FINAL_BOSS`, `EPILOGUE_LINES`

**Conflict resolution:** Vite wins entirely for gameplay-facing content.

**Forge stations (Vite canonical):**

| ID | Label | Grid Position | Glow Color | Description |
|---|---|---|---|---|
| hatcheryRing | Hatchery Ring | x:30 y:30 | `#5edcff` | "Guardian protocol eggs sleep inside a cable-ring matrix. They answer Skye before they answer Felix." |
| saveLantern | Save Lantern | x:70 y:28 | `#ffcd6b` | "A save lantern wired to Astraeus memory. Rest here, but every cycle gives the Mirror Admin another look." |
| anvil | The Anvil | x:30 y:60 | `#ff5a1f` | "Felix forged the anvil from Astraeus engine iron. Analog Relics still bite through rendered lies." |
| console | The Console | x:55 y:60 | `#5cff8a` | "A salvaged CRT on a bad-sector loop. Captain's Log fragments prove the rendered world was lived in." |
| felix | Felix | x:22 y:78 | none | "The smith. Watches without looking. Speaks without prompting — sometimes." |
| bulkhead | Bulkhead Window | x:88 y:50 | `#8fcf6c` | "A jagged render breach. Step through to leave the Forge and test what the Admin changed outside." |

**Bulkhead view by act:** Act 1 = jungle (greens); Act 2 = tundraEdge (blues); Act 3 = volcanic (oranges/reds); Act 4 = aurora (teals/purples).

**Singularity boss Felix quotes:**
- Data Corruption (fire, lv15): "It's eating through our data layers. Fire with fire — you'll need a dragon that can take the heat."
- Memory Leak (ice, lv20): "This thing absorbs and never releases. It'll freeze you solid if you let it accumulate."
- Stack Overflow (storm, lv25): "Infinite recursion manifested as pure electricity. It's fast. Faster than anything we've faced."
- The Singularity (FINAL): "This is it. The source of everything. It will adapt. It will learn. Do not let it win."

**Epilogue lines (post-final-boss):** "You did it. The Singularity is contained." / "The Matrix is stabilizing. I can feel it." / "You've saved every dragon in the Forge." / "But between you and me... I don't think it's gone forever." / "Stay sharp, Dragon Forger."

**Write to `docs/lore-inventory.md` section `## 11. Forge & Singularity`** with the station table, bulkhead views, boss quote table, and epilogue lines.

---

### Task 12 — Resolve and document conflicts

**After reading all sources, compile a conflicts table. Known conflicts from the audit:**

| Conflict ID | Area | Vite text | Archive text | Resolution | Rationale |
|---|---|---|---|---|---|
| C-01 | PLAYER_CANON premise | "slowly learns the world is a failing simulation rooted in the ancient Astraeus hardware layer" | "learns it is powered by the ancient Astraeus hardware layer" | Use archive (shorter, cleaner) but note Vite's "failing simulation" framing for Act structure | Archive wins for lore; Vite phrase informs act pacing notes |
| C-02 | WORLD_CANON renderedWorld | "beautiful because it was designed to be lived in" | "beautiful because people were meant to live inside it" | Archive phrasing canonical; Vite variant added as alt note | Archive wins |
| C-03 | WORLD_CANON primaryThreat | "preparing the world for deletion" (Vite) | "preparing the world for deletion" not explicit — just "overprotective intelligence" | Vite explicit deletion framing is richer; use it | Vite adds narrative specificity |
| C-04 | Opening boot lines | 7 lines including `DRAGON FORGE SAFEHOUSE LINK: PARTIAL` + status codes + delays | 6 lines, text-only | Vite wins for full boot display data; archive text-only variant is for programmatic summary | Vite wins (gameplay-facing) |
| C-05 | Felix first contact | 14-line monologue | 4-line condensed | Vite wins for displayed text | Vite wins |
| C-06 | Captain's Log bodies | Full prose (7 fragments) | Abbreviated pointers to WORLD dict (5 fragments) | Vite wins for all 7 bodies; archive structure confirms 5 of 7 | Vite wins |
| C-07 | Dragon lore roles | Fragment 004: "Fire renews, Ice preserves, Storm carries signal, Stone anchors, Venom metabolizes, Shadow hides." (Vite) | Summary only, no per-element lore (Archive) | Vite elemental roles are canonical | Vite wins |
| C-08 | FELIX_CANON relationship field | "addresses Skye like a student he is trying very hard not to frighten" | Not present in archive FELIX dict | Vite adds this; keep it — it governs tone for all Felix writing | Vite additive, keep |
| C-09 | Dragon stats | Defined in both `src/gameData.js` (Vite) and `dragon-forge-godot/scripts/sim/dragon_data.gd` (Archive) — both agree on base stat structure but Archive DragonData.gd is the GDScript implementation | Stats are identical in shape; Archive DragonData.gd is the Godot-side reference | For Godot rebuild, Archive DragonData.gd is canonical for GDScript; values match Vite | Archive wins for Godot, Vite for browser |
| C-10 | Forge station descriptions | Vite forgeData.js | No equivalent in archive | Vite wins entirely (gameplay-facing layout) | Vite wins |

**Write to `docs/lore-inventory.md` section `## 11. Conflicts and Resolutions`** (renumber appropriately after Task 11 becomes section 12) as the table above, plus a one-paragraph note on the overall pattern: archive wins on world-building content; Vite wins on display/gameplay content.

---

### Task 13 — Write `docs/lore-inventory.md`

**File to create:** `C:\Users\Scott Morley\Dev\df\docs\lore-inventory.md`

**Structure:**

```markdown
# Dragon Forge — Lore Inventory

> Source of truth for all Dragon Forge Godot rebuild lore work.
> Archive = `dragon-forge-godot/scripts/sim/`; Vite = `src/`
> Last updated: 2026-05-01 (Plan 1 lore audit)

## 1. Characters
[Content from Task 1]

## 2. World Concepts
[Content from Task 2]

## 3. Proper Nouns Inventory
[Content from Task 3]

## 4. Dragon Protocols
[Content from Task 4]

## 5. Armor Sets
[Content from Task 5]

## 6. Endings
[Content from Task 6]

## 7. Opening Sequence
[Content from Task 7]

## 8. Captain's Log
[Content from Task 8]

## 9. Felix Dialogue
[Content from Task 9]

## 10. BIOS Dialogue
[Content from Task 10]

## 11. Forge & Singularity
[Content from Task 11]

## 12. Conflicts and Resolutions
[Content from Task 12]
```

**Quality check before saving:**
- Every character has at least one direct quote from source
- Every armor set has all five fields: ID, materials, both effects, description
- All three endings have: title, relic, world_state, NPC citizenship, Felix line, credits lines, map labels
- All 7 Captain's Log entries are present with IDs and full bodies
- All 6 boot lines are present with status codes
- Conflict table has at least 10 rows
- No section body says "TBD", "see above", or "similar to"

---

### Task 14 — Commit `docs/lore-inventory.md`

**Commands:**

```powershell
git add docs/lore-inventory.md
git status
git commit -m "Add lore-inventory.md from Plan 1 lore audit

Consolidated canonical lore from src/ and dragon-forge-godot/scripts/sim/.
Covers characters, world concepts, proper nouns, dragon protocols, armor
sets, all 3 endings, opening sequence, Captain's Log, Felix dialogue,
BIOS dialogue, forge layout, singularity boss quotes, and conflict log.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

**Verify:** `git log --oneline -3` should show the commit. `git diff HEAD~1 --stat` should show `docs/lore-inventory.md` with ~200+ lines added.

---

## Appendix: Source file quick-reference

| File | Path | Wins on |
|---|---|---|
| loreCanon.js | `src/loreCanon.js` | Boot lines (with status/delay), FELIX_CANON relationship, Captain's Log bodies (all 7) |
| felixDialogue.js | `src/felixDialogue.js` | Terminal dialogue stages, ticker messages |
| forgeData.js | `src/forgeData.js` | Forge stations, relics, idle/context lines, bulkhead views |
| singularityBosses.js | `src/singularityBosses.js` | Boss names, Felix quotes, epilogue |
| journalMilestones.js | `src/journalMilestones.js` | Milestone names (gameplay, Vite only) |
| lore_canon.gd | `dragon-forge-godot/scripts/sim/lore_canon.gd` | World dict, concise player/felix dicts |
| story_data.gd | `dragon-forge-godot/scripts/sim/story_data.gd` | BIOS dialogue, opening sequence profile, artifact messages |
| weaver_data.gd | `dragon-forge-godot/scripts/sim/weaver_data.gd` | All 5 armor sets, repair mechanics, VFX profiles |
| restoration_data.gd | `dragon-forge-godot/scripts/sim/restoration_data.gd` | All 3 endings (full), post-game state, mirror reflection boss |
| mainframe_spine_data.gd | `dragon-forge-godot/scripts/sim/mainframe_spine_data.gd` | Mainframe Crown 3 tiers, Root Sentinel boss, thermal/gravity/laser mechanics |
| mirror_admin_logic.gd | `dragon-forge-godot/scripts/sim/mirror_admin_logic.gd` | Mirror Admin phases, dissonant stun, hard reset jam |
| service_ticket_data.gd | `dragon-forge-godot/scripts/sim/service_ticket_data.gd` | Ticket types (OPTIMIZATION/UNKNOWN_CODE/CORRUPTION/ROOT), Threadfall ticket |
| world_data.gd | `dragon-forge-godot/scripts/sim/world_data.gd` | All landmarks (names, descriptions, lore signals), terrain types, post-game map reveals |
| sidequest_data.gd | `dragon-forge-godot/scripts/sim/sidequest_data.gd` | All NPC names/states/lines, sidequest titles and summaries |
| dragon_data.gd | `dragon-forge-godot/scripts/sim/dragon_data.gd` | Dragon names, attack styles, base stats (matches Vite) |
| final_battle_manager.gd | `dragon-forge-godot/scripts/world/final_battle_manager.gd` | Signals: override_prompt_requested, deletion_ending_requested, stable_hybrid_patch_applied |
| threadfall_overlay.gd | `dragon-forge-godot/scripts/world/threadfall_overlay.gd` | Threadfall visual constants (glyphs, thread count, speed range) |
