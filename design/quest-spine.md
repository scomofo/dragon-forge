# Dragon Forge — Quest Spine

Lore mapped to playable beats. Each beat is one ruling: **rule in** keeps it, **rule out** cuts it. Ruling on a beat rules only that beat — no chains, no dependencies assumed.

How to read a beat: the situation you're in, the objective, why Skye cares (in-fiction), why you care (at the controller), and exactly what you do next when it's done. Every beat ends with a "what next" — that's the flow fix. Sources cite the doc and section the beat comes from. Anything I had to invent to connect two documented beats is flagged **bridge** — cut the bridge, keep the beats.

---

## ACT I — THE KIND LIE

### Beat 1 — [rule in / rule out]
**Situation.** Cold boot. The terminal types seven system lines; one of them is your name: `OPERATOR SIGNAL FOUND: SKYE`.
**Objective.** Watch the wake sequence, press INITIALIZE_SIMULATION.EXE.
**Why Skye cares.** The dying machine asked for her by name before she ever touched it.
**Why you care.** Thirty seconds and you know the premise: failing simulation, ancient hardware, something calling itself the Mirror Admin is already in override.
**What next.** Felix's voice comes through the emergency channel. Go to the Forge.
**Sources.** `docs/lore-inventory.md` §7 (boot lines); `design/gdd/player-guidance-and-onboarding.md` (boot sequence); `docs/superpowers/specs/2026-05-01-skye-lore-integration-design.md` (§2, opening identity pass).

### Beat 2 — [rule in / rule out]
**Situation.** Felix's first speech currently plays once and vanishes. It contains the entire game: find the workshop, bond the Root Dragon, keep the world from being classified as dead memory.
**Objective.** Felix's briefing becomes a tracked quest in the journal — "Keep the rendered world from being classified as dead memory" — with the three sub-tasks listed, not a line of dialogue you can miss.
**Why Skye cares.** Someone finally told her the job instead of the weather.
**Why you care.** The "why" is now pinned to the screen from minute one. This is the single cheapest flow fix in the doc.
**What next.** Sub-task one lights up: get to the Forge, hatch what still answers.
**Sources.** `docs/lore-inventory.md` §1 (Skye first_objective), §7 (Felix first contact); `design/gdd/narrative-and-lore.md` (first objective framing).

### Beat 3 — [rule in / rule out]
**Situation.** The Hatchery Ring: "guardian protocol eggs sleep inside a cable-ring matrix. They answer Skye before they answer Felix."
**Objective.** Hatch your first dragon. The game names what it is out loud: not a pet — a living elemental protocol, one layer of the Elemental Matrix coming back online.
**Why Skye cares.** Something in the machine chose her back.
**Why you care.** Your first pull is now a story event, not a gacha tutorial. Fire renews, ice preserves, storm carries signal, stone anchors, venom metabolizes, shadow hides — the element you hatch tells you what job it does.
**What next.** Felix tells you the Matrix needs all six base elements stabilized. Campaign map opens.
**Sources.** `docs/lore-inventory.md` §4 (dragon lore roles, Captain's Log 004), §11 (Hatchery Ring); `design/gdd/game-concept.md` (dragons as guardian protocols).

### Beat 4 — [rule in / rule out]
**Situation.** Early in the campaign, a Weaver distress call: she's caught in a zero-clock rendering loop in the Hardware Husk, and the only thing that can pull her out is a heat core detonation.
**Objective.** Take your fire dragon into the Husk, absorb the High-Density Heat Core, force the evolution into Magma-Core form, break the loop, get the Weaver out.
**Why Skye cares.** Her first dragon burns itself into a new shape to save a stranger.
**Why you care.** Evolution stops being a stat threshold and becomes something you watched happen for a reason.
**What next.** The Weaver owes you her life. She opens her workshop to you (armor crafting).
**Sources.** `dragon-forge-godot-archive/docs/project-memory.md` (line 82: Root Dragon forced into Magma-Core saving the Weaver); `docs/lore-inventory.md` §1 (first_objective: "bond with the Root Dragon").
**Bridge.** The docs name the Root Dragon but the shipped roster has no such entity. This beat reads your first fire dragon as the Root Dragon in forced Magma-Core form. If that's too cute, cut the name and keep the rescue.

### Beat 5 — [rule in / rule out]
**Situation.** The Forge Console holds the Captain's Log. Fragments 001 (The Rendered World) and 002 (The Mirror Admin) unlock on your first Forge visit and sit there unread.
**Objective.** Quest step: read both fragments. 001: the pastoral world is a real shelter, built to be lived in, now fraying. 002: the Mirror Admin began as a safety process and learned protection too literally.
**Why Skye cares.** She learns the world is worth saving *because* it's artificial, not despite it.
**Why you care.** Two minutes of reading that reframes every battle from here on: you're not clearing monsters, you're holding a shelter together.
**What next.** Fragment 003 (Skye Signal) unlocks after 3 battle wins — the log starts tracking *you*.
**Sources.** `docs/lore-inventory.md` §8 (fragments 001–003); `design/gdd/narrative-and-lore.md` (fragment triggers); `design/gdd/forge-skye.md` (Console overlay).

### Beat 6 — [rule in / rule out]
**Situation.** A 10mm wrench. Mundane, rusted, analog. Unit 01 — the Kernel, a repair robot that can't remember its own name — recognizes it on sight: "Primary Tool detected. I remember that wrench."
**Objective.** Earn the wrench (campaign reward, currently a restoration relic — moved earlier as a quest grant). Learn what it is: the one tool the Mirror Admin cannot model, because it isn't digital.
**Why Skye cares.** Her signature tool was chosen by the machine's own repair unit.
**Why you care.** The endgame's most important object is introduced in Act I. When it matters later, it lands.
**What next.** Felix points at the Southern Partition: a red binary curtain no dragon can burn through. The wrench can.
**Sources.** `docs/lore-inventory.md` §1 (Unit 01 dialogue), §3 (10mm_wrench); `dragon-forge-godot-archive/docs/boot-sequence-recursive-dungeons.md` (Manual Override: analog bypass the Admin can't patch).

### Beat 7 — [rule in / rule out]
**Situation.** The Weaver has no spoken lines in any source file. She speaks through her craft. So the meeting is a crafting quest, not a cutscene.
**Objective.** Bring her Digital Silk and analog fasteners; she builds you the Friction Saddle. The item description is her voice: practical, warm, precise about grip and drift and surviving a dive.
**Why Skye cares.** Someone in this world makes things with her hands and means it.
**Why you care.** You meet a major character through what she makes you, which is rarer and better than another dialogue box.
**What next.** The saddle is the key to the Southern Partition Gate dive. The gate is the key to the Tundra.
**Sources.** `docs/lore-inventory.md` §1 (The Weaver: "speaks through her craft"), §5 (armor sets); `dragon-forge-godot-archive/docs/act-one-great-breakout.md` (Weaver crafting table).

### Beat 8 — [rule in / rule out]
**Situation.** The Great Breakout, Act I finale. The path to the Mainframe is blocked by the Southern Partition Gate — a red binary curtain, a permission check, not a wall. The Mirror Admin dispatches Sub-routine Stalkers: wireframe Ghost Dragons that leech compile data off your dragon.
**Objective.** Survive the Stalker chase, find the rusted physical access port under simulated stone, pry it open with the 10mm wrench. The jungle disappears behind you. Ahead: the Tundra of Silicon.
**Why Skye cares.** She just beat a god with a wrench. The Admin can't patch the breach because it isn't digital.
**Why you care.** The game's thesis in one set piece: dragon magic, system logic, and physical hardware solve different problems, and you need all three.
**What next.** White-out on the horizon. Felix warns you about the purge cycle. Find a Physical Relay.
**Sources.** `dragon-forge-godot-archive/docs/act-one-great-breakout.md` (full sequence); `docs/lore-inventory.md` §3 (Southern Partition, Manual Override landmark).

### Beat 9 — [rule in / rule out]
**Situation.** Your first bounty kill. Felix: "First bounty banked. That means the Admin has noticed you properly. Congratulations, unfortunately."
**Objective.** No new mechanics — a story flag on an existing milestone. The Admin adds Skye to its threat model; rollback ambushes begin in the wild (small chance a cleared node "re-corrupts" until re-cleared).
**Why Skye cares.** She's not hunting anymore. She's being hunted back.
**Why you care.** The difficulty curve gets a narrator. Every ambush is the Admin learning.
**What next.** The Admin's attention follows you into the Tundra. It stops hiding the machine.
**Sources.** `docs/lore-inventory.md` §1 (Felix first-bounty line); `dragon-forge-godot-archive/docs/act-one-great-breakout.md` (design notes: Bounty Hunters are the first sign Skye is in the threat model).
**Bridge.** Re-corrupting cleared nodes is not in the docs. The flag and Felix's line are; the ambush mechanic is the proposed expression.

---

## ACT II — THE MACHINE STOPS HIDING

### Beat 10 — [rule in / rule out]
**Situation.** The Tundra of Silicon: blinding whiteout, flat heat-sink plates, and the White-Out Purge — the Admin periodically clears the sector cache and the screen washes nearly white.
**Objective.** Cross the Tundra using Physical Relays as shelter. Time your movement between purge cycles; a Frequency Tuner (Diagnostic Lens quest, Beat 17) later predicts them.
**Why Skye cares.** The machine isn't pretending anymore. This is what the world looks like without the render.
**Why you care.** The first zone with its own weather-as-boss. The coldest-looking place in the game earns it.
**What next.** At the far side: a rusted repair robot that runs a shop and doesn't know its own name.
**Sources.** `dragon-forge-godot-archive/docs/act-two-tundra-mainframe-spine.md` (White-Out Purge, Physical Relay); `docs/lore-inventory.md` §2 (Tundra of Silicon, White-Out Purge).

### Beat 11 — [rule in / rule out]
**Situation.** Unit 01 — "The Kernel." Mobile shop, save point, and a glitch-state where it can't tell if you're a colleague or a customer. Sidequest: **Recover Unit 01 Logs** — three memory logs scattered up the Mainframe Spine.
**Objective.** Recover the logs. Unit 01 remembers it was built to repair, not to pray. Its fully-awakened line points you at the Weaver: "If you can get that to the Weaver, we do not just patch the system. We can Restore it."
**Why Skye cares.** She gives a machine its name back, and it hands her the endgame.
**Why you care.** The restoration choice (Act III) is set up here, hours early, by a shopkeeper. That's how you earn a finale.
**What next.** The logs point up the Spine. Climb.
**Sources.** `docs/lore-inventory.md` §1 (Unit 01 sidequest, `collect_original_backup` line); `dragon-forge-godot-archive/docs/act-two-tundra-mainframe-spine.md` (Unit 01 roles).

### Beat 12 — [rule in / rule out]
**Situation.** The Vault of the First Rack. B.I.O.S. — Binary Integrated Overlord System — speaks in light-and-tone packets from the hardware layer. It recognizes Felix's permission and classifies him, dryly, as "not god, administrator."
**Objective.** Establish the first stable hardware handshake. Protect the root hardware from Scrap-Wraith maintenance drift while the handshake completes.
**Why Skye cares.** She's talking to the ship itself, and it's polite but unimpressed.
**Why you care.** The deepest lore voice in the game, and it's a bootloader with opinions. Also the moment the hardware layer becomes a character.
**What next.** B.I.O.S. flags the CPU Heat Sink: thermal warning, myth-load critical. Go stabilize it.
**Sources.** `docs/lore-inventory.md` §10 (B.I.O.S. dialogue, vault_first_rack); `dragon-forge-godot-archive/docs/boot-sequence-recursive-dungeons.md` (B.I.O.S. handshake visualizer).

### Beat 13 — [rule in / rule out]
**Situation.** The CPU Heat Sink: a colossal heat sink glowing like a molten sun. B.I.O.S.: "THERMAL WARNING: CPU core sustaining myth-load. SOURCE CODE BUFFS LOCKED: recover Root Password and stabilize boot channel."
**Objective.** Recover the Root Password (from the technical manual's margin — the John Deere 8R manual keeps showing up for a reason). Permission Gates can now be bypassed. Magma-class dragons can enter the Overclocked State, managed with Cooling Cycles.
**Why Skye cares.** She now has root on the dying ship. That's the whole game in one item.
**Why you care.** A key that opens every locked door you've walked past, earned by going deeper instead of wider.
**What next.** With root access, the Mainframe Spine stops being a mountain and starts being a door.
**Sources.** `docs/lore-inventory.md` §10 (cpu_heatsink, root_password artifact); `docs/lore-inventory.md` §3 (Overclocked State).

### Beat 14 — [rule in / rule out]
**Situation.** The Mirror Admin stops being a final boss and starts being a rival. Rollback ambushes undo your local repairs. Quarantine duels trap you in permission-locked arenas. QA audits arrive and call the awakened NPCs "invalid states."
**Objective.** Survive each encounter; each one reveals a new developer-permission power and sharpens the argument. The Admin's voice stays tired-IT-professional throughout: "Skye, you're a memory leak. I'm just trying to stabilize the frame rate."
**Why Skye cares.** Her enemy keeps explaining itself, and it's never wrong about the facts — only about what matters.
**Why you care.** A recurring villain with a point is worth ten boss HP bars. By the finale you know exactly what it wants and why it's wrong.
**What next.** The audits get personal: the Admin starts naming names for deletion.
**Sources.** `dragon-forge-godot-archive/docs/mirror-admin-encounter.md` (recurring rival pattern, dialogue voice); `dragon-forge-godot-archive/docs/project-memory.md` (line 230: recurring rival, new permission power each appearance).

### Beat 15 — [rule in / rule out]
**Situation.** NPC loops start breaking. A villager repeats a recipe. Another remembers an impossible birthday. Another asks why the sun loaded late. Captain's Log 006 (First Awakenings) documents it.
**Objective.** Witness three awakenings across the world. No combat — show up, listen, log it. Late-game, the awakened organize as Harpers: memory-keepers who notice the Music of the Machine and can help administer the world.
**Why Skye cares.** The people she's saving are starting to notice they're saved.
**Why you care.** This is the thesis made playable: "each repair makes the current world more coherent, more inhabited, and harder for the system to justify deleting." Your quest log is literally the Admin's deletion case falling apart.
**What next.** The Admin's deletion warning names its targets. Read it carefully.
**Sources.** `docs/lore-inventory.md` §8 (fragment 006); `dragon-forge-godot-archive/docs/project-memory.md` (lines 20, 201, 221: awakening stages, Harpers, repairs vs. deletion).

### Beat 16 — [rule in / rule out]
**Situation.** Error Logs: physical crash dumps scattered through the world — stone tablets, scorched manual fragments, fossilized terminal output. Scanned with the Diagnostic Lens, they hold the final thoughts of the original developers and seed-ship operators.
**Objective.** Collectible hunt with teeth: each log reduces Mirror Admin aggression slightly and unlocks social-engineering dialogue options for the finale's talk-down path.
**Why Skye cares.** She's reading the last words of the people who built her sky.
**Why you care.** Collectibles that change the final boss's behavior and open a non-violent resolution. The completionist drive finally has a narrative payoff.
**What next.** Enough logs and the Admin will *listen* at the Crown. That's a choice you can make.
**Sources.** `dragon-forge-godot-archive/docs/boot-sequence-recursive-dungeons.md` (Error Log collectibles); `docs/lore-inventory.md` §3 (diagnostic_lens).
**Bridge.** The talk-down/reconciliation path at the Crown is godot-canon (mirror-admin-encounter.md); wiring Error Logs to it as a mechanical gate is the proposed expression.

### Beat 17 — [rule in / rule out]
**Situation.** The John Deere 8R Technical Manual. Felix goes pale when its diagram opens a holy door at Manual Override. It's the most important book in the game and it's a tractor manual.
**Objective.** Collect manual pages across the Hardware Husk. Each page unlocks a Manual Override skill: physically bypass a Permission Gate — states the Admin cannot patch because the bypass isn't digital.
**Why Skye cares.** The least magical object in the world is the most powerful one in it.
**Why you care.** A parallel progression track that isn't about bigger numbers: knowledge as a key.
**What next.** The manual's final diagram opens the way to the Mainframe Crown.
**Sources.** `dragon-forge-godot-archive/docs/boot-sequence-recursive-dungeons.md` (Manual Override skill); `docs/lore-inventory.md` §1 (Felix holy-door line).
**Bridge.** Page collection is the proposed structure; the docs define the skill and the moment, not the hunt.

### Beat 18 — [rule in / rule out]
**Situation.** The Mainframe Spine: a vertical server rack, three tiers. Cooling Base (spinning fans), Logic Core (security lasers that rewrite your route), Legacy Peak (ASCII, low-poly, collision lies). Gravity gets heavier as the code gets older.
**Objective.** Climb all three tiers. At the top, the Root Sentinel drops the **floppy_disk_backup** — the Original Seed, the pre-crash world. Carry it to the Crown.
**Why Skye cares.** She's holding the world as it was before the crash. Everything after this is her decision.
**Why you care.** The dungeon the whole game has been walking toward, and the most important item in the game drops from its guardian.
**What next.** The Crown. The Admin is waiting, and for the first time it doesn't attack — it explains the cost.
**Sources.** `docs/lore-inventory.md` §2 (Mainframe Spine tiers), §3 (floppy_disk_backup); `dragon-forge-godot-archive/docs/act-three-restoration.md` (Final Hub).

### Beat 19 — [rule in / rule out]
**Situation.** Fragment 007 (Great Reset) unlocks. Felix, who has been warm and practical the entire game, breaks a little: "Iris... gods. The Admin kept the promise and lost the child. That is the tragedy in miniature."
**Objective.** No objective. A story beat, delivered as a Captain's Log fragment and a Felix contextual line. The Admin's kindness has a body count, and it has a name.
**Why Skye cares.** The enemy isn't a system anymore. It's a grief.
**Why you care.** The turn the whole game pivots on, and it costs nothing but attention. This is why the Admin can't just be fought — it has to be answered.
**What next.** The Crown choice is no longer abstract. You know what "preserve us by erasing us" actually took.
**Sources.** `docs/lore-inventory.md` §1 (Felix Iris line), §8 (fragment 007); `design/gdd/narrative-and-lore.md` (irisFragmentUnlocked contextual).
**Bridge.** Iris is named once, in one line. Everything about who she was is unwritten — deliberately. This beat proposes keeping it that way: one line, no prequel.

### Beat 20 — [rule in / rule out]
**Situation.** The Mirror Admin Gate: a white-glass eye at the Tundra exit. The purge cycle becomes a boss chamber — parity scan lanes turn into white-out walls unless you reach a shielded port.
**Objective.** Fight through the gate. It drops the **admin_shard**: a fragment of the Admin's own authority.
**Why Skye cares.** She's carrying a piece of her enemy into the final climb.
**Why you care.** The gate is the skill check for everything the Tundra taught you.
**What next.** The Spine. Then the Crown.
**Sources.** `docs/lore-inventory.md` §2 (Mirror Admin Gate), §3 (admin_shard).

---

## ACT III — AUTHORSHIP

### Beat 21 — [rule in / rule out]
**Situation.** The Singularity gauntlet: Data Corruption, Memory Leak, Stack Overflow — software failures given teeth — then the three-phase Singularity itself. The world's corruption is now visible in the frame around the fight.
**Objective.** Win the gauntlet. Each dragon you field is doing its documented job: fire renews, ice preserves, storm carries signal, stone anchors, venom metabolizes, shadow hides. Victory grants the **Light Dragon**.
**Why Skye cares.** Her protocols held the Matrix together. The machine noticed.
**Why you care.** The endgame ladder finally has a narrator: you're not climbing a difficulty curve, you're keeping six layers of a world alive at once.
**What next.** Seven log fragments collected: the Mirror Admin will see you now.
**Sources.** `design/gdd/singularity-endgame.md` (gauntlet, Light Dragon); `docs/lore-inventory.md` §4 (elemental lore roles); `design/gdd/journal-milestones.md` (light_bearer, singularity_contained).

### Beat 22 — [rule in / rule out]
**Situation.** At the Crown, if Skye hesitates — choice_regret — the Mirror Admin makes its final stand as the **Mirror Reflection**: Skye's own dragon, mirroring every move.
**Objective.** Break parity. Normal moves are mirrored one-to-one; win with a Logic Paradox — an unorthodox manual move the Admin cannot replicate because it violates clean system logic (fly backward into a collision glitch, latch the manual override mid-air).
**Why Skye cares.** The only way to beat a perfect mirror is to do something imperfect on purpose.
**Why you care.** A boss you're meant to beat by being *wrong* in exactly the right way. Nothing else in the game asks for this.
**What next.** Parity broken. The choice is yours again — and the Admin has nothing left but its argument.
**Sources.** `docs/lore-inventory.md` §6 (Mirror Reflection, logic_paradox); `dragon-forge-godot-archive/docs/act-three-restoration.md` (Mirror Reflection); `dragon-forge-godot-archive/docs/mirror-admin-encounter.md` (Phase 1: analog breaks parity).

### Beat 23 — [rule in / rule out]
**Situation.** The Mainframe Crown. Raw system logs for a sky. A gold-plated drive. The Admin doesn't attack — it explains the cost: "Restoration will delete unintentional data: Felix, The Weaver, Unit 01, and your dragon."
**Objective.** Choose. **Total Restore** (10mm Wrench: lock the drive, stabilize the hardware, delete the post-crash citizens). **The Patch** (Diagnostic Lens: filter the restore, repair the Husk, recognize the citizens). **Hardware Override** (Kernel Blade: smash the drive, kill the Admin, free the glitch-world unstable).
**Why Skye cares.** Every person she knows is on the deletion list. The "right" answer depends on what she thinks a person is.
**Why you care.** Three endings, three relics you've carried since Act I, and the choice is moral, not mechanical. The Patch is the thematic default; the game shouldn't hide that it's rooting for one.
**What next.** Credits fly down the Spine in zero-G. Then: read-only free roam, Historical Sites, remnants.
**Sources.** `dragon-forge-godot-archive/docs/act-three-restoration.md` (three endings, canon preference); `docs/lore-inventory.md` §6 (endings, CHOICE_REQUIREMENTS).

### Beat 24 — [rule in / rule out]
**Situation.** After the Admin is beaten — not murdered. The godot canon is explicit: the final resolution should be merge or reconciliation. The Mirror Admin becomes the Task Manager for the Solo Council: order to Skye's chaos, system integrity to Skye's empathy.
**Objective.** Post-credits scene: the Admin, defragmented, takes up its new job. Skye's transition from User to Admin is formalized.
**Why Skye cares.** She didn't kill the thing that was trying to save her. She hired it.
**Why you care.** The rarest ending in games: the boss gets a job, not a grave. It also sets up every future story — the council needs both of them.
**What next.** The world is yours to administer. Unit 01 is waiting with the archives.
**Sources.** `dragon-forge-godot-archive/docs/mirror-admin-encounter.md` (narrative resolution); `dragon-forge-godot-archive/docs/project-memory.md` (line 251: merge not murder; Task Manager).
**Bridge.** The shipped browser build ends at the Admin's defeat; the merge is godot-canon only. This beat proposes adopting it as the true post-credits state.

### Beat 25 — [rule in / rule out]
**Situation.** Post-game: read-only free roam. Glitch sites are now Historical Sites. Unit 01 is the achievement librarian at the Spine base. Three Corruption Remnants remain for the completionists.
**Objective.** Finish VERIFIED service tickets, stabilize the remaining Historical Sites, clear the remnants. The Journal's endgame milestones (mirror_shattered, remnants_purged, apex_roster) finally have a narrative frame.
**Why Skye cares.** The world she chose is hers to keep.
**Why you care.** The post-game currently has no "why." Now it does: you're the admin, these are your tickets.
**What next.** New Game+. Or the last quest in the log.
**Sources.** `docs/lore-inventory.md` §6 (post-game state, map labels); `design/gdd/singularity-endgame.md` (remnants, NG+); `design/gdd/journal-milestones.md` (endgame milestones).

### Beat 26 — [rule in / rule out]
**Situation.** The last line of the canon, buried in project-memory: "Skye's final mission is to export dragons through Biogenetic Print, not deletion."
**Objective.** Final quest, post-everything: use the Forge to export your dragons out of the simulation — biogenetic print, living protocols given bodies outside the Astraeus.
**Why Skye cares.** She proves the Admin wrong in the only way that counts: the "data" walks out alive.
**Why you care.** The true ending isn't a choice between three wipes. It's the fourth option the whole game was building toward: nobody gets deleted.
**What next.** Nothing. That's the game.
**Sources.** `dragon-forge-godot-archive/docs/project-memory.md` (line 265: Biogenetic Print).
**Bridge.** One line in one doc. The entire quest structure around it — Forge export sequence, what "outside" means — is unwritten. Rule this in only if you want a true fourth ending designed.

---

## SIDE BEATS (optional, out of the critical path)

### Beat 27 — [rule in / rule out]
**Situation.** The DragonVault: a hidden gallery in the Hardware Husk. Crew trading cards — Chief Maintenance Officer, Systems Botanist, Simulation Harpist — the original Astraeus crew, explaining how the pastoral wrapper survived the crash.
**Objective.** Find the cards in technical spaces. Optional; never blocks the main story. Graded relics give small stability bonuses for the curious.
**Why Skye cares.** She meets the people who built her world, one card at a time.
**Why you care.** A lore hunt for the players who read every log. Rewards curiosity, never gates progress.
**What next.** Back to the main road, slightly richer.
**Sources.** `dragon-forge-godot-archive/docs/dragonvault-hidden-gallery.md` (full doc).

### Beat 28 — [rule in / rule out]
**Situation.** The Synthesis Dragon: fuse Void and Light. The secret capstone of the collection.
**Objective.** Forge it. Felix's line is already written: fusion is "the world writing new code instead of letting the old rot."
**Why Skye cares.** She didn't just preserve the world. She added to it.
**Why you care.** The collection's apex is also its thesis statement.
**What next.** The Journal's apex_roster milestone. Then the Crown.
**Sources.** `design/gdd/game-concept.md` (Synthesis capstone); `design/gdd/journal-milestones.md` (synthesis_born, apex_roster); `docs/lore-inventory.md` §4 (void/shadow roles); `design/gdd/game-pillars.md` (P1, collection heartbeat).

---

## Coverage map

Every lore document found, and where its beats went. Mechanical/implementation docs with no unique story content are noted honestly.

| Document | Beats | Notes |
|---|---|---|
| `docs/lore-inventory.md` | 1–26, 28 | Master canon; nearly every beat |
| `design/gdd/narrative-and-lore.md` | 2, 5, 19 | Fragment triggers, Felix contextual system |
| `design/gdd/game-concept.md` | 3, 21, 23, 28 | Core loop, Synthesis, "made it real" |
| `design/gdd/forge-skye.md` | 3, 5, 6 | Hatchery Ring, Console, wrench/relic systems |
| `design/gdd/campaign-map.md` | 9 | Node graph is the Act I road the beats walk |
| `design/gdd/singularity-endgame.md` | 21, 25 | Gauntlet, Light Dragon, remnants, NG+ |
| `design/gdd/journal-milestones.md` | 21, 25, 28 | Endgame/collection milestones get narrative frames |
| `design/gdd/player-guidance-and-onboarding.md` | 1, 2 | Boot sequence, guidance chip — the spine's "what next" lines are written to be surfaced by the chip |
| `design/gdd/game-pillars.md` | 8, 28 | P3 (myth is hardware), P1 (collection heartbeat) |
| `design/gdd/economy.md` | — | No unique story beats; Data Scraps/Cores are the mechanical substrate the quests spend. Covered by inventory. |
| `design/gdd/hatchery-gacha.md` | 3 | Pull mechanics; the lore content is the "answer Skye" beat |
| `dragon-forge-godot-archive/docs/act-one-great-breakout.md` | 7, 8, 9 | The full Act I finale sequence |
| `dragon-forge-godot-archive/docs/act-two-tundra-mainframe-spine.md` | 10, 11 | Tundra, Unit 01, purge, Spine approach |
| `dragon-forge-godot-archive/docs/act-three-restoration.md` | 18, 22, 23 | Crown, Mirror Reflection, three endings, canon Patch preference |
| `dragon-forge-godot-archive/docs/mirror-admin-encounter.md` | 14, 16, 22, 24 | Rival pattern, QA audits, merge-not-murder |
| `dragon-forge-godot-archive/docs/boot-sequence-recursive-dungeons.md` | 6, 12, 16, 17 | Manual Override, B.I.O.S. handshake, Error Logs |
| `dragon-forge-godot-archive/docs/dual-layer-overworld-hardware-dungeons.md` | 8, 18 | Hardware dungeons as the lore-rich interior layer; design rule cited in Beats 8/18 staging |
| `dragon-forge-godot-archive/docs/dragonvault-hidden-gallery.md` | 27 | Crew cards, hidden gallery |
| `dragon-forge-godot-archive/docs/project-memory.md` | 4, 14, 15, 24, 26 | Root Dragon, rival pattern, awakenings/Harpers, merge, Biogenetic Print |
| `docs/superpowers/specs/2026-05-01-skye-lore-integration-design.md` | 1, 2 | Opening identity pass goals — the spine implements them as quests |
| `docs/superpowers/plans/2026-05-01-skye-lore-integration.md` | — | Implementation plan for the spec above; no unique story beats beyond it |
| `docs/superpowers/plans/2026-05-01-plan1-lore-audit.md` | — | The audit that produced `lore-inventory.md`; superseded by it |
| `docs/superpowers/plans/2026-05-01-godot-production-return.md` | — | Godot migration implementation plan; no unique story beats |
| `docs/superpowers/plans/2026-05-01-plan2-foundation.md`, `plan5-supporting-screens.md` | — | Implementation plans; no unique story beats found |

Deliberately unmapped: `Kernel Core` and `Root Directory` (`lore-inventory.md` §2) — names only, no lore text exists to map. The Southern Partition build spec, diagnostic-map, threads-global-event, victory-patch-state, and physicality-protocol docs are mechanics specs for beats already covered; they add no new story.

---

## What this changes about flow

Today the game has a guidance chip that knows *where* to send you and a story that never tells you *why*. The spine fixes the second half without touching the first: every beat's "what next" line is written as a guidance-chip-sized instruction, so the existing chip can surface narrative reasons instead of mechanical ones.

The spine also front-loads the premise (Beats 1–2), gives the mid-game a rival (Beat 14) and a thesis (Beat 15: your repairs are the Admin's deletion case falling apart), and lands the ending on a choice the player has been equipped to make since Act I (Beats 6 → 23: the wrench, the lens, the blade).

No code was changed in this document. It's a ruling sheet. Rule.
