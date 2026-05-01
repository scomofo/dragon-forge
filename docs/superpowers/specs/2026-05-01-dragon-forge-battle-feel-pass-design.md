# Dragon Forge Battle Feel Pass Design

## Purpose

Dragon Forge should feel closer to a premium 1991 NES hit during its most repeated interaction: choosing a move and watching a turn resolve. The battle rules stay turn-based and menu-driven. The improvement is presentation, rhythm, and readability: a normal attack should feel fast, deliberate, and satisfying without adding reflex timing or changing combat balance.

The target is "instant fun per input." If someone watches one turn with sound off, they should still understand who attacked, whether it hit, how big the result was, and whether something special happened.

## Scope

This pass improves battle feel only. It does not add active timing, blocking, new stats, new move effects, or broad rebalance work.

The pass has five pillars:

1. Attack cadence: shorten dead air and give every move a sharper launch-impact-recover rhythm.
2. Impact language: strengthen hit-stop, shake tiers, flashes, sprite recoil, and damage number choreography.
3. Result clarity: make crits, effectiveness, misses, status, reflect, and KO visibly distinct without relying on the battle log.
4. Enemy personality: give enemy attacks clearer tells and different visual weight by move or element.
5. Victory and defeat flourish: make battle endings feel like punctuation instead of simple state changes.

## Architecture

`battleEngine.js` remains the source of combat truth. It resolves turn outcomes, damage, statuses, misses, critical hits, KO state, and reward logic. Presentation improvements live around:

- `src/BattleScreen.jsx`
- `src/animationEngine.js`
- `src/VfxOverlay.jsx`
- `src/DamageNumber.jsx`
- `src/styles/battle.css`

The main addition is a small battle presentation profile layer. Instead of scattering hardcoded timing, CSS class, and sound decisions through `BattleScreen.jsx`, resolved turn events map to presentation profiles such as:

- `miss`
- `resistedHit`
- `normalHit`
- `effectiveHit`
- `criticalHit`
- `statusApply`
- `reflect`
- `ko`

Each profile defines the presentation values needed by BattleScreen:

- anticipation duration
- launch duration
- impact pause duration
- recovery duration
- shake strength
- flash class
- attacker sprite class
- defender sprite class
- damage number style
- sound cue names
- log reveal timing

BattleScreen sequences a turn by asking for the profile for each resolved event, then applying that profile to sprites, VFX, damage numbers, sounds, shake, and log updates. This keeps the RPG math stable while making feel easier to tune.

## Player-Facing Behavior

### Move Acceptance

When a move is selected, the selected button briefly locks or highlights and unavailable buttons dim while the turn resolves. The command should feel accepted immediately. The battle log should avoid competing for attention until the action beat has landed.

### Attack Anticipation

Every attack gets a short tell before launch. Light attacks should snap quickly. Heavy or high-power attacks should get a slightly stronger wind-up. Enemy attacks should be just as readable as player attacks.

Misses still show launch motion, but the impact beat becomes a clear whiff rather than a weak hit.

### Hit Tiers

Result types should have distinct visual grammar:

- Resisted hit: smaller shake, muted flash, smaller damage number.
- Normal hit: standard flash, standard recoil, readable damage number.
- Super-effective hit: stronger flash, stronger shake, brighter damage number.
- Critical hit: larger pop, stronger impact pause, distinct crit marker.
- Reflect: shield-like or rebound cue, damage number style that separates it from direct attacks.
- Status apply: separate status badge or aura cue, not just a log line.
- KO: defender collapse, flicker, or fade with a slightly longer punctuation beat.

### Damage Numbers

Damage numbers should communicate result quality:

- Low or resisted damage uses a smaller, subdued style.
- Normal damage uses the current readable style.
- Effective damage uses a stronger color and rise motion.
- Critical damage uses a larger pop and short linger.
- Status and reflect use separate badge-like markers rather than pretending to be normal damage.

### Victory and Defeat

Victory should include a quick enemy collapse or flicker, reward count-up, and a small dragon celebration pose or bounce. Defeat should include a clear dragon knockdown or fade and a short recovery option. Battle endings should feel like deliberate punctuation before navigation resumes.

## Data Flow

The intended flow is:

1. `battleEngine.resolveTurn()` produces deterministic combat events.
2. `BattleScreen` receives each event.
3. A presentation helper classifies the event as `miss`, `resistedHit`, `normalHit`, `effectiveHit`, `criticalHit`, `statusApply`, `reflect`, or `ko`.
4. The helper returns a profile object.
5. BattleScreen uses that profile to drive sprite classes, VFX overlay, damage numbers, sounds, screen shake, battle log timing, and phase transitions.

The profile helper should be deterministic and testable. It should not inspect DOM state, run timers, play sounds, or mutate battle state. BattleScreen remains responsible for applying the profile over time.

## Testing

Automated tests should focus on deterministic classification and reducer behavior:

- Miss events choose the `miss` profile.
- Critical hit events choose the `criticalHit` profile.
- Super-effective and resisted hits choose distinct profiles.
- Reflect events choose the `reflect` profile.
- Status application chooses a status presentation profile or marker.
- KO events choose the `ko` profile.
- Battle reducer transient presentation state can be set and cleared without corrupting existing battle phase.

Existing combat engine tests must keep passing unchanged. This pass should not require changing expected combat math.

Manual smoke testing should cover:

- Start a standard NPC battle.
- Select a basic attack and observe command acceptance, launch, hit, damage, and recovery.
- Select an elemental move and verify stronger result readability.
- Observe at least one miss, crit, status, or reflect when practical.
- Win a battle and verify victory flourish plus reward clarity.
- Lose or force a defeat path when practical and verify defeat readability.

## Rollout

Implementation should land in three chunks:

1. Extract presentation profile helpers and tests.
2. Wire profiles into attack sequencing, VFX, damage numbers, sound cues, and CSS classes.
3. Polish victory and defeat endings, then run automated tests and a manual battle smoke pass.

This sequencing keeps the first change testable without touching the visible battle flow, then lets presentation work build on the helper instead of adding more one-off timing logic to BattleScreen.

## Non-Goals

- No active timing bonus.
- No blocking or parry mechanic.
- No combat rebalance.
- No new dragon or NPC content.
- No broad UI redesign outside the battle screen.
- No change to save data format unless a small presentation preference becomes necessary.
