# Dragon Forge — Reconnection Campaign

**Open `project.godot` in Godot 4.6.3 Standard and press F5.** Run Project launches the complete Reconnection campaign: **22 connected rooms, four sectors, 13 encounters and an ending**. The current development pass adds Prism, the Synthesis guardian, and campaign save schema 11. Release acceptance for this revision must be established by its own workflow results.

Choose **Begin campaign** → press **E** at the hatch ring to awaken Magma → press **M** → **Outer Grid / Enter sector**. Follow the labeled north portals. After each sector boss, collect its core, return to the Forge and install it to open the next sector.

Controls: WASD move, mouse aim, 1–4 techniques, Space dodge, Shift guard, E interact, Q repair, Tab swap, P guardians, M routes, N journal, Esc pause. Menus and contextual interactions also provide clickable controls.

## Guardians and progression

Up to **nine guardians** can be owned: Magma, Rime, Arc, Cairn, Nox, Umbra, Null, Lumen and Prism. Expeditions have **two field slots**. Select the active guardian and reserve at the Forge Nursery. Optional recruitment can happen in any order allowed by each guardian's actual prerequisites; recruiting another guardian preserves an existing expedition pair and keeps the campaign saveable.

Magma and Rime have earned evolved forms; Arc can evolve into Tempest Arc. The Forge also supports non-destructive resonance recruitment. **Fire + Venom produces Shadow**: awaken Nox, then create Shadow resonance and awaken Umbra at Resonance Fusion. Umbra earns Phase by dodging real incoming hits and spends it only when Phase Strike deals damage. Closed enemy and boss shields still block that strike.

For Void, **stabilize the Singularity, recover the preserved imprint in its chamber, then return to Resonance Fusion at the Forge to stabilize it and awaken Null**. Existing guardians are retained. Null's four techniques are Rift Shard, the pushing Void Rift, the defensive Null Reflect and the pulling/healing Siphon Rift. Shields remain authoritative; bosses and enemies with locked attack warnings stay anchored, and displacement respects collision.

**Stabilizing the Singularity directly awakens Lumen**, the gold-and-white Light guardian with stained-glass wings and a biped silhouette. Light needs no Forge recipe or Void recruitment. Its Prism Claw, Radiant Beam and radial Solar Flare respect enemy shields; Restoration heals Lumen for 25% of its maximum HP.

**Light + Void produces Synthesis**: with Lumen and Null owned, create Synthesis resonance at the Forge and awaken Prism. Both parents and the selected expedition pair remain intact. Prism combines Void Rift displacement, direct Radiant Beam and Recompile, a radial attack that selects the strongest existing Chill, Charge or Toxin payoff on each target. Shields block damage and preserve those statuses.

Five imported boss identities, Forge Trials, salvage upgrades, journals and the existing ten-track soundtrack are integrated. Audio settings are available on the title and pause menus. This remains a compact campaign adaptation; the browser game's full collection and content are outside its scope.

## Source project and standalone builds

The included models and textures are ready for Godot to import. Playing the source project requires Godot; it does not require Python, Node or asset generation. **F5 runs the campaign**. F6 runs the selected scene, including optional character inspection and boss-arena validation scenes. The original mechanical slice remains at `world/main.tscn` for regression work.

Standalone Windows, macOS and Linux packages are produced and checked separately by **Nextgen standalone playtests**. Use a `standalone-playtest` artifact from a successful run for the revision you want; candidate exports have not completed native-runner checks. Standalone packages run without an installed Godot editor. See [release/README.md](release/README.md) for launch and build instructions.

Valid older campaign saves migrate in memory to schema 11; loading preserves their original bytes and the first later successful write retains a backup. Migration grants no Synthesis progress. Completed saves from before schema 10 receive the earned Light guardian during migration; unfinished campaigns do not. Optional ownership order and the selected two-guardian pair survive migration. Unknown, corrupt or unearned states remain protected from overwrite.

See [campaign/README.md](campaign/README.md) for routes, combat, saves, tests and the remaining human acceptance work. Visual captures do not establish controller quality, balance or target-hardware frame times; the optional first-pass guardian rigs are not certified for foot locking. [validation/README.md](validation/README.md), [art/README.md](art/README.md) and [art/POLISH.md](art/POLISH.md) describe the inspection tools and inherited art work.
