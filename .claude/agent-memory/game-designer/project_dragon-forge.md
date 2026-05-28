---
name: project-dragon-forge
description: Dragon Forge game concept, emotional arc, design pillars, and current GDD status — foundational context for all design work
metadata:
  type: project
---

Dragon Forge is a 16-bit cyber-retro dragon-collecting RPG built in Godot 4.6 (GDScript). Six elemental guardian protocols (Fire, Ice, Storm, Stone, Venom, Shadow) plus a Void endgame unlock. Core loops: Hatch → Forge → Battle → Explore → Stabilize.

**Emotional arc**: Wonder → Attachment → Urgency → Dread → Agency.

**Design conceit**: Dragons are not growing — they are "uncapping." Leveling earns the dragon's trust to reveal what it always was. Stage thresholds are meant to feel like reveals, not rewards.

**Why:** This framing is baked into the Player Fantasy sections of multiple approved GDDs (dragon-progression.md, hatchery.md). Mechanical choices must be read against it — anything that makes the dragon feel like it is literally getting stronger contradicts the lore.

**How to apply:** When evaluating progression or combat mechanics, always check whether the mechanic can be framed as "earning trust" vs. "gaining power." If the math says one thing and the lore says another, surface the conflict explicitly.

## GDD Status (as of 2026-05-21)
- Battle Engine: Approved
- Hatchery: Approved
- Fusion Engine: Designed
- Dragon Progression: In Design (Detailed Design section not yet written — review requested before drafting)
- Dragon Forge Hub: Designed
- Campaign Map: Designed
- Singularity: Designed
- Armor System: Designed
- Mirror Admin: Designed
- Shop: Designed
- Journal/Console: Designed
- Save/Persistence: Designed
- Audio Director: Designed
- Input Router: Designed

## Key locked constraints (Battle Engine, Approved)
- Stat scaling formula: `floor((baseStat + (level − 1) × 3) × shinyMult)`
- Damage formula: `baseDamage = (ATK × stageMult × 1.5) − (DEF × 0.5)`
- Stage multipliers: 0.5× / 0.75× / 1.0× / 1.4×
- Stage thresholds: 1–9 / 10–24 / 25–49 / 50+
- XP_PER_LEVEL = 100 (flat)
- MAX_LEVEL = 60

## Open design questions (flagged in adversarial review 2026-05-21)
- SPD stat has no combat mechanic — must define or remove from visible stat block before Detailed Design
- Stage IV (levels 50–60, 1,000 XP) is mechanically shorter than Stage III (25 levels, 2,500 XP) — inverts intended emotional weight
- No mechanism prevents Stage IV grind before Singularity arc — Campaign Map zone gating is the only safeguard but not yet locked
- Flat XP curve produces no felt escalation across 60 levels — Stage II→III drag (25 levels) will feel like a plateau
- Stage boundary damage cliffs (up to 59% jump at level 9→10) exploitable if no Campaign Map level gates
- "Uncapping" narrative frame conflicts with half-damage Stage I combat reality
- Hatchery duplicate XP (50/100/150) not level-normalized; late-game duplicate pulls are disproportionately powerful
