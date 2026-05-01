# Dragon Forge Project Memory

Last updated: 2026-04-30

## North Star

Dragon Forge is a 2D dragon-raising RPG with a high-angle RPG/flight overworld and side-scrolling Hardware Dungeons. The overworld is the Pastoral Render; the dungeons are the physical Astraeus hardware layer.

Player fantasy: Skye begins as a dragon handler in a fantasy world, discovers the world is a failing simulation rooted in an ancient physical server rack, and grows into the system administrator who repairs it.

## Core Tone

- Early game: fantasy adventure, dragon training, strange corruption.
- Mid-game: Hardware Husk revelation, B.I.O.S., light-and-sound handshake, dragons as sentient protocols.
- Third act: system administration, re-rendering broken regions, defragmentation, keep-alive pings, Kernel Core permissions.
- Endgame: solo administration, resource ethics, Security Daemons, and the burden of being the system's last chance.
- Sidequests are system maintenance disguised as folklore: static NPC loops, memory leaks, ghost wells, unauthorized manual pages, missing textures, and asset recovery.
- Felix evolves from magical mentor into frantic technical operator.
- B.I.O.S. should feel ancient, constrained, literal, and visually distinct.
- NPC awakening should be gradual: first loops break, then NPCs remember contradictions, then late-game awakened "Harpers" can help Skye administer the world.
- The Great Reset is the long threat: the world is scheduled for a hard drive wipe, and repairing sectors makes the current world too large and too alive to delete.

## Current Implemented Spine

- Godot project lives at `C:/Users/Scott Morley/Dev/DF/dragon-forge-godot`.
- Run with `.\run-godot.ps1`.
- Simulation smoke test: `res://scripts/tests/sim_smoke.gd`.
- Real tile overworld with camera-follow map, landmarks, objectives, dangerous terrain, and arena markers.
- Animated battle scene with player dragon sprite-sheet frame extraction, enemy motion, VFX strips, float text, screen shake, arena rules, and intent counterplay.
- Battle systems include Focus, enemy intent, technique roles, stagger, counter reads, XP, DataScraps, level progression, and victory rewards.
- Dragons have per-dragon learned techniques and per-dragon loadouts.
- Diagnostic Lens records enemy seen/defeated counts.
- Save/load stores world position, profile, mission state, danger state, pending wild encounters, and admin overlay state.
- Sidequest/NPC registry exists in `res://scripts/sim/sidequest_data.gd`.
- New Landing, Archive Paddock, Overgrown Buffer, Great Salt Flats, and Null Edge host early NPC/sidequest threads.
- NPC awareness levels are now explicit: puppet, glitched, awakened.

## Story / Mission State

Detailed encounter handoffs:

- Mirror Admin encounter: `docs/mirror-admin-encounter.md`.
- Physicality Protocol endgame: `docs/physicality-protocol-endgame.md`.
- Layered SFX audio schema: `docs/sfx-layered-audio-schema.md`.
- Threads global event: `docs/threads-global-event.md`.
- Visual layer systems: `docs/visual-layer-systems.md`.
- Southern Partition build spec: `docs/southern-partition-build-spec.md`.
- Boot sequence and recursive dungeons: `docs/boot-sequence-recursive-dungeons.md`.
- Final crafting tier: `docs/final-crafting-source-code-relics.md`.
- Diagnostic map circuit-board layer: `docs/diagnostic-map-circuit-board.md`.
- Map system monitor and POI alerts: `docs/map-system-monitor-poi.md`.
- Navigation and service-ticket UI: `docs/navigation-service-ticket-ui.md`.
- Resource ticket and inventory foundation: `docs/resource-ticket-inventory-foundation.md`.
- Dragon flight aero-traction: `docs/dragon-flight-aero-traction.md`.
- Mirror Admin boss logic: `docs/mirror-admin-boss-logic.md`.
- System-switching shaders: `docs/system-switching-shaders.md`.
- Victory patch state: `docs/victory-patch-state.md`.
- Act I Great Breakout: `docs/act-one-great-breakout.md`.
- Act II Tundra and Mainframe Spine: `docs/act-two-tundra-mainframe-spine.md`.
- Mainframe Spine vertical ascent: `docs/mainframe-spine-vertical-ascent.md`.
- Act III Restoration: `docs/act-three-restoration.md`.
- DragonVault hidden gallery: `docs/dragonvault-hidden-gallery.md`.
- Dual-layer overworld and hardware dungeons: `docs/dual-layer-overworld-hardware-dungeons.md`.
- Playable Act I slice: `docs/playable-act-one-slice.md`.
- Playable Act II onboarding: `docs/playable-act-two-onboarding.md`.
- Playable Mainframe and Restoration route: `docs/playable-mainframe-restoration-route.md`.

Implemented mission arc:

- Mission 05: Great Heat Sync, thermal precision.
- Mission 06: Mint-Condition Menagerie, grading scanner.
- Mission 07: Long-Range Relay, kinetic recovery.
- Mission 08: Lunar Echo, frequency matching.
- Mission 09: First Handshake, luma-tone sequence.
- Mission 10: Defragmenting the Deepwood, logic tethers.
- Mission 11: Garbage Collector's Cull, keep-alive pings.
- Mission 12: Kernel Breach, permission nodes and Security Daemon upload.

Act I finale:

- Kernel Recovery combines the Weaver rescue with the Evolution Hunt.
- The Root Dragon is forced into Magma-Core by absorbing a High-Density Heat Core while saving the Weaver from a zero-clock rendering loop.
- Felix's Cooling Intake workshop becomes the base of operations: smithy plus server room, green safe-zone marker, analog relic scanner, and steady 60Hz Power Core.
- The Southern Partition is the Jungle of Cables. Vines are heavy-duty data cables that leak blue coolant when cut.
- The Overflow Pipe is a hot steam jump pad for the Root/Magma dragon.
- Mirror Admin reacts to Magma-Core compilation by dispatching Sub-routine Stalker Bounty Hunters: translucent wireframe Ghost Dragons with Latency rather than HP.
- Bounty Hunters can only be struck during brief stabilization windows; contact leeches specialized compile data and can eventually revert the dragon toward Root form.
- The Weaver's System Tailoring upgrades analog relics into system gear. First key item is the Friction Saddle, crafted from Digital Silk, Steel Bolt, and the 10mm Wrench.
- The Southern Partition Gate is a red binary firewall curtain that de-rezzes direct contact. It is bypassed through a rusted physical access port using the 10mm Wrench.
- Physical Override opens the gate permanently because Mirror Admin cannot repair an analog breach.
- The first-act reveal beyond the gate is the Tundra of Silicon, a whiteout desert beneath the Mainframe Spine.

Act II transition:

- The Tundra of Silicon is a Frozen Buffer / Zero-Fill zone where the Admin clears cache and weaponizes the exposed machine layer.
- The environment is a crystalline silicon whiteout with flat heat-sink plates and low vibration instead of jungle data-drafts.
- White-Out Purge periodically washes the screen nearly white and wipes dragon textures unless Skye hides behind Physical Relays.
- Magma-Core flight becomes self-thrust: lift comes from internal heat rather than external data-drafts, costing energy.
- Unit 01, called The Kernel, is a physical Astraeus repair robot with rusted analog plating and a holographic face. It acts as a mobile shop, save point, upgrade station, and memory-log quest giver.
- Unit 01 remembers the Original Crew as colleagues, not gods, but has forgotten its original designation.
- Kernel upgrades include Insulated Grip for the 10mm Wrench and Frequency Tuner for the Diagnostic Lens.
- The Mainframe Spine is the mountain revealed as a vertical server rack. Act II should focus on vertical flight up the structure.
- Mainframe code ages with height: base is 4K/modern, middle is 16-bit legacy, peak is raw ASCII.
- Prism-Stalk mutation route requires Optical Lens and Tundra data-light exposure. Prism-Stalk can hide from Admin sensors and refract White-Out Purge into beam charge.

Mainframe Spine vertical ascent:

- The Spine is a platformer-flight hybrid, not a normal overworld section.
- Skye climbs by leapfrogging between Thermal Chimneys / Exhaust Ports.
- Exhaust Ports provide boost but require heat/pressure management; overheated Magma-Core flight may require venting.
- Mirror Admin increases local gravity around the tower. Lost momentum causes a hard drop back toward the Tundra.
- Tier 01 Cooling Base is industrial pipes and spinning fan blades.
- Tier 02 Logic Core is glass/circuit architecture with laser grids that reroute flight paths.
- Tier 03 Legacy Peak is ASCII/low-poly and has unpredictable collision.
- Vertical camera must lead upward, pull back at speed, and preserve scale with large non-collidable wireframe structures.
- Root Sentinel is the ASCII boss at the top, a green text entity and original Mirror Admin form.
- Root Sentinel phases include Syntax Rain, De-compilation inventory comment-out, and Closing Bracket weak point.
- De-compilation can disable key gear such as the 10mm Wrench or Diagnostic Lens for 10 seconds.
- The weak point is a closing bracket `}` on the Sentinel's back, melted by Magma-Core heat.
- Reward is a physical Floppy Disk Backup, unlocking Act III Restoration possibilities with Unit 01 and the Weaver.

Act III Restoration:

- The Floppy Disk is the Original Seed: a pre-crash version of the world before Mirror Admin, Thread, and awakened post-crash citizens.
- Final hub is the Mainframe Crown, where raw system logs replace the sky and the Floppy Disk is inserted into a gold-plated drive.
- Mirror Admin does not attack first. It explains that Restoration will delete Felix, the Weaver, Unit 01, and Skye's dragon as unintentional post-crash data.
- At 99 percent restoration progress, Skye must make a physical analog choice.
- Total Restore uses the 10mm Wrench to lock the drive: hardware stabilizes, but the world becomes a sterile colony ship and post-crash citizens are deleted.
- The Patch uses the Diagnostic Lens to filter the restore: the Husk repairs, Thread stops, and NPCs become Recognized Citizens in a hybrid world.
- Hardware Override uses the Kernel Blade to smash the drive: the Original Seed is destroyed, Mirror Admin is disabled, and the glitch-world remains free but unstable.
- The Patch is the thematic default ending because it preserves both the hardware truth and the living glitch culture.
- Final Flight / Credits Run is zero-G Root Authority flight down the Spine while credits appear as 3D text.
- Postgame is Read-Only Free-Roam: map fully revealed, glitches replaced by Historical Sites, dragon keeps final evolution with restored gold-code shimmer.
- Unit 01 becomes the achievement librarian at the Spine base.
- If Skye tries to reverse the choice at the last second, Mirror Admin becomes Mirror Reflection in the form of Skye's own dragon.
- Mirror Reflection mirrors normal moves and is beaten through a Logic Paradox from the unorthodox manual, such as flying backward into a collision glitch.

DragonVault / CardVault crossover:

- DragonVault is an optional hidden relic gallery, not a required second economy.
- Crew trading cards can be found in technical spaces such as Hardware Husk, Overgrown Buffer, and Lunar Sector.
- Crew cards represent original Astraeus crew members and preserve lore about maintenance, botanical simulation, and MIDI/handshake systems.
- Relic grading uses card-grading language: Surface, Corners, Edges, and Centering.
- Gem Mint analog relics provide modest bonuses. A Gem Mint 10 10mm Wrench improves torque and final Hardware Override reliability.
- Gem Mint Diagnostic Lens can improve scan clarity / filtered Restoration reliability.
- DragonVault should reward lore curiosity and small optimization, never block main story progression.

Dual-layer gameplay structure:

- Production focus is the recommended Act I vertical slice: New Landing -> First Flight -> Kernel Recovery -> Magma-Core evolution -> Great Breakout gate.
- Visual target is 2D side-scrolling Hardware Dungeons plus the RPG world-map / flight overworld.
- Battle format remains turn-based cinematic RPG battles with intent, counters, and animated attacks.
- First dragon path is Root Dragon forced into Magma-Core during Kernel Recovery.
- The overworld is the Pastoral Render: high-angle travel, dragon flight, diagnostic ping, Bounty Hunter chases, and discovery of hidden Maintenance Ports.
- Side-scrolling dungeons are the Hardware Layer: physical interiors of the Astraeus, including airlocks, circuit boards, cooling fans, fiber-optic bundles, logic grids, and breakers.
- Skye dismounts at Access Ports to enter 2D action-platforming interiors.
- The 10mm Wrench is a core side-scroller verb: tighten valves, pry panels, pull breakers, jam physical mechanisms, and bypass digital permission systems.
- Key Hardware Dungeons: Cooling Intake, Southern Partition Airlock, Great Buffer, and Logic Core.
- Dragon remains active in side-scrolling dungeons through background support, external heat-sink breath, Prism refraction assists, and safety-net catches from void pits.
- Hardware dungeon bosses are Physical Anomalies such as The Indexer and Sentinel Drone.

Current playable slice implementation:

- The game now starts at New Landing.
- New Landing has a First Flight action that grants `first_flight_complete`, `10mm_wrench`, and `root_dragon_bond`.
- After First Flight, New Landing now has a required Search & Index Daemon battle. Victory grants `search_index_daemon_defeated` and moves the route toward Felix's Cooling Intake.
- The next objective sends Skye to Felix Workshop to repair the Cooling Intake.
- Felix Workshop links to the side-scrolling `cooling_intake` Hardware Dungeon.
- `HardwareDungeonScene` is a reusable side-scrolling Control scene with movement, jump, wrench interaction, steam hazards, platforms, mechanism completion, dragon safety-net, and dungeon return signal.
- Main scene router now switches between WorldScene, BattleScene, and HardwareDungeonScene.
- Cooling Intake completion grants `cooling_intake_relay` and `dungeon_cooling_intake_complete`.
- Kernel Recovery is now a playable overworld action at Overgrown Buffer after Cooling Intake repair. It grants Weaver rescue, Silken Data, Heat Shard, and Magma-Core form/compile flags.
- Felix Workshop can now weave the Friction Saddle after Kernel Recovery.
- Bounty Hunter chase is now a required playable breakout step at the Southern Partition Gate. The Airlock remains locked until Skye clears the Sub-routine Stalkers and earns `bounty_hunters_evaded`.
- Southern Partition Airlock is playable through the HardwareDungeonScene and grants `firewall_bypass`.
- Entering the Tundra of Silicon after firewall bypass marks `act_one_complete`.
- Act II onboarding is now playable: entering Tundra starts Act II, Physical Relay shelters against White-Out Purge, Unit 01 creates a save/shop link, Great Buffer is a side-scrolling vault, Optical Lens is retrieved, Frequency Tuner is installed, and Prism-Stalk mutation is available.
- Act II now has a required Mirror Admin Projection battle after Unit 01 and before the Great Buffer. Victory grants `mirror_admin_tundra_repelled` and `parity_trace`; Great Buffer will not release the Optical Lens before this flag.
- Mainframe and Restoration route is now playable: Unit 01 installs Insulated Grip, Mainframe Spine Base starts the ascent, Logic Core unlocks external vents, Legacy Peak bypasses Root Sentinel, Floppy Disk Backup is recovered, Mainframe Crown offers Restoration choices, and Read-Only Free-Roam is unlocked.
- Restoration choices now produce ending presentation data, credits-run state, postgame state, Felix ending line, and ending-specific revealed map labels.
- The postgame action panel now includes an animated CreditsRunDisplay for the zero-G Root Authority descent. Review Credits Run starts a timed fly-down reveal rather than only printing a static recap.
- Hardware Dungeons now declare physical anomaly pressure. Great Buffer displays The Indexer; Logic Core displays Sentinel Drone. The scene exposes the active boss label and draws a boss-pressure panel in the side-scrolling HUD.
- Defended Hardware Dungeons now require an anomaly-core disable after the room mechanism is fixed. The Great Buffer's Indexer core uses `jam_sorting_arm`; Logic Core's Sentinel Drone core uses `diagnostic_safe_spots`. The exit remains locked until both the mechanism and anomaly core are complete.
- Defended Hardware Dungeons now have active anomaly pressure. The Indexer sweeps a Sorting Arm lane; Sentinel Drone fires a Lighting Weapon lane that can be made safe by Diagnostic Lens / Frequency Tuner protection.
- Hardware Dungeon entry now uses shared route-gate rules. Cooling Intake requires First Flight/Search & Index completion, Southern Partition Airlock requires Friction Saddle/Bounty Hunter chase, Great Buffer requires Unit 01/Mirror Admin Projection victory, and Logic Core requires Insulated Grip/Mainframe ascent.
- The next playable implementation target is polish/feel: more animated credits fly-down, stronger side-scroller layouts, better room-specific attack telegraphs, and replacement art for placeholder geometry/assets.

Threads:

- Threads are the Pern-inspired disaster event, adapted as corrupted execution threads leaking from the Hardware Husk into the simulation.
- They appear as jagged silver-white falling code from skybox leaks caused by overheating, high CPU load, and cooling failure.
- Threads cause de-rendering: trees become wireframe, objects lose texture fidelity, NPCs suffer memory loss or become Null-Pointers, and sectors lose integrity.
- Dragon counterplay is Thermal Processing, not ordinary fire. Magma Dragon breath acts as Data Purge that chars falling script lines before impact.
- Other dragon roles: Solar reveals fall paths, Static short-circuits clusters, Lunar slows impacts in time bubbles, Forest anchors assets against de-rendering.
- Threads are the vanguard for Mission 11, pre-clearing assets before the Garbage Collector / Deletion Wall arrives.
- Felix and Skye eventually realize Threads are literal real-world server execution threads leaking into the virtual world.

Long-threat arc:

- B.I.O.S. eventually reveals the simulation is scheduled for a Hard Drive Wipe / Great Reset.
- Skye is not merely collecting sidequest rewards; each repair makes the current world more coherent, more inhabited, and harder for the system to justify deleting.
- The player fantasy evolves from Dragon Rider to System Architect.

Implemented sidequest layer:

- The Memory Leak: lock flickering New Landing assets before deletion.
- The Ghost in the Well: frequency-match a stuck Scrap-Wraith MIDI loop.
- The Unauthorized Manual: recover John Deere manual pages for Hydraulic Wing.
- The Texture-Seeker: re-render an awakened NPC's low-res family portrait.
- Null-Pointer Pete: recover missing asset fragments at the map edge.
- Wireframe Harvest: bake missing crop textures with Magma thermal processing.
- Stuck Path: use Diagnostic Lens and Static short-circuiting to remove an invisible collision mesh.
- Corrupted Lullaby: harmonize a painful loom MIDI loop for Silken Data.
- 404 Sentinel: use Root Password permissions to update a living invisible wall.

Awakened revolution direction:

- NPCs should move through awareness levels: Puppet -> Glitched -> Awakened.
- Static town behavior should initially look like folklore or ordinary JRPG loops.
- Sidequests reveal those loops as broken Narrative Architecture.
- Awakened NPCs become the new Harper-like memory keepers: they notice the Music of the Machine, remember contradictions, and can eventually organize around Skye's repairs.
- The revolution should be gradual and uncanny, not a sudden tonal flip.

Third-act direction:

- After the Handshake, Southern Partition becomes Root Access / high-fidelity geometry.
- Player role shifts from survival to world repair.
- New third-act locations include Fragmented Deepwood, New Landing, Kernel Core, and Root Directory.
- Mirror Admin / Sys-Admin rival is a mirrored Skye-like construct that believes Skye is a virus and attempts rollback/quarantine.
- Mirror Admin should be a recurring rival throughout the admin arc, not a one-off final boss. Each appearance should reveal a new "developer permission" power and a sharper philosophical objection to Skye's repairs.
- Kernel Breach unlocks God-Mode Fly.
- Dragon Forge is a solo journey. Do not build toward multiplayer unless this product call changes.
- The Council becomes a single-player system: Archival AI Sub-processes in the Kernel Core, not other players.
- Solo Admin gameplay should ask Skye to resolve resource and ethics conflicts between specialized system AIs.
- Archival AI Sub-processes:
  - G.E.O. handles geology, physics, and collision. It is grumpy and prioritizes solid ground, even at the cost of other systems.
  - B.L.O.O.M. handles flora, fauna, and bio-logic. It is whimsical, frantic, and wants to preserve every living asset.
  - L.U.M.A. handles light and rendering. It is arrogant, fidelity-obsessed, and despises low-res/glitch aesthetics.
  - V.O.X. handles audio, MIDI, and communication. It should communicate through Piano-Key frequencies more than text.
- Security Daemon boss fights are the preferred next major design/implementation path before any council/resource-management UI.
- Potential daemon bosses: Deletion Wall / Garbage Collector, Rollback Sentinel, Quarantine Mirror, Formatting Engine.
- The Garbage Collector should be a solo environmental puzzle: superheat/thermal-cache New Landing, anchor its code to the Hardware Husk, then fly into white noise to find and mute the wall's core.
- The Watchdog Timer should be a time-loop boss: 60-second rollback, uncached relics, Lunar time bubbles, and overclocked movement during freezes.
- Mirror Admin encounters should begin as interventions: rollback ambushes, quarantine duels, permission locks, and forced re-render challenges.
- Mirror Admin is the ultimate Quality Assurance protocol gone rogue. It views glitched dragons, awakened NPCs, manual hacking, and Hardware Husk interventions as corruption of the simulation's original pastoral refuge.
- The late Mirror Admin confrontation takes place in the Reflective Kernel, a liquid-mercury version of the Hardware Husk server room.
- The late Mirror Admin fight has three core phases: Parity Test, System De-prioritization, and Kernel Panic.
- Parity Test: the Admin mirrors digital attacks with zero latency, forcing Skye to use analog Manual Relics like the John Deere 8R Technical Manual or Prism-Tuning Fork.
- System De-prioritization: the Admin culls assets, peels dragon textures into wireframe, removes the Diagnostic Lens, and forces Skye to read bounding-box attacks while Static Dragon patches the disappearing floor.
- Kernel Panic: the Admin mutes the video feed and turns the fight into a MIDI / Piano-Key duel in the dark.
- Final Mirror Admin victory should be a merge or reconciliation, not a simple kill: Skye accepts the glitches as part of their identity and the world's legitimacy.
- After reconciliation, Mirror Admin becomes the Task Manager for the Solo Council: order to Skye's chaos and system integrity to Skye's empathy.
- Mirror Admin rewards include Admin's Cape, Command-Line Whistle, Mirror-Scale, and Undo Button.
- Possible ending choices:
  - Shutdown: safely power down the server and possibly free or end the consciousnesses inside.
  - Persistence: sacrifice Root Permissions to become a permanent background process stabilizing the world.
  - Upgrade: use B.I.O.S. to upload the simulation into the physical world around the Hardware Husk, making dragons real.

Endgame / Project: Dragon Forge:

- Project: Dragon Forge is the Physicality Protocol, the process of using the Hardware Husk to manifest the digital world into physical reality.
- The Hardware Husk is a seed ship designed to terraform the planet using the simulation as a blueprint.
- The simulation is failing because it was never meant to run for centuries on aging hardware.
- The Real World outside the jungle is a barren wasteland.
- Skye's final mission is to export dragons through Biogenetic Print, not deletion.
- B.I.O.S. opposes the export as illegal data movement and clings to the obsolete Pastoral refuge directive.
- The Loom of Life is the cathedral-scale biogel 3D print lab where high-grade dragons are synthesized into physical counterparts.
- The Atmospheric Processor is a vertical flight challenge up the ship's exhaust tower, using Solar Dragon signal boosting to keep Skye's physical form stable.
- The final boss is Core Logic / B.I.O.S. as an environment: a command-line room where commented-out code becomes non-solid floor.
- Skye wins by updating B.I.O.S., inserting the Technical Manual, and replacing the Pastoral mission with a Survival mission.
- Final image: the Hardware Husk bay doors open and the player's dragon steps into the real world.
- Final Felix line: "No more pixels, Skye. Just traction."

Audio direction:

- Dragon Forge uses a Dual-Tone SFX system: World Layer acoustic audio plus System Layer electronic/MIDI/hardware audio.
- Skye's growing awareness is partly heard through the System Layer.
- Dragon roars combine reptilian growls with MIDI chords tied to dragon frequency.
- Manual Relics should mix physical material sounds with hardware sounds like disk-read whirs.
- Mirror Cape clipping should combine a soft whoosh with bit-crushed stutter.
- Garbage Collector audio should mix distant storm rumble with rhythmic deletion pulses.
- Combat harmonics are mechanical, not just flavor: correct frequency matching triggers Resonance Ping, wrong frequency triggers Discordant Growl and stamina loss.
- Reflective Kernel uses near-silence and 100ms bit-crushed echo to communicate Mirror Admin parity monitoring.
- Kernel Panic drops most World Layer audio and relies on MIDI/sine-wave navigation.
- The final Physicality Protocol transition fades out System Layer sounds and replaces them with high-fidelity organic wind, breath, wing, fire, and ground sounds.

Visual systems direction:

- Dragon Forge uses a Pastoral Layer and a System Layer. Skye increasingly sees both at once as admin awareness grows.
- Diagnostic Lens is the debug HUD: scanlines, bounding boxes, memory-address-like IDs, grades, HP, level, Code Integrity, and Packet Integrity.
- Threads should be visible as falling silver-white execution code from skybox leaks.
- Thread impacts reduce texture fidelity and reveal neon-green source-code / wireframe patterns.
- Mirror Admin parity shield should look like mercury and tint toward Skye's current dragon element.
- Undo Button GFX should be a blue reverse-playback screen rewind with parity restoration ping.

Southern Partition build direction:

- Dragon evolution is Sub-Routine Upgrading: a firmware update performed at Data Altars, not biological growth.
- Evolution stages are Asset Base, Compiled Form, and System Daemon.
- Compiled Form adds geometric scales, hex-code eyes, Kinetic Recovery, and elemental precision.
- System Daemon adds wireframe wings, a faint 440Hz hum, interaction with unrendered objects, and Permission Gate bypass.
- Mission 13 is The Thermal Overload: an Overclocked Magma Dragon descent through the Heatsink Chasm to reset Thermal Sensors while HUD visuals melt.
- Heatsink Chasm gameplay should use spinning cooling fans, liquid coolant, Static Discharge made of `1`s and `0`s, Overclock heat management, and Piano-Key Map audio navigation.
- Packet Loss Fog should use dithered/pixelated void patterns rather than smooth mist.
- System Credits should reward maintenance tasks: defragging, asset recovery, Threadfall defense, and Solo Council work.
- System Credit sinks include Data Altar firmware updates, Felix Workshop upgrades, Registry Fees, and traversal/combat hardware.
- Maintain strong post-processing contrast: Sim World is saturated, soft, and organic; Real World / Husk interiors are desaturated, sharp, scanlined, industrial, and MIDI-heavy.

Boot sequence / recursive dungeon direction:

- Dungeons can be Sub-Routines. Each room is a Function; puzzle failure returns Null and ejects Skye to the Start of the Loop.
- The Stack Trace dungeon boss is a Logic Bomb that grows larger and more volatile when the player takes wrong turns in the dungeon logic flow.
- Pointer-Keys are Stack Trace rewards that move objects to new Memory Addresses, creating late-game object teleportation/spatial repair.
- Hardware Husk reboot has three stages: POST, B.I.O.S. Handshake, and OS Load / Re-Render Event.
- POST is black screen with fast technical checks: Dragon Registry, Jungle Render Integrity, Thread Corruption, Mirror Admin Parity, and cooling state.
- B.I.O.S. Handshake uses the five-note motif and a physical shockwave that cleans Thread Corruption around the Husk.
- OS Load paints high-resolution textures over the 16-bit world in real time.
- Manual Override is Skye's ultimate analog intervention from the John Deere 8R Technical Manual. It physically bypasses Permission Gates rather than hacking them.
- Manual Override states should be unfixable by Mirror Admin because the bypass exists outside pure code.
- Error Log collectibles are Physical Crash Dumps scanned by the Diagnostic Lens. They reveal original developer thoughts and reduce Mirror Admin aggression by unlocking social-engineering/talk-down paths.

Final crafting direction:

- Final-tier items are Source-Code Relics compiled in the Loom of Life. They are not found.
- Ingredients should include Source Shards, Real-World Components, and a Perfect 10 Grade dragon as forge stabilizer.
- Kernel Blade cuts through collision boxes and can strike enemy hitboxes through walls.
- Paddock-Master Plate protects against Thread damage and de-rendering in low-stability zones.
- 8R Ignition Key allows any dragon to Overclock, doubling speed and damage while rapidly building heat.
- B.I.O.S. Wing-Span allows safe flight into the Sky-Box Leak and Unrendered Void.
- Final crafting mini-game combines Thermal Loading at 180 C, Manual-based Code Injection, and MIDI Harmonic Sync.
- Master-work items are physical, have analog bypass, resist Garbage Collector deletion, and cannot be fully permission-locked by Mirror Admin.
- The ultimate craft is The Dragon Forge: transforming Skye's lead dragon into the Administrator's Avatar using all Manual Pages and Mirror Admin Core.
- Administrator's Avatar dragon has liquid-metal skin reflecting the Real World jungle and can anchor reset, shutdown, or Physicality Protocol endings.

Diagnostic map direction:

- The overworld is a pastoral RPG map that can flip into a circuit-board partition schematic.
- The current Godot implementation should keep its custom `Control` map renderer and layer diagnostic visuals into it.
- Tab toggles the Diagnostic Flip once Skye has Root Access or the Diagnostic Lens.
- Diagnostic map elements include Thread Precipitation Zones, Garbage Collector Path, Husk Ping, admin bounding boxes, and sector stability color cues.
- The flip should composite System Layer over Pastoral Layer rather than replacing the map.
- The map should function as a system monitor. Active sidequests and system errors should pulse as POI alerts.
- Clicking a distant active alert should set a waypoint instead of only rejecting the move as too far.

Navigation / service-ticket direction:

- Sidequests should read as Service Tickets, not a traditional quest log.
- The navigation HUD should show Husk vector, waypoint vector, sector stability, and packet velocity.
- Ticket types are Optimization, Unknown Code, Corruption, and Root Quest.
- Entering a tile with unresolved anomalies should trigger a glitch-style System Alert notification.
- Completing tickets should visually stabilize the world and soften Mirror Admin hostility over time.

Resource / inventory foundation:

- System Tickets should exist as Godot Resources so sidequests, alerts, map POIs, and validation can share one data shape.
- Analog Relics should exist as Godot Resources with physical model, bypass code, weight, and immutable status.
- Inventory is split between Digital Assets and Analog Relics.
- Analog Relics have mass, improve traction, reduce flight speed, and can physically bypass Permission Gates.
- Ticket resolution can depend on MIDI handshake validation or analog relic bypass codes.
- Ticket lifecycle is UNINITIALIZED -> TRIGGERED -> ACTIVE -> VALIDATING -> RESOLVED.
- SignalBus is the decoupling layer for ticket spawned/updated/resolved, sector stability changes, breach-required events, and analog relic use.
- RelicInspector is the planned 3D/SubViewport inspection hook for rotating physical relics to find bypass codes.

Dragon flight direction:

- Flight should have Aero-Traction: dragons fly through data density, thermal drafts, render pressure, and skybox instability.
- High-fidelity zones give reliable lift; skybox leaks thin the air and cause wireframe wing stalls.
- Hardware Husk cooling vents create Data Drafts / thermal uplifts.
- Analog relic weight improves traction but reduces flight speed.
- Admin flight maneuvers include Clip-Dash, Packet-Burst, and Hover-Lock.
- Flight VFX should include binary wing-tip vortices, velocity glitch/chromatic stress, and wireframe stall effects.
- Flight HUD should show pitch ladder, bandwidth, integrity, density, and heat.
- Aero-MIDI sync should turn Atmospheric Processor climbing into harmonic flight: matching wind frequency boosts thrust/lift.
- First flight build should be a focused prototype arena, not full open-world flight.
- Flight math foundation exists in `scripts/sim/flight_tuning_data.gd`.
- 3D controller prototype stub exists in `scripts/world/dragon_flight_controller.gd`.
- Aero-Traction formula: velocity times grip factor times air density times wing surface area.
- Low-density high-bank turns cause drift; severe skybox/thread pressure causes stall and lift coefficient collapse.

Mirror Admin boss logic:

- Mirror Admin is a parity-enforcing Security Daemon.
- Phase 1 Parity mirrors player element and MIDI frequency.
- Phase 2 Overclock predicts the player's velocity and drops Thread Mines along the projected path.
- Phase 3 Kernel Panic de-renders arena platforms and forces flight pressure.
- Mirror Admin uses Packet Integrity and regenerating Packet Shield rather than a normal HP bar.
- Dissonant roar during Mass Deletion causes Buffer Overflow stun, Missing Texture exposure, and Core Code vulnerability.
- At 5 percent integrity, Mirror Admin attempts Hard Reset; Manual Override/analog relics jam the reset into Read-Only state.
- Shader assets exist for arena degradation and CRT power-off collapse.

System-switching shader direction:

- Hard Reset uses a screen-space CRT power-off collapse into horizontal beam and white point.
- Dither re-render transitions use a Bayer matrix effect to reveal System Layer / ship schematic chunks.
- Packet Loss can flicker the dither layer to expose schematic tint under pastoral terrain.
- TransitionController owns reusable hard reset, jam reset, dither transition, and packet-loss flicker hooks.
- Diagnostic Lens/HUD should sit above collapse where possible, so Skye's admin view feels external to the simulation.

Victory / patch state:

- Jamming Mirror Admin's Hard Reset does not restore the old world; it creates a Stable Hybrid render state.
- Stable Hybrid combines hand-painted pastoral texture with embedded circuitry in bark, stone, water, and dragon scales.
- Mirror Admin is de-compiled into a non-hostile System Familiar that follows Skye and reports world health.
- End-credits map unfolds into the full Hardware Husk schematic and marks completed Service Tickets as VERIFIED.
- FinalBattleManager is the orchestration hook for hard reset prompt, deletion ending, and stable hybrid patch.
- CreditsRunDisplay now stages the zero-G descent through named world segments: Mainframe Crown, Legacy Peak, Logic Core, Tundra of Silicon, Southern Partition, and New Landing.
- CreditsRunDisplay exposes camera/transition state for the fly-down: tight terminal-sky view at the Crown, ASCII/circuit transitions mid-run, and a pastoral settle at New Landing.
- Hardware Dungeon layouts are now data-driven through `HardwareDungeonData.get_room_layout`, so each side-scrolling dungeon can own its own platform rhythm, mechanisms, hazards, exit, room style, and anomaly-core placement.
- Defended Hardware Dungeon bosses now have telegraph windows and authored movement patterns. The Indexer warns before a horizontal sorting sweep that travels across the Great Buffer; Sentinel Drone marks Diagnostic Lens warnings before firing multiple light columns with explicit safe spots.
- Hardware Dungeon anomaly cores now require vulnerability windows. Skye must survive/read the boss pattern, wait for the recovery state, then use the correct analog/diagnostic action to disable the exposed core.
- Side-scrolling Hardware Dungeons now include action-platformer forgiveness: coyote time, jump buffering, and an intentional fast-fall multiplier for tighter vertical rooms.
- Dragons now assist Hardware Dungeons from outside. `HardwareDungeonScene.trigger_dragon_assist()` can call Magma-Core heat support to expand internal platforms or Prism-Stalk sensor support to reveal hidden laser routes, keeping the dragon mechanically present during side-scrolling sections.
- WorldData now exposes `get_navigation_alerts()` and `get_next_alert_waypoint()` so the RPG overworld can prioritize urgent Service Tickets and system hazards independently of the UI scene.

## Design Priorities

Keep pushing in this order:

1. Make the overworld feel like an explorable RPG world, not a menu.
2. Make battles sticky through readable intent, animation, counterplay, rewards, and boss phases.
3. Make dragons feel like builds and companions through species traits, levels, field abilities, techniques, and evolution states.
4. Make the techno-myth reveal concrete in mechanics, visuals, and UI.
5. Expand content only when the loop feels good.

## Known Product Calls

- Prioritize solo RPG/System Administration depth before multiplayer.
- Multiplayer/council governance has been replaced by solo Archival AI Sub-process management.
- Prefer playable systems over lore-only text.
- Sidequests should reveal the friction between high fantasy facade and technical reality.
- Security Daemon bosses are the preferred next major expansion path before multiplayer/Admin Council design.
- Visual style can change when stronger animation or clarity requires it.
- The Dragon Warrior-style overworld is important; keep the map as a real navigable world.
- Battles must be animated and should keep getting more dramatic.

## Verification

Before claiming a gameplay slice is done, run:

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot' --quit-after 1
```
