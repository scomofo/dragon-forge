# Control Manifest

> **Status**: Active
> **Last Updated**: 2026-05-26
> **Source ADRs**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0013, ADR-0014, ADR-0015
> **Engine**: Godot 4.6

This manifest is the flat implementation rule sheet for Dragon Forge. Stories and implementation agents should treat the rules below as mandatory unless a later Accepted ADR supersedes them.

## Global Rules

| ID | Rule | Source |
|---|---|---|
| CM-GLOB-01 | Durable gameplay state must round-trip through Save / Persistence. Feature systems must not write save files directly. | ADR-0001 |
| CM-GLOB-02 | Durable-state signals must fire only after save commit success. | ADR-0001, ADR-0002 |
| CM-GLOB-03 | Cross-system notifications must use semantic events or signals with stable IDs. | ADR-0002 |
| CM-GLOB-04 | A missing listener, muted audio bus, or missing optional presentation asset must not block gameplay progression. | ADR-0002 |
| CM-GLOB-05 | Stable IDs stored in save data must not be renamed without migration. | ADR-0004 |
| CM-GLOB-06 | Top-level screen transitions must go through SceneFlowService. | ADR-0005 |
| CM-GLOB-07 | Runtime systems must read save snapshots or typed projections, not live mutable SaveData Resources. | ADR-0006 |
| CM-GLOB-08 | Battle completion is a pre-commit settlement request until the caller commits through Save / Persistence. | ADR-0007 |
| CM-GLOB-09 | Campaign Map/Singularity authored encounter data is the authority for final reward settlement; Battle payload reward values must validate against that data. | ADR-0008 |
| CM-GLOB-10 | `player_scraps` may change only through EconomyLedger inside a SaveTransaction. | ADR-0009 |
| CM-GLOB-11 | Singularity is the only owner of corruption class, SCAR nodes, gatekeeper flags, Mirror Admin defeat, Void grant, ending ID, and Mirror Admin phase checkpoints. | ADR-0010 |
| CM-GLOB-12 | Corruption and post-game visual effects are presentation-only and must not mutate gameplay state. | ADR-0011 |
| CM-GLOB-13 | Hatchery, Fusion, Journal, and Audio must use their dedicated service boundaries before implementation stories. | ADR-0012, ADR-0013, ADR-0014, ADR-0015 |

## Save / Persistence

| ID | Required | Forbidden |
|---|---|---|
| CM-SAVE-01 | Use typed `SaveData` Resource for durable state. | Ad hoc JSON/dictionary save schema for MVP durable state. |
| CM-SAVE-02 | Use `SaveTransaction` staged mutation for multi-field changes. | Partial saves such as Scraps deducted without item flag set. |
| CM-SAVE-03 | Implement temp-write, verify, backup, rename, reload-validate, then emit. | Emitting committed-state signals before file commit. |
| CM-SAVE-04 | Keep debug failure injection out of release exports. | Shipping QA failure hooks. |
| CM-SAVE-05 | Use `ending_id != ""` as the only post-game persistent authority. | Serialized `game_state = "post_game"`. |

## Input

| ID | Required | Forbidden |
|---|---|---|
| CM-IN-01 | Define MVP actions as distinct `StringName` InputMap actions. | Combined `ui_up/down/left/right` action names. |
| CM-IN-02 | Complete Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and terminals with d-pad plus confirm/cancel. | Hover-only interaction. |
| CM-IN-03 | Route feature logic from semantic actions. | Branching on raw gamepad button constants in feature systems. |
| CM-IN-04 | Preserve separate keyboard/gamepad focus and mouse/touch hover behavior for Godot 4.6. | Assuming hover focus and controller focus are the same. |
| CM-IN-05 | Interpret Counter as contextual `battle_defend` during Singularity `tritone_window`. | Adding a separate MVP Counter input action. |
| CM-IN-06 | Restore keyboard/gamepad focus through Input Router after every top-level screen transition. | Treating mouse hover as controller focus. |

## Events And Presentation

| ID | Required | Forbidden |
|---|---|---|
| CM-EVT-01 | Use semantic signal names such as `corruption_class_changed(payload)`, `ending_resolved(ending_id)`, and `journal_entry_available(fragment_id)`. | Sending UI widget names or raw input events across systems. |
| CM-EVT-02 | Audio Director subscribes to events and owns presentation only. | Audio Director owning or mutating gameplay state. |
| CM-EVT-03 | Journal / Console unlocks content from milestones and records read state through Save / Persistence. | Journal resolving endings, combat, economy, or map traversal. |
| CM-EVT-04 | Gameplay logic must use timers/signals independent of audible playback. | Requiring audible playback for progression. |

## Authored Data

| ID | Required | Forbidden |
|---|---|---|
| CM-DATA-01 | Use typed Resources for cross-system content with stable IDs. | Hardcoding implementation-facing IDs in scattered scripts. |
| CM-DATA-02 | Validate required content IDs at load time. | Failing silently when required authored content is missing. |
| CM-DATA-03 | Reference content by ID, not display text. | Using localized/prose text as a save or logic key. |
| CM-DATA-04 | Keep Shop OQ-SH01 tuning provisional until Campaign Map node/playtest data exists. | Finalizing boss/hazard Scrap bonuses from estimates alone. |
| CM-DATA-05 | Treat `dragon_id: StringName` as canonical dragon identity and derive `stage` from level. | Element-only identity, numeric-only identity, or persisted stage as canonical state. |
| CM-DATA-06 | Keep authored battle definitions as typed Resources and runtime battle state in RefCounted/controller objects. | Mutable combat/session state in shared `.tres` Resources. |
| CM-DATA-07 | Keep Hatchery pull tables, Fusion rules, Journal libraries, and Audio libraries as typed Resources or approved generated tables with stable IDs. | Hardcoded pull weights, fusion constants, lore IDs, or cue IDs scattered through UI scripts. |
| CM-DATA-08 | Bind battle presentation through `BattleAnimationManifest` Resources selected by `BattleDefinition.animation_manifest_id` and resolved against `MoveDefinition` IDs. | Move-specific sprite paths or VFX paths embedded in battle runtime code or `MoveDefinition`. |

## Scene Flow And Services

| ID | Required | Forbidden |
|---|---|---|
| CM-SCENE-01 | Bootstrap foundation services in explicit order: content, save, input, scene flow, then presentation subscribers. | Feature code relying on hidden Autoload `_ready()` side effects. |
| CM-SCENE-02 | Register required screen IDs through authored content or approved tables and validate them at boot. | Scattered hardcoded root-scene paths. |
| CM-SCENE-03 | Preserve the current screen if registration, instantiation, or setup of the next screen fails. | Freeing the active screen before the replacement is valid. |
| CM-SCENE-04 | Use `PackedScene.instantiate()` and callable signal connections. | Godot 3 `PackedScene.instance()` or string-based `connect()` patterns. |

## Dragon Progression

| ID | Required | Forbidden |
|---|---|---|
| CM-DRAGON-01 | Mutate dragon records only through DragonProgressionService helpers inside a SaveTransaction. | Direct `DragonRecord` field edits from Battle, Hub, Campaign Map, Hatchery, Fusion, or Singularity. |
| CM-DRAGON-02 | Emit progression/stage events only after save commit success. | Emitting `stats_updated` or `stage_advanced` from inside the XP loop before commit. |
| CM-DRAGON-03 | Return named result types such as `XPApplyResult`, `DragonCreationResult`, and `ResonanceChargeResult`. | Anonymous `Dictionary` contracts for progression APIs. |
| CM-DRAGON-04 | Carry both `dragon_id` and `element` in dragon progression events. | Element-only progression events. |
| CM-DRAGON-05 | Add active/passive Resonance charges through `DragonProgressionService.add_resonance_charge()`. | Battle Engine or Campaign Map incrementing `dragon.battle_charges` directly. |
| CM-DRAGON-06 | Let Hatchery and Fusion create or mutate dragons only through source-specific DragonProgressionService helpers. | Hatchery or Fusion constructing DragonRecord instances directly in UI code. |

## Battle Runtime

| ID | Required | Forbidden |
|---|---|---|
| CM-BATTLE-01 | Keep Battle Engine scene-local: a Battle screen/host owns a controller Node, which owns one RefCounted BattleSession. | Battle Engine as an Autoload or persisted session. |
| CM-BATTLE-02 | Accept gameplay actions only in TELEGRAPH through Input Router semantic actions. | Raw input constants or action acceptance during IMPACT/RECOIL/RESOLUTION. |
| CM-BATTLE-03 | Return `BattleEndedPayload` and `BattleDurableDelta` for settlement. | Battle Engine opening save transactions or mutating SaveData directly. |
| CM-BATTLE-04 | Let Campaign Map or Singularity apply XP, Scraps, HP/loadout deltas, item flags, node flags, boss flags, and Resonance charges. | Battle Engine applying rewards, progression, map state, or Singularity milestone flags. |
| CM-BATTLE-05 | Treat Mirror Admin as one continuous BattleSession with profile swaps and final-only battle completion. | Ending and restarting battle sessions between PARITY, OVERCLOCK, and KERNEL_PANIC. |
| CM-BATTLE-06 | Commit Mirror Admin mid-fight corruption only with matching phase checkpoint data, or defer corruption commit until final settlement. | Committing CRITICAL/BREACH mid-fight while reloading only from the stale pre-boss save. |
| CM-BATTLE-07 | Validate every battle-capable actor has manifest bindings for required moves, Defend, hurt, defend-hit, KO, and status receive before production content lock. | Shipping generic shared attack placeholders or content that chooses animations by hardcoded move-name branches. |

## Campaign Map

| ID | Required | Forbidden |
|---|---|---|
| CM-MAP-01 | Author Campaign Map as typed immutable Resources with validated node IDs, connections, boss IDs, CROWN ID, and reward data. | Runtime mutation of shared map `.tres` Resources. |
| CM-MAP-02 | Settle Battle results in one Campaign Map or Singularity SaveTransaction using `BattleEndedPayload` and `BattleDurableDelta`. | Treating Battle completion as durable reward authority. |
| CM-MAP-03 | Award passive bench Resonance for slots 2-3 on every expedition battle, win or loss. | Awarding bench Resonance only on victory. |
| CM-MAP-04 | Validate Battle echoed Scrap reward against authored node/boss reward data before applying EconomyLedger mutation. | Accepting arbitrary `payload.scraps_earned` as final economy authority. |
| CM-MAP-05 | Use Campaign Map `cleared_bosses[]` only for generic non-Singularity bosses. | Writing Singularity gatekeeper or Mirror Admin defeated flags from Campaign Map. |
| CM-MAP-06 | Matrix stabilization must fold into the acquisition transaction when possible or run through a deferred guarded post-commit command. | Opening nested SaveTransactions synchronously inside post-commit signal handlers. |
| CM-MAP-07 | Keep OQ-SH01 open until `docs/balance/economy-content-lock.md` validates at least 200 Scraps surplus on the Act 3 critical path above normal consumable spend. | Finalizing `BOSS_SCRAP_BONUS` or `HAZARD_SCRAP_BONUS` from provisional estimates. |

## Economy And Shop

| ID | Required | Forbidden |
|---|---|---|
| CM-ECO-01 | Mutate `player_scraps` only through `EconomyLedger.add_scraps()` or `EconomyLedger.spend_scraps()` inside a SaveTransaction. | Direct `player_scraps +=` or `player_scraps -=` from feature systems. |
| CM-ECO-02 | Mutate expedition item flags only through source-specific `ExpeditionInventoryLedger` helpers. | Direct writes to `expedition_*` flags from Shop, Campaign Map, Battle, or Singularity code. |
| CM-ECO-03 | Shop purchases must deduct Scraps and set the relevant flag in one atomic transaction. | Partial purchase states where Scraps changed but flag did not, or flag changed but Scraps did not. |
| CM-ECO-04 | ShopService receives SaveService, catalog, EconomyLedger, and ExpeditionInventoryLedger through explicit setup or dependency injection. | Hardcoded `/root` singleton lookup inside Shop purchase logic. |
| CM-ECO-05 | Relic ownership flags are one-way; Shop is the sole normal writer. | Crown purchases, discounted relics, emergency grants, relic consumption, or relic resets. |
| CM-ECO-06 | Post-ending unowned relic lockout is presentation/read-only behavior. | Mutating relic flags to create post-ending shop presentation. |

## Singularity

| ID | Required | Forbidden |
|---|---|---|
| CM-SING-01 | Route Matrix stabilization activation into `SingularityService.activate_from_matrix()` after Campaign Map commit success. | Treating repeated Matrix signals as duplicate activation or duplicate Spine placement. |
| CM-SING-02 | Mutate `corruption_class` and `scar_nodes[]` together in one SaveTransaction. | Committing corruption class without the matching cumulative SCAR list. |
| CM-SING-03 | Set gatekeeper defeated flags only through Singularity first-clear settlement. | Campaign Map or Battle Engine writing `gatekeeper_[id]_defeated`. |
| CM-SING-04 | Commit CRITICAL/BREACH Mirror Admin phase advances only with matching phase checkpoint data. | Reloading to stale pre-boss state after durable mid-fight corruption commits. |
| CM-SING-05 | Grant Void through Dragon Progression story-grant helper in the same transaction as `mirror_admin_defeated`. | Separate commits where Mirror Admin is defeated but Void is absent, or Void exists without defeat flag. |
| CM-SING-06 | Resolve Crown endings by reading Shop relic flags and writing only `ending_id`. | Crown selling/granting relics, mutating relic flags, deducting Scraps, or serializing `game_state`. |
| CM-SING-07 | Treat gatekeeper replay as non-milestone replay. | Re-advancing corruption, rewriting first-clear flags, re-granting Void, or re-emitting first-time milestone signals. |

## Corruption Rendering

| ID | Required | Forbidden |
|---|---|---|
| CM-RENDER-01 | Apply corruption profiles through `CorruptionPresentationService` from committed Singularity state or save snapshots. | Gameplay systems directly mutating rendering materials or compositor effects. |
| CM-RENDER-02 | Keep UI/HUD text, focus rings, labels, and confirm/cancel affordances above world corruption effects. | Global filters that reduce required UI contrast/readability. |
| CM-RENDER-03 | Use authored `CorruptionVisualProfile` and `PostGameVisualProfile` Resources with boot/content validation. | Scattered hardcoded shader IDs and unvalidated profile names. |
| CM-RENDER-04 | Use Godot Compositor/CompositorEffect for screen-wide corruption post-processing where required. | Ad hoc manual viewport post-process chains for MVP corruption effects. |
| CM-RENDER-05 | Apply restored gold-code as a sprite/entity overlay after shiny tint and before UI labels. | Treating restored gold-code as a stat effect or replacing shiny/readability markers. |
| CM-RENDER-06 | Provide reduced-motion and reduced-flash variants for corruption, Hatchery reveal, and full-screen pulses. | Audio-only or color-only communication of corruption, Counter readiness, SCAR, or ending state. |
| CM-RENDER-07 | Distinguish rendering method from graphics backend: Forward+ is the primary desktop method, Windows backend defaults must be verified, and any required Vulkan pin must be explicit in `project.godot` with QA evidence. | Treating Forward+, Vulkan, D3D12, and Compatibility as interchangeable renderer labels. |

## Hatchery

| ID | Required | Forbidden |
|---|---|---|
| CM-HATCH-01 | Execute egg pulls through `HatcheryService.execute_pull()` using one SaveTransaction. | UI code spending Scraps, rolling RNG, or mutating pity counters directly. |
| CM-HATCH-02 | Use injected or transaction-scoped RNG with deterministic test seams. | Global `randi()`, `randf()`, or scattered random calls for pull outcomes. |
| CM-HATCH-03 | Stage Scrap spend, pity updates, dragon creation or duplicate XP, and hatch events atomically. | Partial outcomes where Scraps spend without a dragon/pity result, or dragon creation commits without spend. |

## Fusion

| ID | Required | Forbidden |
|---|---|---|
| CM-FUSION-01 | Generate preview and commit values through the same FusionService formula path. | Duplicating fusion formulas in UI preview code. |
| CM-FUSION-02 | Commit child creation and parent retention/removal in one SaveTransaction through DragonProgressionService helpers. | Separate commits for child creation and parent mutation. |
| CM-FUSION-03 | Return named `FusionPreviewResult` and `FusionCommitResult` types. | Anonymous dictionaries for Fusion preview or commit contracts. |

## Journal And Console

| ID | Required | Forbidden |
|---|---|---|
| CM-JOURNAL-01 | Own `journal_unlocked_ids[]`, `journal_read_ids[]`, and `terminal_read_ids[]` in JournalService. | Campaign Map, Singularity, Battle, or Audio mutating Journal read state directly. |
| CM-JOURNAL-02 | Unlock lore from post-commit semantic milestones and emit Journal events only after Journal commit success. | Unlocking lore from pre-commit gameplay state or display text. |
| CM-JOURNAL-03 | Use stable fragment and terminal IDs backed by authored JournalLibrary Resources. | Keying Journal logic off localized/prose text. |

## Audio Director

| ID | Required | Forbidden |
|---|---|---|
| CM-AUDIO-01 | Route music, SFX, corruption mix, and tritone cues through AudioDirectorService. | Gameplay systems instantiating or controlling AudioStreamPlayers directly. |
| CM-AUDIO-02 | Treat audio completion as presentation telemetry only. | Blocking gameplay progression on `audio_event_finished()`, audible playback, or unmuted buses. |
| CM-AUDIO-03 | Use AudioLibrary Resources with validated required cue IDs, optional fallback cues, and pool limits. | One-off hardcoded audio paths or unbounded overlapping SFX instances. |

## Story Checklist

Every implementation story should answer these checks before development starts:

1. Which system owns every durable field this story reads or writes?
2. Does any state change need a `SaveTransaction`?
3. Which semantic events are emitted, and do any require commit-before-emit ordering?
4. Does the feature remain completable with d-pad plus confirm/cancel where player-facing?
5. Are all implementation-facing content IDs backed by typed Resources or approved GDD tables?
6. Does the story avoid blocked tuning decisions, especially Shop OQ-SH01?
7. Does the story respect SceneFlow, DragonProgressionService, and Battle settlement ownership instead of writing across boundaries?
8. Does the story use Campaign Map, EconomyLedger, and ExpeditionInventoryLedger helpers for rewards, currency, and expedition flags?
9. Does the story keep Singularity-owned endgame fields behind SingularityService settlement APIs?
10. Does any corruption/post-game visual work remain presentation-only and preserve HUD accessibility?
11. Does any Hatchery, Fusion, Journal, or Audio work follow ADR-0012 through ADR-0015 before implementation?
12. If the story touches Battle content, does its `BattleDefinition` resolve a valid `BattleAnimationManifest` for every required `MoveDefinition` and actor action?

## Known Gaps

- Shop OQ-SH01 remains open until authored Campaign Map Act 3/4 node distribution and economy playtest/simulation data prove at least 200 Scraps surplus above normal consumable spend on the Act 3 critical path.
- Armor System still needs a GDD before architecture coverage is complete.
- Singularity boss stories must use the ADR-0007/ADR-0010 phase-checkpoint model unless the Singularity GDD/ADR is changed to defer CRITICAL/BREACH durable commits until final settlement.
- Corruption rendering stories must follow ADR-0011 and capture screenshot/performance/accessibility evidence before visual acceptance.
- Hatchery, Fusion, Journal, and Audio implementation stories must follow ADR-0012 through ADR-0015.
- Battle content stories must use `docs/architecture/battle-animation-manifest-schema.md`; placeholder animation bindings are allowed only for explicit greybox scope.
