# Cross-GDD Review — 2026-05-26

## Scope

Reviewed Dragon Forge's approved MVP/supporting GDD set after Singularity and the four support contracts were approved.

System GDDs reviewed:

- `battle-engine.md`
- `campaign-map.md`
- `dragon-forge-hub.md`
- `dragon-progression.md`
- `fusion-engine.md`
- `hatchery.md`
- `shop.md`
- `singularity.md`
- `save-persistence.md`
- `audio-director.md`
- `input-router.md`
- `journal.md`

Specialist delegation:

- Cross-GDD consistency: systems-designer
- Holistic game design: game-designer
- Registry consistency: qa-lead

## Verdict

**CONCERNS — mechanical contradictions resolved in-session; production readiness still needs economy/content validation.**

The cross-document design is now coherent enough to continue architecture work, but it is not ready for production balance lock. The remaining issues are primarily validation and content-data readiness rather than contradictory rules.

## Required Revisions Applied

1. **Elder multiplier contract propagated to Battle Engine**
   - `battle-engine.md` now defines Elder Stage IV as `ELDER_STAGE_MULT = 1.75` when `is_elder = true` and level is 50+.
   - Battle Engine ACs now cover the Elder branch.
   - Dragon Progression ACs now clarify that 1.4x is the standard non-Elder Stage IV multiplier.

2. **Dragon record schema aligned**
   - `dragon-progression.md` now lists `base_hp`, `base_atk`, `base_def`, `base_spd`, and `is_elder` in the dragon data contract.
   - Fusion remains the writer of inherited base stats and `is_elder`; Dragon Progression owns the schema/serialization expectations.

3. **Battle reward payload clarified**
   - Battle Engine now emits `raw_xp_awarded` and `scraps_earned`.
   - Campaign Map owns over-level XP decay, final `xp_earned`, Scrap increment, and Dragon Progression `apply_xp()` call.

4. **Campaign Map updated for Shop consumables**
   - Added MAP_EXPLORE rules/ACs for Cache Shard and Emergency Patch.
   - Added reset rule/AC for all four `expedition_*` flags on Bulkhead departure and defeat-return.

5. **`ending_id` ownership corrected**
   - Campaign Map now reads Singularity-owned `ending_id`; it does not write it.
   - Save/Persistence and Singularity remain authoritative for ending commit.

6. **Stale labels and stale wording cleaned**
   - Dragon Progression header now matches its Approved review state.
   - Campaign Map dependency statuses now reflect approved Singularity/Journal/Save/Audio GDDs.
   - Hub OQ-HUB-01 is marked resolved.
   - Hatchery no longer references obsolete flat XP or rest-charge terminology.
   - Shop Defrag Patch wording now matches Battle Engine single-slot status.

7. **Registry drift corrected**
   - Entity registry now uses `battle_charges`, correct `is_elder` semantics, Battle Engine damage formula, and Fusion stat inheritance without an Elder stat multiplier.

## Remaining Production Concerns

### Economy Readiness

Shop OQ-SH01 remains open. The integrated Scrap economy still needs authored Campaign Map node distribution and playtest/simulation data before `BOSS_SCRAP_BONUS` and `HAZARD_SCRAP_BONUS` can be finalized.

Recommended artifact before balance lock:

- Expected Scraps by act
- Required Hatchery pulls with soft pity
- Normal Field Kit / consumable spend
- Relic affordability
- Boss/HAZARD bonus tuning
- Farming tolerance target

### Content Data Lock

Implementation can proceed on architecture, but production planning needs a content lock artifact for:

- Campaign Map node table
- Encounter/reward table
- HAZARD status assignments
- Boss definition resources
- SCAR node/protected-node validation
- Lore fragment stubs and terminal entries

### Design Risks To Validate

- Single-active-dragon carry may dominate broad roster play.
- Cross-element Fusion may be dominated by same-element Fusion unless its narrative/challenge role is intentional or it receives a compensating benefit.
- Expedition attention budget is high; corruption, Journal, and SCAR should remain mostly passive until late-game onboarding proves otherwise.

## Clean Findings

- Singularity, Shop, and Save/Persistence now align on no emergency Crown relics and `ending_id` as the only post-game authority.
- Matrix stabilization is coherent across Campaign Map, Hatchery, Singularity, and Journal.
- Support GDDs are approved and referenced consistently.
- Armor System is correctly treated as Supporting/Not Started; concept AC was clarified so it does not block MVP production gates.

## Next Recommendation

Run `/create-architecture` after deciding whether to create the economy/content lock artifact first. Architecture can proceed, but production sprint planning should not treat economy/content data as complete.
