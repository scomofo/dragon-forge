# Battle Animation Coverage Plan

> **Status**: Required carry-forward from vertical slice Revision 4S
> **Date**: 2026-05-26
> **Source evidence**: `prototypes/dragon-forge-vertical-slice` Revision 4S
> **Purpose**: Prevent production battle animation from regressing into shared placeholders. Every attack and defensive action must have its own readable animation sprite set for every dragon, NPC, and boss.

## Decision

The Revision 4S vertical-slice pass proved the requirement: named combat actions are not legible enough when they share one generic attack strip. Production must treat animation coverage as content, not polish.

Every battle-capable actor requires a complete action animation manifest before its encounter is implementation-ready. Reusing one generic attack across multiple moves is allowed only as a temporary greybox placeholder and must be marked `placeholder` in the manifest.

## Scope

Required combatant families:

| Family | Required Coverage |
|---|---|
| Core dragons | Fire, Ice, Storm, Stone, Venom, Shadow |
| Story dragon | Void |
| Fused / Elder dragons | Inherit base element coverage only as a placeholder; need distinct Elder overlays before production art lock |
| Standard NPC dragons/enemies | Every authored enemy encounter |
| Support NPC enemies | Logic Bomb, Recursive Golem, and any similar support threat that can act or visibly telegraph |
| Singularity bosses | Three gatekeepers and Mirror Admin phase profiles |

Required action classes:

| Class | Examples / Source | Coverage Rule |
|---|---|---|
| Basic attack | Element's reliable 100% move, such as Flame Wall / Frost Bite / Thunder Clap / Acid Spit | Unique strip per element and actor silhouette |
| Heavy attack | Magma Breath, Blizzard, Lightning Strike, Rock Slide, Earthquake, Toxic Cloud, Shadow Strike, Radiant Beam, Void Pulse | Unique strip per move, not just a bigger basic attack |
| Status move | Burn, Freeze, Paralyze, Guard Break, Poison, Blind | Unique status application VFX and attacker motion per element |
| Defend | Battle Engine Defend action | Unique guard stance, guard hit, and cooldown-disabled UI signal per actor family |
| Consumable action | Defrag Patch in TELEGRAPH | Shared item-use strip is acceptable, but receiving dragon needs a status-clear reaction |
| Hit / recoil | IMPACT / RECOIL phase | Unique hurt/recoil per actor silhouette; can be shared across damage sources for the same actor |
| KO / collapse | RESOLUTION phase | Unique collapse/decompile per actor family |
| Boss special | Mirror Admin tritone Counter, phase swaps, gatekeeper scripts | Bespoke strip per named boss action |

## Minimum Sprite Set Per Combatant

Each battle-capable actor must provide:

| Asset | Frames | Notes |
|---|---:|---|
| `idle` | 4 | Looping battle idle; bottom-center anchored |
| `telegraph` | 4 | Intent read / windup signal; does not obscure UI telegraph |
| `attack_basic` | 6 | Reliable action strip |
| `attack_heavy_[move_id]` | 6-8 | Heavier move-specific strip |
| `status_[status_id]` | 6 | Status application strip, plus VFX |
| `defend_start` | 4 | Guard stance / shield / brace |
| `defend_hit` | 4 | Impact while defending |
| `hurt` | 4 | Non-defending hit reaction |
| `ko` | 6 | Collapse, deletion, or stabilization outcome |
| `victory_settle` | 4 | Optional for player dragons; required for bosses if authored |

## Technical Rules

- Generate each strip from an approved in-game seed frame for that actor.
- Generate the whole strip together to preserve silhouette, palette, facing direction, and proportions.
- Normalize all frames to a fixed transparent slot and a shared bottom-center anchor.
- Use one frame cadence per move class unless a boss action explicitly needs more frames.
- At gameplay scale, the move must read without relying on the banner text.
- VFX must not obscure HP bars, TELEGRAPH markers, or button prompts.
- Reduced-motion mode may shorten or crossfade strips, but must not replace them with static text.
- Every strip needs a preview sheet and at least one in-engine screenshot capture.

## Naming Pattern

Use stable IDs so authored `MoveDefinition` resources can bind animations without code-specific branches:

```text
actors/{actor_id}/battle/{action_id}_{frame_index}.png
actors/{actor_id}/battle/vfx_{action_id}.png
actors/{actor_id}/battle/preview_{action_id}.png
```

Examples:

```text
actors/root_wyrmling/battle/root_spark_0.png
actors/root_wyrmling/battle/thorn_surge_0.png
actors/root_wyrmling/battle/guarded_spark_0.png
actors/admin_protocol/battle/data_leak_0.png
```

The current vertical-slice filenames under `prototypes/dragon-forge-vertical-slice/assets/slice/` are prototype-local exceptions. Production stories should use the actor/action pattern above.

## Element Direction

| Element | Attack Shape Language | Defense Shape Language | Status VFX |
|---|---|---|---|
| Fire | Upward flame horns, ember arcs, hot orange/yellow impact tongues | Ember wall / heat shimmer shell | Burn: orange ember licks and brief ash pixels |
| Ice | Crystalline facets, downward points, compact snap impacts | Faceted frost plate / cold storage pane | Freeze: pale cyan lock crystals and slowed frame cadence |
| Storm | Jagged fins, lightning zigzags, long directional lines | Split-bolt cage / charged parry | Paralyze: branching cyan/gold arcs and stuttered recoil |
| Stone | Blocky mass, broad stance, heavy ground lift | Plated brace / slab shield | Guard Break: cracked DEF glyph, falling stone chips |
| Venom | Curved spines, hooked tail, asymmetrical splashes | Coiled thorn/venom membrane | Poison: green-violet droplets and lingering bubbles |
| Shadow | Narrow silhouette, broken edges, cloak-like wings | Dark veil with magenta edge noise | Blind: black/magenta eye-scramble and missing pixels |
| Void | Negative-space gaps, unstable outline, anti-symmetry | Absence ring / inverted shell | Void Pulse: white/cyan null gaps with controlled magenta pressure |

## Current Vertical Slice Coverage

| Actor | Action | Status |
|---|---|---|
| Root Wyrmling | Idle | Present, prototype-quality |
| Root Wyrmling | Root Spark | Present, Revision 4S distinct strip |
| Root Wyrmling | Thorn Surge | Present, Revision 4S distinct strip |
| Root Wyrmling | Guarded Spark / Defend | Present, Revision 4S distinct strip |
| Root Wyrmling | Hurt / KO / victory settle | Missing dedicated strips |
| Admin Protocol | Idle | Present, prototype-quality |
| Admin Protocol | Data Leak | Present, Revision 4S distinct strip |
| Admin Protocol | Defend / hurt / KO | Missing dedicated strips |
| Logic Bomb / Recursive Golem | Background presence only | No action coverage yet |

## First Authored Manifest Fixture

`assets/battle/animation_manifests/root_wyrmling_vs_admin_protocol.tres` is the first real content fixture for this schema. It binds:

- Root Wyrmling: Root Spark, Thorn Surge, Guarded Spark, idle, telegraph, hurt, defend-start, defend-hit, KO.
- Admin Protocol: Data Leak, idle, telegraph, hurt, defend-start, defend-hit, KO.
- VFX: Root Spark, Thorn Surge, Guarded Spark, Shadow Burst.
- Evidence: per-action preview sheets plus runtime captures from `assets/battle/runtime_captures/village_edge_admin_protocol/`.

The named attack strips are the distinct approved Revision 4S assets. The base reaction clips now use dedicated generated telegraph, hurt, defend-start, defend-hit, and KO strips derived from approved Root/Admin seed frames. This closes the prior copied-frame coverage gap for the fixture; broader human art-direction review is still required before production art lock.

The standalone vertical slice now mirrors this fixture under `prototypes/dragon-forge-vertical-slice/assets/battle/` and resolves battle presentation keys from the manifest at runtime. The mirror uses prototype-local Resource scripts to keep the slice self-contained without duplicating root-project Godot `class_name` registrations.

## Production Gate

A combat story is not ready for implementation unless it includes:

1. An actor/action animation manifest listing every required strip.
2. Approved seed frames for every actor in the encounter.
3. Preview sheets for each generated strip.
4. Runtime screenshot evidence for every attack, defense, status, and KO beat used by that encounter.
5. Accessibility check: no strip relies on color alone, and reduced-motion behavior is defined.

## Next Work Order

1. Done: create the production `BattleAnimationManifest` schema and initial Godot Resources / validator alongside `MoveDefinition` and `BattleDefinition`. See `docs/architecture/battle-animation-manifest-schema.md` and `src/battle/`.
2. Done: build the first real coverage set for one core dragon and one standard NPC: idle, telegraph, basic, heavy, defend, defend-hit, hurt, KO, VFX, preview sheets, and runtime captures.
3. Then scale horizontally by element, not by encounter: finish Fire/Ice/Storm/Stone/Venom/Shadow/Void base action families before authoring large encounter batches.
4. Reserve bespoke boss-action strips for Singularity gatekeepers and Mirror Admin after the core element grammar is approved.
