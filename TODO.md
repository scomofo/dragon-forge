# Dragon Forge — To Do

## SNES-AAA quality pass (priority order)

- [x] P0 Identity lock — ADR-0011, art bible, music identity, animation honesty, zone + boss-pattern skeletons
- [ ] P1 Battle frames — art commissions still open (see below); code contracts landed:
  - [x] P1.2 code — 9 signatures own dedicated VFX keys; `VFX_PLACEHOLDERS` cleared; procedural palette/motif/motion per signature (`src/sprites.js`, `src/VfxOverlay.jsx`)
  - [x] P1.1 code — arena contract (`isBannedArtUrl`, `KNOWN_PLACEHOLDER_ARENAS`); `fire.webp` banned; gravity-chamber grid tracked as the one placeholder; 404 language removed from `handoff/ARENA_AND_FORGE_BRIEF.md`
  - [x] P1.3/P1.4 code — `DRAGON_BATTLE_SETS` (9) + `NPC_BATTLE_SETS` (9) at 96px cell, honestly `portrait-only` until sheets land
  - [x] P1.5 code — every boss phase declares its own idle/attack cells; remnant hue-rotate recolors removed
  - [x] P1.3/P1.4 pipeline — pose-driven battle-set loader (`src/battleSets.js`: idle/attack/hurt/faint resolution + sheet/fallback) with strip player (`src/BattleSetSprite.jsx`); `DragonSprite`/`NpcSprite`/`BattleScreen` wired, portraits render unchanged until sheets ship
  - [x] P1.1 registry — `src/arenas.js` covers the 11 battle arenas (all honest placeholders); grade-only filter allowlist with 7 locked content-filter users; `BattleScreen` resolves through it with debug flags
  - [x] P1.1 art — all 11 battle arenas + the 5 element arenas now authored 1024² (handoff/ARENA_AND_FORGE_BRIEF.md via seedream v4.5); gravity-chamber grid placeholder retired; `KNOWN_PLACEHOLDER_ARENAS` empty; webp in `public/assets/arenas/`
  - [x] P1 art — all done: arenas + dragon/NPC battle sheets + boss phase attack cells (12) + 9 signature VFX strips (vfx_sig_*.webp, wired via `strip:` so the overlay prefers them over the procedural fallback). Polish debt cleared 2026-09-05: void/protocol_vulture sheets regenerated with rim-light prompts (readable on dark backdrops); singularity surge/void idles regenerated edit-anchored (lightning storm vs black hole — no longer hue-twins); all 72 battle strips now have programmatic squash-and-stretch in-betweens (breathing idle, lunging attack, recoil, settle) rebuilt from cached keyframes with zero API spend.
- [x] P2 Soundtrack — all 12 tracks authored and wired (music pipeline agent, separate from gameplay agents): mirrorAdmin/hub/victory/defeat/credits composed note-for-note from the written motif via `tools/music/` (mirrorAdmin verified as the title motif at half-time with Ab in the bass, no percussion on the downbeat); mapWander/battleB/battleElite/singularity/boss commissioned via fal.ai Lyria 2; battleB split into a three-stage ramp (battle → tense <50% → elite <25%); gatekeepers/remnants route to the boss track; victory/defeat are authored sting files; `MUSIC_COMMISSION` in `src/soundEngine.js` is the doc's code twin with a disk test. Acceptance: a 0–credits run plays 10+ distinct authored loops (doc asks ≥6).
- [x] P3 Four authored zones — Outer Grid / Frozen Cache / Storm Spine / Admin Core rooms (`src/worldZones.js`) — **all four zones shipped to master** (hands-on acceptance playtests below remain open)
  - [x] Outer Grid gameplay — seven rooms, a saved crossing choice, optional cache, Sentinel/Overflow encounters, room checkpoints, and return reward
  - [ ] Outer Grid hands-on acceptance — first-time comprehension, both crossings, loss/retry, keyboard/controller/touch, narrow screens, and timed pacing (`docs/outer-grid-playtest.md`)
  - [x] Outer Grid presentation — room transitions (walk-off/enter + scene dim) and the bespoke firewall-span crossing animation (brace: struts + bridge; crawlway: hatch) landed 2026-09-05, verified via `scripts/outer-grid-shots.mjs`; room backgrounds still reuse shipped arena/Forge art (bespoke room art is a future commission pass)
  - [x] Frozen Cache gameplay + presentation — eight rooms (Cold Archive with three talking remnants whose lines teach the boss tells; Mute Channel; Wraith Cache; Thaw Junction choice; Frozen Vault cache; Siren Loop; Crypto Lock; Thaw Gate), saved junction choice, vault cache, encounter checkpoints, return reward; bespoke thaw (warm rise) / crack (fracture + cold flash) crossing animations; verified via `scripts/frozen-cache-shots.mjs` (both routes); backgrounds reuse shipped arena art
  - [ ] Frozen Cache hands-on acceptance — same playtest dimensions as Outer Grid
  - [x] Storm Spine gameplay + presentation — eight rooms (Overclock Gantry shelter with the hydra overhead; Live Wire; Hydra Spine mid-boss; Fork in the Wire three-lane setpiece — capacitor cache / conduit lore / direct bus, other two lanes arc shut permanently; Capacitor Bank; Broken Conduit; Logic Core finale; Discharge Gate), saved lane choice, 25-scrap cache, return reward; bespoke arc-shut animation (chosen lane floods storm-blue, others arc red and collapse); verified via `scripts/storm-spine-shots.mjs`; zone def corrected to match the DAG (hydra mid-boss, logic core finale). PR #11
  - [ ] Storm Spine hands-on acceptance — same playtest dimensions as Outer Grid
  - [x] Admin Core gameplay + presentation — eight rooms (Mirror Vestibule with Felix's last unscripted line; Processional; Recursive Gate mid-boss; Cold Lanterns setpiece — hoarding/memory/passage, light one and the other two burn out; Reliquary Vault cache; Echo Archive lore; Protocol Perch finale; Reset Threshold homeward), saved lantern choice, 35-scrap cache, return reward; bespoke lantern flare/burn-out animation; zone palette CSS; verified via `scripts/admin-core-shots.mjs`; QA caught and fixed two stray unkeyed arena files (lightning/magma.webp) and two mismatched room backdrops. PR #12 (merged 2026-09-05)
  - [ ] Admin Core hands-on acceptance — same playtest dimensions as Outer Grid
- [x] P4 Execute `bossPatterns.js` in `battleEngine` — **all 13 live** (options-based engine hooks + per-boss screen state; `mirror_admin_reset` via per-phase move history). Depth-axis choice (dual techs **or** 4-move kits) still open
- [ ] P5 Roster expansion only after P1–P3

## Current reliability pass

- [x] Battle state integrity — normal commands and guarded swaps share enemy scripts, damage/status resolution, faint handling, and rewards; Restoration/lifesteal animate real healing; settled HP/buffs match the resolved turn; Siren preserves both living dragons and interrupts the outgoing command without spending its technique
- [x] Boss HP consistency — Vulture drains and applies Blind on a landed Soul Drain; Great Reset commits capped healing and recognizes techniques executed on the KO turn; overheat self-damage remains in the resolved result
- [ ] Battle hands-on acceptance — healing before/after enemy hits, guarded entry at 1×/2×, Siren turns 2/5, lethal entry and reserve return, Vulture drain and Mirror Admin reset
- [ ] Remaining authored-boss contracts — Logic Bomb fuse must override a stored charge and guarantee its turn-seven hit; Data Corruption must rearm after Burn
- [ ] Save recovery — preserve unreadable progress, recover a last-known-good save, and report failed writes
- [x] Campaign guidance — remember the last entered expedition across all four zones, keep route objectives and unclaimed rewards ahead of dailies, explain cross-zone prerequisites, and show the correct room-return hint after defeat
- [x] Playback controls — live MP3/procedural volume, immediate mute, destination-aware unmute, cancelable fades, and disposed arpeggio notes
- [x] Title input — Start no longer bubbles over the next screen's music, and keyboard sound controls no longer trigger Start
- [ ] Manual browser check — title keyboard controls, volume/mute through navigation, rapid screen changes, and narrow-screen audio controls

## Recent Browser QA

- [x] Save recovery — validate before migration, protect the main save with a previous-write backup, preserve damaged originals, retain failed writes in memory with retry/download, and confirm import/restore/reset or conflicting-save replacement (ADR-0012)
- [ ] Save recovery browser acceptance — damaged/legacy saves, denied/full storage, failed writes during battle, cross-tab conflict, portable import/export, reset, keyboard and 390px layout (`docs/save-recovery-playtest.md`)
- [x] Forge hub refactor: scene/overlays/movement split, CSS extracted, truthful station copy
- [x] Browser Playwright smoke: desktop/tablet/mobile screenshots and overflow checks
- [x] Asset manifest test: runtime dragon, NPC, egg, arena, and boss references checked under public/
- [x] Bespoke Void Dragon evolution sprites: generated void_stage1–4.png
