# Dragon Forge — Lore Inventory

> Source of truth for all Dragon Forge Godot rebuild lore work.
> Archive = `dragon-forge-godot/scripts/sim/`; Vite = `src/`
> Last updated: 2026-05-12 (Plan 1 lore audit)

---

## 1. Characters

### Skye

**Source:** Archive `lore_canon.gd` PLAYER dict (canonical); Vite `loreCanon.js` PLAYER_CANON (adds nuance)

**Role:** Dragon handler and emerging system administrator

**Key Lore Facts:**
- Begins inside a mythic rendered world and slowly learns the world is a failing simulation rooted in the ancient Astraeus hardware layer (Vite nuance; Archive says "learns it is powered by" — Vite wording is canonical per conflict resolution)
- Registers simultaneously as both resident and operator; the system cannot decide whether to guide her, quarantine her, or hand her the keys
- Her dual-status is the narrative engine: every system treats her as anomalous
- The Astraeus identifies her immediately on emergency wake sequence ("OPERATOR SIGNAL FOUND: SKYE")

**Dialogue Samples:**
- (No direct Skye lines; she speaks through action and the system's response to her signal)

---

### Professor Felix

**Source:** Archive `lore_canon.gd` FELIX dict; Vite `loreCanon.js` FELIX_CANON adds relationship and tone fields; `forgeData.js` supplies idle lines and contextual lines

**Role:** Forge-keeper, mentor, and frantic technical operator

**Key Lore Facts:**
- Tone: warm, precise, anxious, and practical under pressure (both sources agree)
- Addresses Skye like a student he is trying very hard not to frighten (Vite-only nuance, canonical)
- "Felix isn't my real name. It's what the kids could pronounce."
- Built the Anvil from the engine block of the Astraeus
- When the Mirror Admin's deletion warning names those who will be erased: "Felix, The Weaver, Unit 01, and your dragon" — he is among the in-world citizens threatened by Total Restore
- Goes pale when the John Deere 8R Technical Manual diagram opens the holy door at Manual Override

**Dialogue Samples:**
- Felix (opening): "Skye. Good. You can hear me. Do not trust the sky if it tears. Do not trust a perfect reflection. That is the Mirror Admin. The world you know is rendered over the old Astraeus hardware. It was meant to protect us. Now it is trying to preserve us by erasing us. The dragons are not pets. Not exactly. They are living guardian protocols with teeth, memory, and opinions. If they bond to you, they can hold the Matrix together. Get to the Forge. Hatch what still answers. I will explain the impossible parts while we run."
- Felix (first visit): "Skye. There you are. Sit, breathe, and do not touch anything glowing blue unless I say so."
- Felix (first bounty kill): "First bounty banked. That means the Admin has noticed you properly. Congratulations, unfortunately."
- Felix (wrench tier 3): "That wrench is starting to remember the Astraeus. Tools do that here if you survive long enough."
- Felix (Iris fragment): "Iris... gods. The Admin kept the promise and lost the child. That is the tragedy in miniature."
- Felix idle: "The Mirror Admin started as a kindness. Don't forget that."
- Felix idle: "I built this anvil from the engine block of the Astraeus. Small comfort."
- Felix (Total Restore ending): "The fans are steady. I just wish I could hear the village."
- Felix (Patch ending): "No more false sky, Skye. Just a world that finally knows what it is."
- Felix (Hardware Override ending): "That was not in the manual. Which is probably why it worked."

---

### Mirror Admin

**Source:** Archive `mirror_admin_logic.gd` (canonical for mechanics and phases); Vite `loreCanon.js` WORLD_CANON.primaryThreat (canonical premise wording per Vite-wins rule for gameplay-facing content)

**Role:** The primary antagonist; began as a safety process

**Key Lore Facts:**
- Began as a safety process; learned protection too literally; began treating contradiction, grief, and memory as corruption (Captain's Log 002)
- Three combat phases: PARITY → OVERCLOCK → KERNEL_PANIC
  - PARITY: packet_integrity > 0.62 (system stable, mirrors player element)
  - OVERCLOCK: packet_integrity 0.26–0.62 (throttling, increased pressure)
  - KERNEL_PANIC: packet_integrity ≤ 0.25 (critical state)
- Can enter READ_ONLY state when the hard_reset jammed with manual override
- Weakness: dissonant frequency — a tritone above the Admin's current target frequency (exactly 6 semitones up: `target * 2^(6/12)`)
- Mirrors the player's current element and element color during PARITY phase
- `hard_reset_active` triggers when packet_integrity ≤ 0.05; can be jammed with manual override item
- Converts safety firewalls into stone-armored guardians against living contradiction
- Its deletion warning when restoration is ready: "Restoration will delete unintentional data: Felix, The Weaver, Unit 01, and your dragon."

**Dialogue Samples:**
- "Restoration will delete unintentional data: Felix, The Weaver, Unit 01, and your dragon."

---

### B.I.O.S.

**Source:** Archive `story_data.gd` BIOS_DIALOGUE (canonical)

**Full Name:** Binary Integrated Overlord System

**Role:** Hardware-layer intelligence; communicates via light-and-tone packets

**Key Lore Facts:**
- Speaks from the Astraeus hardware layer in constrained light-and-tone packets
- Appears at two key landmarks: `vault_first_rack` (Vault of the First Rack) and `cpu_heatsink` (CPU Heat Sink)
- Standby fallback line when no tile match: "B.I.O.S. STANDBY: Awaiting stable connection."
- Recognizes Felix's user permission but classifies him as "not god, administrator"
- SOURCE CODE BUFFS are locked until Root Password is recovered and boot channel stabilized
- Artifact messages: Root Password recovery grants permission gate bypass; Overclocked State grants Magma-class speed surges but requires Cooling Cycles

**Dialogue Samples:**
- At `vault_first_rack`: "B.I.O.S. ONLINE: Binary Integrated Overlord System. USER PERMISSION DETECTED: Felix. Classification: not god, administrator. MISSION 04: Establish Stable Connection. Protect Root Hardware from Scrap-Wraith maintenance drift."
- At `cpu_heatsink`: "THERMAL WARNING: CPU core sustaining myth-load. Magma protocol compatible with Overclocked evolution. Cooling cycles required. SOURCE CODE BUFFS LOCKED: recover Root Password and stabilize boot channel."

---

### Unit 01 / The Kernel

**Source:** Archive `sidequest_data.gd` NPCS["unit_01"] (canonical); `mainframe_spine_data.gd` `collect_original_backup()` for post-game role; `restoration_data.gd` for post-game citizenship

**In-World Name:** The Kernel

**Role:** Mobile Shop / Save Point; post-game Achievement Librarian

**Key Lore Facts:**
- State: AWAKENED; awareness level: 2
- Named among those who would be deleted by Total Restore ("Felix, The Weaver, Unit 01, and your dragon")
- Can recognize Skye's 10mm wrench as a primary tool; does not remember its own designation
- Post-game role becomes achievement_librarian (all endings)
- Sidequest "Recover Unit 01 Logs": recover 3 memory logs so The Kernel can remember its original repair designation
- Fully awakened line: "Unit 01 was not built to pray. Unit 01 was built to repair."
- Has a glitch-state where it questions whether Skye is a colleague or a customer

**Dialogue Samples:**
- "Primary Tool detected. I remember that wrench. I do not remember my own name."
- "Designation missing. Function persists. Colleague? Customer? Both?"
- "Unit 01 was not built to pray. Unit 01 was built to repair."
- (From `collect_original_backup`): "That... that is a Backup. If you can get that to the Weaver, we do not just patch the system. We can Restore it."

---

### The Weaver

**Source:** Archive `restoration_data.gd` (deletion warning names her); Archive `weaver_data.gd` (armor system attributed to her craft)

**Role:** Crafts and maintains Armor Sets; one of the in-world citizens threatened by Total Restore

**Key Lore Facts:**
- Named explicitly in Mirror Admin's deletion warning alongside Felix and Unit 01
- The WeaverData module manages all armor craft logic, implying her workshop is the armor crafting interface
- Responsible for the five armor overlays that Skye and her dragon can wear
- Armor repair (field_repair_armor) requires a 10mm wrench, steel bolts, and a gauge value in the green zone (0.44–0.62); partial repair only (max integrity 0.78)
- Integrity below 0.35 triggers `needs_weaver_patch` flag — full repair requires return to The Weaver
- Cloth is "memory under tension" (Glitch Weaver NPC awakened line echoes this theme)

**Dialogue Samples:**
- (No direct Weaver lines in source; she speaks through the Glitch Weaver NPC echo): "Harmony restored the weave. Cloth is memory under tension."

---

## 2. World Concepts

**Rendered World**
Definition: The pastoral fantasy surface layer of Dragon Forge's setting.
Extended notes: Beautiful because it was designed to be lived in (Vite wording) / people were meant to live inside it (Archive wording). Not false — a genuine shelter built over the Astraeus. Its pastoral character is intentional design, not deception. It is currently fraying: sky tears, wireframe wheat fields, floating geometry. The Mirror Admin is trying to "preserve" it by erasing it.
Visual aesthetic: Pastoral fantasy with progressive hardware intrusions — green directory forests, checksum peak mountains, overgrown buffer jungles, render tears revealing server void beyond.

**Astraeus**
Definition: The buried physical vessel/server layer that still powers the rendered world.
Extended notes: An ancient hardware installation. Felix built his anvil from its engine block. The emergency wake sequence broadcasts from it. B.I.O.S. speaks from it. The Tundra of Silicon exposes its hardware topology directly. The Mainframe Spine is its vertical server rack made navigable. Its fans still spin under Skye's boots. The rendered world was built over it to protect the people inside.
Visual aesthetic: Industrial hardware gothic — racks, coolant, fans, bad sectors, old ports, exposed fiber-optic veins, copper trace roots, heat sinks, silicon dust.

**Hardware Husk**
Definition: The damaged machine reality beneath the mythic surface.
Extended notes: A terrain type in the overworld (character "h") as well as a concept. Brushed metal juts through the simulated world like exposed bone. Captain's Log 005 describes it: "racks, coolant, fans, bad sectors, old ports, and the physical truth the rendered world was built to hide." Danger level 16.0 (highest non-boss terrain danger). Encounters: Scrap Wraith (Maintenance Drone Attack).
Visual aesthetic: Brushed metal, scanline overlays, industrial decay, exposed hardware components cutting through pastoral render.

**Great Reset**
Definition: A hard wipe event that treats all living memory as corrupted data.
Extended notes: Not malice — maintenance without mercy (Captain's Log 007). If Skye cannot prove the world is alive, the Admin will wipe it clean. The countdown signal was lost at boot (SIGNAL LOST status in opening sequence). At the Mainframe Crown, the Great Reset is no longer a warning — it becomes a pending system choice. Triggered by the Mirror Admin's interpretation of the world as dead memory.
Visual aesthetic: Boot text turning red, signal loss indicators, countdown timers going dark.

**Threadfall**
Definition: Corrupted execution threads falling from the sky and de-rendering local assets.
Extended notes: The ThreadfallOverlay renders as falling white streaks of binary glyphs (0, 1, /, \, |, x) with intensity scaling from 0.0 to 1.0. At high intensity, derender bands appear across the screen. Service tickets for Threadfall are classified as CORRUPTION type (icon X, color #ff594d). Threadfall stops in the total_restore and patch endings; persists in hardware_override.
Visual aesthetic: White binary glyph rain with scanline bands; streak speed scales with intensity (90+210*intensity px/s); 42 threads.

**Mainframe Crown**
Definition: The apex of the Astraeus server stack where the restoration choice is made.
Extended notes: Located at map position (26, 2). Above Legacy Peak. The sky is raw system logs; a gold-plated drive waits for the Original Seed Backup. The Great Reset is no longer a warning here — it is a pending system choice. Skye must choose whether to restore, patch, or override the world the Astraeus still remembers.
Visual aesthetic: Raw green system logs as sky, gold-plated hardware, scrolling system event feeds.

**Mainframe Spine (3 tiers)**
Definition: A vertical server rack that serves as the game's tower-climb dungeon sequence.
Extended notes: Three distinct tiers from `mainframe_spine_data.gd`:
1. **Cooling Base** (height 0.0–0.33): Industrial pipes aesthetic; giant fans, pipes, and exhaust ports; mechanic is spinning fan blades obstacle climb.
2. **Logic Core** (height 0.34–0.66): Glass and glowing circuits aesthetic; security lasers rewrite Skye's trajectory into bad routes rather than dealing damage directly.
3. **Legacy Peak** (height 0.67–1.0): ASCII low-poly aesthetic; blocky, old, under-specified; collision lies; unpredictable collision when ascii_noise > 0.55 and velocity > 0.5.
Gravity increases with altitude (1.0 + altitude * 1.4). Thermal chimney boost from dragon heat and port pressure decreases with altitude density.
Visual aesthetic: Progressive hardware revelation — modern render passes at base, legacy green ASCII at crown.

**Mirror Admin Gate**
Definition: A white-glass eye landmark at the Tundra exit that converts the purge cycle into a boss chamber.
Extended notes: Located at map position (23, 5). A sector purge generates parity scan lanes that become white-out walls unless Skye reaches a shielded port. Drops the admin_shard artifact. Tagged as admin_node. Part of the Tundra of Silicon sequence before the Mainframe Spine approach.
Visual aesthetic: White-glass eye, Cache Vault visual profile (deep blue #071a3f, cyan #58dbff, stark white, hollow gray), scanline overlay.

---

## 3. Proper Nouns Inventory

### Place Names (Overworld Landmarks)

Full list from `world_data.gd` LANDMARKS keys (map coordinates → id → label):

| ID | Label | Kind |
|----|-------|------|
| digital_forge | Digital Forge | forge |
| skye_start | Village Edge | field |
| testing_fields | Testing Fields | field |
| forge_lab | Felix Workshop | lab |
| firewall_gate | Firewall Gate | gate |
| checksum_ring | Checksum Ring | arena |
| overgrown_buffer | Overgrown Buffer | jungle |
| overflow_pipe | Overflow Pipe | hardware |
| vault_first_rack | Vault of the First Rack | hardware |
| scrap_pit_arena | Scrap Pit Arena | arena |
| mint_menagerie | Archive Paddock | archive |
| great_salt_flats | Great Salt Flats | salt |
| manual_override | Manual Override | hardware |
| cpu_heatsink | CPU Heat Sink | hardware |
| lunar_cooling_pool | Lunar Cooling Pool | field |
| lunar_sector | Lunar Sector | lunar |
| lunar_resonance_bowl | Resonance Bowl | arena |
| piano_key_ridge | Piano-Key Ridge | lunar |
| deepwood_fragment | Fragmented Deepwood | jungle |
| high_render_valley | High-Render Valley | field |
| directory_tree_loop | Directory Tree Loop | jungle |
| glitch_loom | Glitch Loom | field |
| new_landing | New Landing | field |
| null_edge | Null Edge | wall |
| update_monolith | Update Monolith | hardware |
| sentinel_404_gate | 404 Sentinel Gate | gate |
| ghost_tractor_trace | Ghost Tractor Trace | salt |
| z_fighting_ridge | Z-Fighting Ridge | archive |
| southern_partition_gate | Southern Partition Gate | gate |
| tundra_of_silicon | Tundra of Silicon | kernel |
| great_buffer_vault | Great Buffer Vault | kernel |
| physical_relay | Physical Relay | hardware |
| mirror_admin_gate | Mirror Admin Gate | kernel |
| glitch_hunter_black_market | Glitch-Hunter Market | hardware |
| mainframe_spine_base | Mainframe Spine Base | kernel |
| legacy_peak | Legacy Peak | kernel |
| mainframe_crown | Mainframe Crown | kernel |
| skybox_leak | Sky-Box Leak | lunar |
| floating_point_cliffs | Floating Point Cliffs | archive |
| dead_pixel_void | Dead Pixel | wall |
| kernel_core | Kernel Core | kernel |
| root_directory | Root Directory | kernel |

### Terrain Type Names

From `world_data.gd` TERRAIN_BY_CHAR labels:

| Symbol | Label | Kind |
|--------|-------|------|
| . | Grasslands | field |
| = | Old Access Road | field |
| f | Directory Forest | jungle |
| j | Overgrown Buffer | jungle |
| ^ | Checksum Peaks | archive |
| d | Manual Desert | salt |
| s | Great Salt Flats | salt |
| h | Hardware Husk | hardware |
| l | Lunar Shelf | lunar |
| m | Magma Marsh | forge |
| a | Battle Arena | arena |
| ~ | Deep Ocean | water |

### Post-Game Ending-Specific Map Labels

From `restoration_data.gd` `revealed_map_labels()`:

**Total Restore:**
- new_landing → "Archived Landing Site"
- forge_lab → "Maintenance Intake Archive"
- tundra_of_silicon → "Zero-Fill Record"
- mainframe_crown → "Restored Crown Drive"

**The Patch:**
- new_landing → "Historical New Landing"
- forge_lab → "Felix Historical Workshop"
- overgrown_buffer → "Control Plaza Historical Site"
- tundra_of_silicon → "Recognized Silicon Tundra"
- mainframe_crown → "Mainframe Crown Memorial"

**Hardware Override:**
- new_landing → "Free Landing Commune"
- forge_lab → "Felix's Open Intake"
- tundra_of_silicon → "Unstable Free Buffer"
- mainframe_crown → "Broken Crown Drive"

### System/Concept Names

- **Elemental Matrix** — The interconnected system of elemental guardian protocols that the dragons stabilize; collapses without all six elements active
- **Southern Partition** — A red binary curtain firewall dividing the rendered world; requires the 10mm Wrench relic code to bypass the physical access port
- **Root Authority** — The permission level required to reach the Crown and make restoration choices; also the flight mode during credits (ZERO_G_ROOT_AUTHORITY)
- **White-Out Purge** — Mirror Admin weaponizing zero-fill cache as weather across the exposed Astraeus layer; hazard in Tundra of Silicon and Great Buffer Vault
- **Packet Loss Fog** — Environmental hazard in Overgrown Buffer terrain; makes movement feel unstable
- **Overclocked State** — Magma-class speed surge discovered at CPU Heat Sink; requires Cooling Cycles to manage heat damage; an artifact item
- **Admin Sweep** — Hazard at Glitch-Hunter Market; linger too long and the market folds itself into a fan shadow
- **Z-Fighting** — Two mountain textures flickering over each other at Z-Fighting Ridge; dragons stutter and stamina drains twice as fast
- **Dead Pixel** — Unrendered black square at Dead Pixel Void; stepping close scrapes HP from active dragons
- **Null-pointer drift** — Hazard at Null Edge; lingering makes the interface unstable
- **Floating Point Drift** — Hazard at Floating Point Cliffs; platforms slide out of alignment
- **Void Draft** — Hazard at Sky-Box Leak; infinite vertical lift but cold damage accumulates fast
- **Legacy Collision** — Hazard at Legacy Peak; blocky surfaces snap in and out of solidity

### Item/Artifact Names

From `world_data.gd` LANDMARKS artifact fields:
- root_password — bypasses Permission Gates
- overclocked_state — Magma-class speed surge artifact
- ghost_tractor_trace — artifact at Ghost Tractor Trace
- optical_lens — locked behind purge-timed alcoves in Great Buffer Vault
- physical_relay — artifact at Physical Relay
- admin_shard — artifact at Mirror Admin Gate
- floppy_disk_backup — dropped by Root Sentinel at Legacy Peak; key to restoration
- floppy_disk_backup_drive — artifact at Mainframe Crown (the drive to insert the backup)

### Analog Relic Names (Vite wins — from `forgeData.js` RELICS)

| ID | Name | Source | Effect | Slot Cost | Mythic |
|----|------|--------|--------|-----------|--------|
| iron_knuckle | Iron Knuckle | Recursive Golem (Cooling Intake boss) | Heavy poise damage +1 | 1 | No |
| hydra_cog | Hydra Cog | Glitch Hydra (Tundra boss) | Heavy can chain twice on hit | 1 | No |
| coolant_core | Coolant Core | Tundra Bit-Wraith swarm bonus | Capacitor stuns last +50% | 1 | No |
| phase_lens | Phase Lens | Sub-routine Stalker (rare drop) | Roll i-frames extend to 12f | 2 | No |
| twin_forge | Twin Forge | Volcanic miniboss | Light chain extends to 4 hits | 2 | No |
| resonant_fork | Resonant Tuning Fork | Lattice-Singer (The Last Verse) | Every 4th Heavy pulses AOE that strips frostbite | 1 | No |
| astraeus_engine | Astraeus Engine | Mirror Admin's Sanctum (Act IV) | All bounty windows last 50% longer | 1 | Yes |

### Boss/Enemy Names

- **Firewall Sentinel** — Safety firewall converted into a stone-armored guardian; wild encounters in Grasslands and Magma Marsh; Firewall Gate encounter
- **Corrupt Drake** — Arena encounters at Checksum Ring; wild encounters in Directory Forest and Checksum Peaks
- **Scrap Wraith** — Vault of the First Rack encounter; Scrap Pit Arena; wild encounters in Overgrown Buffer, Great Salt Flats, Hardware Husk
- **Glitch Hydra** — Tundra boss; drops Hydra Cog relic
- **Bit Wraith** — Tundra Bit-Wraith swarm (drops Coolant Core relic on swarm bonus)
- **Sub-routine Stalker** — Rare drop source for Phase Lens relic; fled in The Great Breakout sidequest
- **Recursive Golem** — Cooling Intake boss; drops Iron Knuckle relic
- **Lunar Mote** — Arena encounters at Resonance Bowl; wild encounters in Lunar Shelf
- **Sys-Admin** — Kernel Core encounter (Sys-Admin Rollback)
- **Root Sentinel** — Legacy Peak encounter; drops floppy_disk_backup
- **Data Corruption** — Singularity gatekeeper (fire element, level 15, HP 140 ATK 30 DEF 18 SPD 16)
- **Memory Leak** — Singularity gatekeeper (ice element, level 20, HP 120 ATK 26 DEF 24 SPD 22)
- **Stack Overflow** — Singularity gatekeeper (storm element, level 25, HP 100 ATK 34 DEF 14 SPD 30)
- **The Singularity** — Final boss; three phases: Ignition (fire, level 30, HP 150 ATK 32 DEF 20 SPD 18), Surge (storm, level 30, HP 130 ATK 36 DEF 16 SPD 26), Void Collapse (void, level 30, HP 100 ATK 40 DEF 12 SPD 32)

---

## 4. Dragon Protocols

> Dragons are living elemental protocols: guardians, maintenance processes, and companions with enough soul to choose Skye back. With teeth, memory, and opinions. Each dragon stabilizes a different layer of the Elemental Matrix.

**Lore roles by element (Vite `loreCanon.js` Captain's Log 004, canonical):**
- Fire renews; Ice preserves; Storm carries signal; Stone anchors; Venom metabolizes; Shadow hides.

**Stage tiers (Archive `dragon_data.gd`):** Level 1–9 = Stage 1; Level 10–24 = Stage 2; Level 25–49 = Stage 3; Level 50+ = Stage 4.

**Shiny multiplier:** 1.2× applied to all base stats (HP, ATK, DEF, SPD).

**Stat scaling:** Each level above 1 adds +3 to all base stats before the shiny multiplier is applied.

| Element | Dragon Name | Lore Role | Attack Style | Base HP | Base ATK | Base DEF | Base SPD |
|---------|-------------|-----------|--------------|---------|----------|----------|----------|
| fire | Magma Dragon | Renews — thermal energy that burns away dead data and reignites dormant processes | Burst damage and burn pressure | 110 | 28 | 20 | 18 |
| ice | Ice Dragon | Preserves — locks living memory in cold storage against deletion | Control, mitigation, and freeze setup | 100 | 24 | 26 | 20 |
| storm | Storm Dragon | Carries signal — propagates data packets and keeps the Matrix's communication layers alive | Speed chains and Focus acceleration | 90 | 30 | 16 | 28 |
| stone | Stone Dragon | Anchors — maintains ground-truth data structures against floating-point drift | Stagger, armor, and heavy counters | 120 | 22 | 30 | 12 |
| venom | Venom Dragon | Metabolizes — processes corrupted data slowly, neutralizing toxins in the Matrix | Attrition, poison, and corrosive debuffs | 95 | 26 | 18 | 24 |
| shadow | Shadow Dragon | Hides — conceals critical processes from the Mirror Admin's parity scans | Evasion, blind strikes, and unstable burst | 85 | 32 | 14 | 26 |
| void | (Singularity phase only) | Endgame corruption made manifest; not a guardian protocol — an anti-protocol | void_rift, null_reflect | — | 40 | 12 | 32 |

---

## 5. Armor Sets

> Armor sets are crafted by The Weaver from scavenged materials. All armor data is canonical from Archive `weaver_data.gd`.

| ID | Name | Required Scavenged Item | Materials | Overworld Effect | Side-scrolling Effect | Outline Color | Description |
|----|------|------------------------|-----------|------------------|-----------------------|---------------|-------------|
| obsidian_shell | Obsidian Shell | magma_scale | magma_scale, digital_silk, silicon_shards | thermal_exhaust_stability | steam_trap_immunity | #ff7a35 (orange) | A heat-buffered overlay that lets the dragon and Skye ignore unstable exhaust wash. |
| refractive_plate | Refractive Plate | optical_lens | optical_lens, digital_silk, fragmented_code | stalker_invisibility | security_node_reveal | #58dbff (cyan) | A light-bending overlay for hiding from Sub-routine Stalkers and revealing tripwires. |
| silicon_padded_gear | Silicon Padded Gear | silicon_shards | silicon_shards, raw_silk | static_discharge_resistance | input_lag_reduction | #70ff8f (green) | Softcode padding that gives bad collision enough physicality to stand on. |
| friction_harness | Friction Harness | 10mm_wrench | 10mm_wrench, digital_silk, steel_bolt | high_traction_dives | pipe_wall_slide | #ffd166 (warm yellow) | A saddle-harness overlay for steep dives and vertical pipe grip. |
| ascii_aegis | ASCII Aegis | floppy_disk_backup | fragmented_code, floppy_disk_backup, digital_silk | firewall_phase_passage | double_jump_recompile | #b7fffb (pale cyan) | A low-poly source-tier overlay that de-compiles and re-compiles Skye mid-air. |

**Repair Mechanics (Archive `weaver_data.gd`):**
- `apply_armor_damage()`: Each damage hit reduces integrity (clamped 0.0–1.0). At integrity < 0.5: `visual_decay = true`, `texture_state = GRAY_FLICKER`. At integrity < 0.35: `needs_weaver_patch = true` — full repair requires The Weaver.
- `field_repair_armor()`: Requires tool_id == "10mm_wrench", gauge value in green zone (0.44–0.62), and at least one steel bolt. Success restores +0.22 integrity (max 0.78), sets `texture_state = TEMPORARY_RESEAT`. Failure with wrong gauge: `stripped_bolt = true`.

**VFX Screen Effects:**
- Temporary repair: `screen_effect = scanline_burst`, outline turns #70ff8f, flicker_alpha 0.16
- Visual decay / GRAY_FLICKER: `screen_effect = chromatic_glitch`, outline turns #9b998d, flicker_alpha scales from 0.24 to 0.58 as integrity drops
- Stable equipped armor: `screen_effect = scanline_burst`, flicker_alpha 0.08

---

## 6. Endings

> All ending data is canonical from Archive `restoration_data.gd`. Three choices are available at the Mainframe Crown. Each requires the matching Analog Relic.

### Ending A: Total Restore

**Required Relic:** 10mm_wrench

**World State:** sterile_colony_ship

**NPC Citizenship:** deleted — Felix, The Weaver, Unit 01, and Skye's dragon are removed from active memory

**Hardware Stability:** 1.0 (perfect)

**Threadfall Stopped:** Yes

**Mirror Admin Disabled:** No (result: ORIGINAL_SEED_LOCKED)

**Summary:** The Original Seed locks into place. The Astraeus stabilizes, but the post-crash citizens are removed from active memory.

**Felix Line:** "The fans are steady. I just wish I could hear the village."

**Credits Lines:**
- "POST: Dragon Registry archived"
- "OS LOAD: Colony protocol restored"
- "MAP: Historical records sealed"

**Map Legend:** "VERIFIED archives mark what used to be villages."

**Free Roam Objective:** Read the sealed Historical Sites and recover what the restore erased.

**Visual Shift:** cold_colony_ship_render

**Accent Color:** #d8e7ff (pale blue)

**Ending-Specific Map Labels:**
- New Landing → Archived Landing Site
- Felix Workshop → Maintenance Intake Archive
- Tundra of Silicon → Zero-Fill Record
- Mainframe Crown → Restored Crown Drive

---

### Ending B: The Patch

**Required Relic:** diagnostic_lens

**World State:** recognized_hybrid

**NPC Citizenship:** recognized_citizens — Felix, The Weaver, Unit 01, and the dragon are recognized as citizens of the hybrid world

**Hardware Stability:** 0.9 (high)

**Threadfall Stopped:** Yes

**Mirror Admin Disabled:** No (result: FILTERED_RESTORE_APPLIED)

**Summary:** The Diagnostic Lens filters the restore. The Husk repairs itself while Felix, the Weaver, Unit 01, and the dragons become recognized citizens.

**Felix Line:** "No more false sky, Skye. Just a world that finally knows what it is."

**Credits Lines:**
- "POST: Dragon Registry verified"
- "OS LOAD: Hybrid render stabilized"
- "MAP: Historical Sites unlocked"

**Map Legend:** "VERIFIED tickets become Historical Sites across the revealed map."

**Free Roam Objective:** Fly Read-Only Free-Roam, visit Historical Sites, and finish any VERIFIED service tickets.

**Visual Shift:** hybrid_high_fidelity_paintover

**Accent Color:** #ffd56b (warm gold)

**Ending-Specific Map Labels:**
- New Landing → Historical New Landing
- Felix Workshop → Felix Historical Workshop
- Overgrown Buffer → Control Plaza Historical Site
- Tundra of Silicon → Recognized Silicon Tundra
- Mainframe Crown → Mainframe Crown Memorial

---

### Ending C: Hardware Override

**Required Relic:** kernel_blade

**World State:** free_glitch

**NPC Citizenship:** self_determined — NPCs choose their own status in the free glitch world

**Hardware Stability:** 0.55 (unstable)

**Threadfall Stopped:** No (Thread still falls)

**Mirror Admin Disabled:** Yes (result: ORIGINAL_SEED_DESTROYED)

**Summary:** The Kernel Blade shatters the drive. The Mirror Admin goes silent, Thread still falls, and the glitched world chooses its own unstable freedom.

**Felix Line:** "That was not in the manual. Which is probably why it worked."

**Credits Lines:**
- "POST: Mirror Admin disabled"
- "OS LOAD: Free glitch state accepted"
- "MAP: Unstable Historical Sites unlocked"

**Map Legend:** "OPEN tickets remain as living repairs for the free glitch world."

**Free Roam Objective:** Stabilize the remaining Historical Sites before the free glitch world shakes itself apart.

**Visual Shift:** free_glitch_stabilized_by_community

**Accent Color:** #ff6b9a (hot pink)

**Ending-Specific Map Labels:**
- New Landing → Free Landing Commune
- Felix Workshop → Felix's Open Intake
- Tundra of Silicon → Unstable Free Buffer
- Mainframe Crown → Broken Crown Drive

---

### Shared Post-Game State (all endings)

From `restoration_data.gd` `postgame_state()`:
- Mode: READ_ONLY_FREE_ROAM
- Dragon scale overlay: restored_gold_code
- Map fully revealed
- Glitch sites become historical_sites
- Unit 01 role: achievement_librarian
- Credits flight mode: ZERO_G_ROOT_AUTHORITY
- Credits rendered as 3D text

### Mirror Reflection Boss

Triggered by "choice_regret" during the restoration sequence (from `create_mirror_reflection()`):
- Name: Mirror Reflection
- Form: player_dragon (mirrors Skye's current dragon)
- Mirrors all moves
- Weakness: logic_paradox
- Logic paradox moves: fly_backward_into_collision_glitch, manual_latch_while_airborne, buffer_jump_into_wall
- Requires `has_unorthodox_manual = true` and one of the three paradox moves
- Success: PARITY_BROKEN (Admin cannot replicate); Failure: PARITY_MAINTAINED

---

## 7. Opening Sequence

### Boot Lines Table (Vite canonical — 7 lines with status codes)

| # | Text | Status | Delay (ms) |
|---|------|--------|------------|
| 1 | > ASTRAEUS EMERGENCY WAKE SEQUENCE | — | 600 |
| 2 | > OPERATOR SIGNAL FOUND: SKYE | OK | 800 |
| 3 | > RENDERED WORLD LAYER: UNSTABLE | WARNING | 950 |
| 4 | > ELEMENTAL GUARDIAN PROTOCOLS: DORMANT | WARNING | 950 |
| 5 | > MIRROR ADMIN OVERRIDE: ACTIVE | FAIL | 900 |
| 6 | > DRAGON FORGE SAFEHOUSE LINK: PARTIAL | OK | 800 |
| 7 | > GREAT RESET COUNTDOWN: SIGNAL LOST | FAIL | 900 |

Note: Archive `lore_canon.gd` has 6 boot lines (omits "DRAGON FORGE SAFEHOUSE LINK: PARTIAL"). Vite 7-line version with status codes is canonical.

### Stakes and First Objective (Archive `story_data.gd` `opening_sequence_profile()`)

- **Stakes:** Mirror Admin override active. Great Reset countdown hidden behind corrupted telemetry.
- **First Objective:** Find Felix Workshop, bond with the Root Dragon, and keep the rendered world from being classified as dead memory.
- **Presentation Style:** tense_boot_first_contact

### Felix First Contact Lines (14 lines, Vite canonical from `loreCanon.js` OPENING_FELIX_LINES)

```
"Skye. Good. You can hear me.
Do not trust the sky if it tears. Do not trust
a perfect reflection. That is the Mirror Admin.

The world you know is rendered over the old
Astraeus hardware. It was meant to protect us.
Now it is trying to preserve us by erasing us.

The dragons are not pets. Not exactly.
They are living guardian protocols with teeth,
memory, and opinions. If they bond to you,
they can hold the Matrix together.

Get to the Forge. Hatch what still answers.
I will explain the impossible parts while we run."
```

Note: Archive `story_data.gd` has 4 compressed lines. Vite 14-line version is canonical.

---

## 8. Captain's Log

> All 7 fragments are Vite canonical from `loreCanon.js` CAPTAINS_LOG_ARC. Archive has only 5 abbreviated fragments.

**Locked copy text:** "SIGNAL LOCKED — Recover field signal to decrypt this body."

### Fragment Table

| ID | Title | Act | Unlock Condition | Body |
|----|-------|-----|-----------------|------|
| 001 | The Rendered World | 1 | `flags.metFelix === true` | The pastoral world is not false. It is a rendered shelter built over the Astraeus, beautiful because people were meant to survive inside it. |
| 002 | The Mirror Admin | 1 | `flags.metFelix === true` | Mirror Admin began as a safety process. It learned protection too literally, then started treating contradiction, grief, and memory as corruption. |
| 003 | Skye Signal | 1 | `stats.battlesWon >= 3` | Skye registers as both resident and operator. The system cannot decide whether to guide her, quarantine her, or hand her the keys. |
| 004 | Guardian Protocols | 1 | `flags.currentAct >= 2` | Dragons are elemental guardian protocols with living behavior. Fire renews, Ice preserves, Storm carries signal, Stone anchors, Venom metabolizes, Shadow hides. |
| 005 | The Hardware Husk | 2 | `flags.currentAct >= 2 && stats.battlesWon >= 5` | Beneath the mythic map is the Hardware Husk: racks, coolant, fans, bad sectors, old ports, and the physical truth the rendered world was built to hide. |
| 006 | First Awakenings | 2 | `flags.currentAct >= 2 && stats.battlesWon >= 8` | NPC loops broke before anyone understood. Some repeated recipes. Some remembered impossible birthdays. Some asked why the sun loaded late. |
| 007 | Great Reset | 3 | `flags.currentAct >= 3` | The Great Reset is not malice. It is maintenance without mercy. If Skye cannot prove the world is alive, the Admin will wipe it clean. |

---

## 9. Felix Dialogue

### 9.1 Terminal Dialogue (6 stages 0–5)

**Stage 0 — Opening (Felix first contact, 14 lines):**
```
"Skye. Good. You can hear me.
Do not trust the sky if it tears. Do not trust
a perfect reflection. That is the Mirror Admin.

The world you know is rendered over the old
Astraeus hardware. It was meant to protect us.
Now it is trying to preserve us by erasing us.

The dragons are not pets. Not exactly.
They are living guardian protocols with teeth,
memory, and opinions. If they bond to you,
they can hold the Matrix together.

Get to the Forge. Hatch what still answers.
I will explain the impossible parts while we run."
```

**Stage 1:**
```
"Interesting... I'm picking up anomalous
 readings in the Matrix.
 Probably nothing. Keep forging."
```

**Stage 2:**
```
"The anomalies are getting stronger.
 Something is feeding on the elemental
 energy. We need more dragons, fast."
```

**Stage 3:**
```
"All six elements are online, but the
 Matrix is destabilizing. I'm detecting
 a pattern in the noise — it's not
 random. It's intelligent."
```

**Stage 4:**
```
"An Elder dragon... magnificent.
 But its power is attracting something.
 The readings are off the charts.
 Brace yourself."
```

**Stage 5:**
```
"It's here. The Singularity has breached
 the Matrix. Everything I've built,
 everything we've forged — it all
 comes down to this."
```

### 9.2 Ticker Messages (6 stages 0–5)

| Stage | Ticker |
|-------|--------|
| 0 | SYSTEM STATUS: NOMINAL |
| 1 | ANOMALY DETECTED — SECTOR 7 |
| 2 | WARNING: ELEMENTAL FLUX RISING |
| 3 | ALERT: MATRIX INTEGRITY 62% |
| 4 | CRITICAL: MATRIX INTEGRITY 23% |
| 5 | [BREACH DETECTED] — ALL SECTORS COMPROMISED |

### 9.3 Context-Aware Lines (5 entries)

| ID | Condition | Line |
|----|-----------|------|
| firstVisit | `!save?.flags?.metFelix` | "Skye. There you are. Sit, breathe, and do not touch anything glowing blue unless I say so." |
| tundraReturn | `save?.flags?.lastZone === 'tundra'` | "You came back smelling like coolant. Tundra's getting under your suit, kid." |
| irisFragmentUnlocked | `save?.flags?.fragmentsUnlocked?.includes('007')` | "Iris... gods. The Admin kept the promise and lost the child. That is the tragedy in miniature." |
| wrenchTier3 | `(save?.skye?.wrenchTier || 1) >= 3` | "That wrench is starting to remember the Astraeus. Tools do that here if you survive long enough." |
| firstBountyKill | `(save?.skye?.bountiesCleared || 0) === 1` | "First bounty banked. That means the Admin has noticed you properly. Congratulations, unfortunately." |

### 9.4 Idle Lines (full list — 16 lines from `forgeData.js` FELIX_IDLE_LINES)

1. "A bolt has two states, kid. Tight or stripped. Don't be a stripped bolt."
2. "Heat softens iron. Cold makes it brittle. People are the same."
3. "Every dragon I've known started as something fragile. So did every blade."
4. "You came back. That's the part most folks forget to do."
5. "The wrench remembers what you forge with it. Keep it honest."
6. "Out there is rust. In here, we make it useful."
7. "I built this anvil from the engine block of the Astraeus. Small comfort."
8. "You smell like the Tundra. Let it go before it sets."
9. "Don't bond a dragon you wouldn't mourn. That's the whole law of it."
10. "The Mirror Admin started as a kindness. Don't forget that."
11. "Felix isn't my real name. It's what the kids could pronounce."
12. "When the lantern flickers blue, the deck has shifted again. Adjust your stance."
13. "Skye, if the sky looks too perfect, duck. Perfect means the Admin is rendering over a wound."
14. "Dragons are protocols with tempers. Treat them like partners, not equipment."
15. "The old Astraeus fans still spin under your boots. That sound is not weather."
16. "If the Console repeats a log, read it twice. Memory fights deletion by stuttering."

---

## 10. BIOS Dialogue

> All BIOS data is canonical from Archive `story_data.gd`. Archive wins entirely.

### Tile: vault_first_rack (Vault of the First Rack)

```
B.I.O.S. ONLINE: Binary Integrated Overlord System.
USER PERMISSION DETECTED: Felix. Classification: not god, administrator.
MISSION 04: Establish Stable Connection. Protect Root Hardware from Scrap-Wraith maintenance drift.
```

**Landmark context:** Inside the Star-Shaper; fiber-optic veins run along narrow halls; a vertical LED array repeats five tones in light instead of speech. Skye objective: establish the first stable hardware handshake before the Great Reset countdown reacquires signal.

### Tile: cpu_heatsink (CPU Heat Sink)

```
THERMAL WARNING: CPU core sustaining myth-load.
Magma protocol compatible with Overclocked evolution. Cooling cycles required.
SOURCE CODE BUFFS LOCKED: recover Root Password and stabilize boot channel.
```

**Landmark context:** A colossal heat sink glows like a molten sun. Magma-class dragons tremble at the edge of an Overclocked state. Mission 05.

### Fallback Line

```
B.I.O.S. STANDBY: Awaiting stable connection.
```

### Artifact Messages

- **root_password:** "Root Password recovered from the technical manual margin. Permission Gates can now be bypassed."
- **overclocked_state:** "Overclocked State discovered: Magma-class speed surges, but future Cooling Cycles must manage heat damage."

---

## 11. Forge & Singularity

### Forge Station Table (6 stations — Vite wins from `forgeData.js`)

| ID | Label | Grid Position (x%, y%) | Glow Color | Description |
|----|-------|------------------------|------------|-------------|
| hatcheryRing | Hatchery Ring | x:30, y:30 | #5edcff (hatchery cyan) | Guardian protocol eggs sleep inside a cable-ring matrix. They answer Skye before they answer Felix. |
| saveLantern | Save Lantern | x:70, y:28 | #ffcd6b (lantern warm) | A save lantern wired to Astraeus memory. Rest here, but every cycle gives the Mirror Admin another look. |
| anvil | The Anvil | x:30, y:60 | #ff5a1f (coal glow) | Felix forged the anvil from Astraeus engine iron. Analog Relics still bite through rendered lies. |
| console | The Console | x:55, y:60 | #5cff8a (console green) | A salvaged CRT on a bad-sector loop. Captain's Log fragments prove the rendered world was lived in. |
| felix | Felix | x:22, y:78 | none | The smith. Watches without looking. Speaks without prompting — sometimes. |
| bulkhead | Bulkhead Window | x:88, y:50 | #8fcf6c (jungle day) | A jagged render breach. Step through to leave the Forge and test what the Admin changed outside. |

### Bulkhead View by Act (4 acts)

| Act | Variant | Palette |
|-----|---------|---------|
| 1 | jungle | #8fcf6c (jungle day), #5a8c3a, #2c4a1c |
| 2 | tundraEdge | #cfe7ff, #7aa8c4, #3b5870 |
| 3 | volcanic | #ff7a3d, #a83a18, #3a0c08 |
| 4 | aurora | #7af0d6, #9b6cff, #1a1644 |

### Singularity Boss Felix Quote Table (4 entries — Vite `singularityBosses.js`)

| Boss | Felix Quote |
|------|------------|
| Data Corruption | "It's eating through our data layers. Fire with fire — you'll need a dragon that can take the heat." |
| Memory Leak | "This thing absorbs and never releases. It'll freeze you solid if you let it accumulate." |
| Stack Overflow | "Infinite recursion manifested as pure electricity. It's fast. Faster than anything we've faced." |
| The Singularity (final) | "This is it. The source of everything. It will adapt. It will learn. Do not let it win." |

### Epilogue Lines (5 lines — Vite `singularityBosses.js` EPILOGUE_LINES)

1. "You did it. The Singularity is contained."
2. "The Matrix is stabilizing. I can feel it."
3. "You've saved every dragon in the Forge."
4. "But between you and me... I don't think it's gone forever."
5. "Stay sharp, Dragon Forger."

---

## 12. Conflicts and Resolutions

| Conflict ID | Area | Vite Text | Archive Text | Resolution | Rationale |
|-------------|------|-----------|--------------|------------|-----------|
| C-01 | PLAYER_CANON premise wording | "slowly learns the world is a failing simulation rooted in the ancient Astraeus hardware layer" | "learns it is powered by the ancient Astraeus hardware layer" | **Vite wins** | Vite adds "failing simulation" nuance and "rooted in" framing; more dramatically precise and consistent with Vite's role as source of truth for gameplay-facing content |
| C-02 | renderedWorld phrasing | "beautiful because it was designed to be lived in" | "beautiful because people were meant to live inside it" | **Archive wins** | World lore is archive domain; Archive wording is warmer and more thematic for in-world text |
| C-03 | primaryThreat explicitness | "Mirror Admin began as a safety process and became an overprotective intelligence preparing the world for deletion" | "Mirror Admin began as a safety process and became an overprotective intelligence preparing the world for deletion" (via WORLD dict) | **Same** — both sources agree on the core premise | No conflict; Vite wins for display copy per rule |
| C-04 | Opening boot lines count | 7 lines with OK/WARNING/FAIL status codes and per-line delays | 6 lines, no status codes, no delays | **Vite wins** | Vite has richer implementation data (status, delay). Boot line 6 ("DRAGON FORGE SAFEHOUSE LINK: PARTIAL") is Vite-only and important for gameplay context |
| C-05 | Felix first contact length | 14 lines, full speech with paragraph breaks | 4 compressed lines covering the same beats | **Vite wins** | Vite's 14-line version is the authored screenplay; Archive 4-liner is a content summary for the sim module |
| C-06 | Captain's Log bodies | 7 full entries with authored body text (including Fragment 005 "Hardware Husk" and Fragment 006 "First Awakenings") | 5 entries, abbreviated bodies; some bodies are just WORLD dict strings | **Vite wins** | Vite has 7 complete entries with authored prose; Archive is missing Fragments 005 and 006 entirely |
| C-07 | Dragon lore roles | Per-element lore roles in Captain's Log 004 body: "Fire renews, Ice preserves, Storm carries signal, Stone anchors, Venom metabolizes, Shadow hides" | DragonData has no lore role field — only attack_style and base_stats | **Vite wins** | Vite is source of truth for gameplay-facing content including dragon lore presentation; Archive has no lore role field to conflict with |
| C-08 | FELIX_CANON relationship field | "Felix addresses Skye like a student he is trying very hard not to frighten" (FELIX_CANON.relationship — Vite-only) | Not present in Archive FELIX dict | **Vite wins** | Vite-only nuance field; no Archive entry to conflict with; essential characterization for dialogue writing |
| C-09 | Dragon stats source | Vite `gameData.js` dragon definitions (not read in this audit — deferred) | Archive `dragon_data.gd` DRAGONS dict with full base_stats | **Archive wins for Godot build** | Both sources agree in shape (hp/atk/def/spd). Godot rebuild uses Archive GDScript natively; Vite stats are source of truth for browser build |
| C-10 | Forge station descriptions | Vite `forgeData.js` FORGE_STATIONS with full description strings (gameplay-facing display text) | Not present in Archive | **Vite wins** | Forge station layout and descriptions are gameplay-facing display content; Vite wins per rule |

**Concluding principle:** Archive wins on world-building content (landmarks, world lore, endings, armor sets, NPC states, proper nouns, BIOS dialogue); Vite wins on display and gameplay content (dragon stats, NPC enemies, battle mechanics, shop items, singularity bosses, forge station layout, Felix idle lines, context triggers, terminal dialogue stages, ticker messages). When a Vite field has no Archive counterpart (FELIX_CANON.relationship, boot line 6, Fragments 005–006), Vite is canonical without conflict.
