# Requirements Traceability Matrix

> Last Updated: 2026-05-26
> Mode: /architecture-review full
> Scope: 15 design docs in `design/gdd/`, 15 ADRs, master architecture, control manifest, architecture registry, Godot 4.6 reference docs, and technical preferences.

## Coverage Summary

| Status | Count | Percent |
|---|---:|---:|
| Covered | 38 | 97.4% |
| Partial | 1 | 2.6% |
| Gap | 0 | 0.0% |
| Total requirements | 39 | 100% |

## Full Traceability Matrix

| TR-ID | GDD | System | Requirement | ADR Coverage | Status |
|---|---|---|---|---|---|
| TR-save-001 | save-persistence.md | Save / Persistence | Typed SaveData durable state. | ADR-0001 | Covered |
| TR-save-002 | save-persistence.md | Save / Persistence | Atomic staged transactions with rollback. | ADR-0001 | Covered |
| TR-save-003 | save-persistence.md | Save / Persistence | Commit-state signals after save commit success. | ADR-0001, ADR-0002 | Covered |
| TR-input-001 | input-router.md | Input Router | Semantic hardware-to-action routing. | ADR-0003 | Covered |
| TR-input-002 | input-router.md | Input Router | D-pad plus confirm/cancel completion paths. | ADR-0003, ADR-0005 | Covered |
| TR-input-003 | input-router.md | Input Router | Godot 4.6 dual-focus handling. | ADR-0003, ADR-0005 | Covered |
| TR-data-001 | systems-index.md | Authored Data | Stable cross-system content as typed Resources/tables. | ADR-0004 | Covered |
| TR-data-002 | campaign-map.md | Campaign Map | Fixed authored node graph. | ADR-0004, ADR-0008 | Covered |
| TR-data-003 | singularity.md | Singularity | Stable SCAR, boss, phase, ending, and terminal IDs. | ADR-0004, ADR-0010 | Covered |
| TR-dragon-001 | dragon-progression.md | Dragon Progression | Canonical dragon schema, stats, stage, charges, Elder flag. | ADR-0006 | Covered |
| TR-dragon-002 | dragon-progression.md | Dragon Progression | XP/stat/creation APIs across dependent systems. | ADR-0006, ADR-0010 | Covered |
| TR-dragon-003 | dragon-progression.md | Dragon Progression | Progression event timing compatible with save commits. | ADR-0001, ADR-0002, ADR-0006 | Covered |
| TR-hatch-001 | hatchery.md | Hatchery | Pull rates, pity, soft pity, shiny, duplicate XP. | ADR-0004, ADR-0006, ADR-0009, ADR-0012 | Covered |
| TR-hatch-002 | hatchery.md | Hatchery | Atomic pull economy, dragon creation, pity, duplicate XP. | ADR-0001, ADR-0006, ADR-0009, ADR-0012 | Covered |
| TR-fusion-001 | fusion-engine.md | Fusion Engine | Fusion formulas and Elder generation. | ADR-0006, ADR-0013 | Covered |
| TR-fusion-002 | fusion-engine.md | Fusion Engine | Atomic child creation and parent rules. | ADR-0001, ADR-0006, ADR-0013 | Covered |
| TR-battle-001 | battle-engine.md | Battle Engine | Five-phase battle loop. | ADR-0007 | Covered |
| TR-battle-002 | battle-engine.md | Battle Engine | Battle formulas and Elder multiplier branch. | ADR-0006, ADR-0007 | Covered |
| TR-battle-003 | battle-engine.md | Battle Engine | Typed runtime result/presentation payloads, no durable reward commit. | ADR-0002, ADR-0007, ADR-0008, ADR-0009, ADR-0010 | Covered |
| TR-map-001 | campaign-map.md | Campaign Map | Expedition party, node state, final XP/reward settlement. | ADR-0008, ADR-0009 | Covered |
| TR-map-002 | campaign-map.md | Campaign Map | REST, defeat, replay, HAZARD, MAP_EXPLORE consumables. | ADR-0008, ADR-0009, ADR-0010 | Covered |
| TR-map-003 | campaign-map.md | Campaign Map | Matrix stabilization and Spine unlock handoff. | ADR-0008, ADR-0010 | Covered |
| TR-map-004 | campaign-map.md | Campaign Map | Read Singularity state without mutating it. | ADR-0008, ADR-0010, ADR-0011 | Covered |
| TR-shop-001 | shop.md | Shop | Purchases, catalog, relic flags, Unit 01 flow. | ADR-0009 | Covered |
| TR-shop-002 | shop.md | Economy | Scrap mutation through EconomyLedger, no negative balance. | ADR-0009 | Covered |
| TR-shop-003 | shop.md | Expedition Inventory | Source-specific expedition item flag mutation. | ADR-0008, ADR-0009, ADR-0010 | Covered |
| TR-shop-004 | shop.md | Economy | OQ-SH01 remains provisional until economy-content lock evidence. | ADR-0004, ADR-0008, ADR-0009 | Covered |
| TR-sing-001 | singularity.md | Singularity | Own corruption, SCAR, bosses, Void grant, ending_id. | ADR-0001, ADR-0002, ADR-0007, ADR-0008, ADR-0009, ADR-0010 | Covered |
| TR-sing-002 | singularity.md | Singularity / Crown | Crown ending flow from Shop relic flags, no Crown purchases. | ADR-0009, ADR-0010 | Covered |
| TR-sing-003 | singularity.md | Mirror Admin | Continuous three-phase encounter and checkpoint-safe corruption. | ADR-0007, ADR-0010 | Covered |
| TR-sing-004 | singularity.md | Void Dragon | Reserved Void grant identity and story slot. | ADR-0006, ADR-0010 | Covered |
| TR-sing-005 | singularity.md | Rendering / Presentation | Corruption and post-game rendering/accessibility constraints. | ADR-0011 | Covered |
| TR-journal-001 | journal.md | Journal / Console | Lore unlocks and terminal read state from milestones. | ADR-0001, ADR-0002, ADR-0004, ADR-0010, ADR-0014 | Covered |
| TR-journal-002 | journal.md | Journal / Console | Stable fragment/terminal content IDs and atomic read state. | ADR-0001, ADR-0004, ADR-0010, ADR-0014 | Covered |
| TR-audio-001 | audio-director.md | Audio Director | Semantic event subscription, buses, mix, tritone cues, no gameplay authority. | ADR-0002, ADR-0010, ADR-0011, ADR-0015 | Covered |
| TR-audio-002 | audio-director.md | Audio Director | Audio never blocks gameplay. | ADR-0002, ADR-0005, ADR-0015 | Covered |
| TR-hub-001 | dragon-forge-hub.md | Dragon Forge Hub | Hub stations, presentation, roster, Felix, Save Lantern, Bulkhead. | ADR-0003, ADR-0005, ADR-0008, ADR-0009 | Partial |
| TR-hub-002 | dragon-forge-hub.md | Dragon Forge Hub / Save | Non-blocking Save Lantern with responsive navigation. | ADR-0001, ADR-0005 | Covered |
| TR-hub-003 | dragon-forge-hub.md | Dragon Forge Hub / Scene Flow | Focus, station, Bulkhead transition safety. | ADR-0003, ADR-0005 | Covered |

## Remaining Partial Coverage

| Priority | Requirement | Issue | Suggested Action |
|---|---|---|---|
| Low | TR-hub-001 | Hub is bounded by Scene Flow/Input/Save/Economy ADRs, but Felix ambient presentation and full station composition do not have a dedicated presentation ADR. | Accept as story-level design unless Hub implementation reveals hidden cross-system ownership. |

## Known Gaps

None. The previous TR-sing-005 corruption rendering gap is covered by ADR-0011.

## Story And Test Linkage

No `production/epics/**/*.md` story files are present yet. Automated test infrastructure now exists and the example GUT test passes, but full GDD -> ADR -> Story -> Test chain coverage remains 0/39 until epics and stories are created in Pre-Production.
