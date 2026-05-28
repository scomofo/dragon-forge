# Art Bible: Dragon Forge

> **Status**: In Design
> **Author**: Scott + art-director
> **Last Updated**: 2026-05-26
> **Template**: Art Bible
> **Scope Completed**: Sections 1-4, Visual Identity Foundation
> **Art Director Sign-Off (AD-ART-BIBLE)**: Lean mode sign-off deferred

---

## 1. Visual Identity Statement

Dragon Forge looks like a warm 16-bit pastoral RPG being visibly debugged by ancient machinery: every comforting fantasy shape has a diagnostic shadow, and every glitch reveals structure rather than random noise.

**Principles**

- **Cozy surface, exposed system**: The world must first read as a livable pastoral fantasy, then reveal Astraeus hardware beneath it. When a scene could lean either fantasy or cyber, choose fantasy as the silhouette and system logic as the texture, lighting, or overlay.
- **Pixel clarity over noise**: All assets must remain readable at gameplay scale with strong silhouettes, 1px dark outlines, and limited internal detail. When visual richness conflicts with combat or HUD readability, simplify the sprite before adding effects.
- **Corruption has stages**: Visual degradation follows the six corruption states: NOMINAL, ANOMALY, WARNING, ALERT, CRITICAL, BREACH. When showing instability, escalate through controlled palette shifts, scanlines, dropped pixels, geometry breaks, and hardware exposure rather than arbitrary glitch decoration.
- **Dragons feel alive, not mechanical**: Dragons are guardian protocols with personality. Their bodies should read as creatures first, with data, circuitry, or elemental logic expressed through markings, horns, wings, eyes, and evolution accents.

---

## 2. Mood & Atmosphere

| Game State | Mood Target | Lighting Character | Atmosphere | Energy |
|---|---|---|---|---|
| Hub / Dragon Forge | Safe workshop under pressure | Warm forge light against charcoal-blue UI shadows; orange hearth accents, cyan diagnostic glow | Hand-built, sheltered, old machinery, guarded warmth | Measured |
| Hatchery | Wonder and anticipation | Soft radial glow from eggs; high-value highlights on shells and reveal effects | Magical, intimate, sparkling, precise | Rising |
| Fusion / Anvil | Craft, risk, transformation | Strong ember underlight with sharp cyan system readouts; momentary high contrast during fusion commit | Volatile, ritualized, mechanical, consequential | Focused |
| Campaign Map Exploration | Pastoral discovery with hidden wrongness | Bright rendered-world local color, gradually invaded by cooler hardware tones and scanline artifacts | Curious, open, unstable, nostalgic | Contemplative |
| Battle TELEGRAPH | Tactical clarity | Clean separation between combatants and menu band; intent colors bright but contained | Alert, readable, anticipatory | Controlled |
| Battle IMPACT / RECOIL | Elemental force | Brief contrast spikes, hit flashes constrained by reduced-motion settings; recoil returns quickly to readable state | Sharp, kinetic, crunchy, responsive | Frenetic burst |
| Singularity / Mirror Admin | Dread through order | Cold whites, cyan diagnostics, magenta corruption, hard shadows; minimal warmth except player/dragon accents | Clinical, hostile, overclocked, brittle | High tension |
| Victory / Stabilization | Relief and restored signal | Gold-code overlays, warmer mids, reduced glitch activity | Earned, luminous, repaired, breathing | Settling |
| Defeat / Deletion Threat | Loss of continuity | Desaturated palette, failing scanlines, reduced saturation on living elements | Hollow, suspended, fragile, interrupted | Low, tense |
| Crown Ending Choice | Agency at system scale | Large contrast between relic color, crown hardware, and world-state preview; lighting should make each ending visually distinct | Final, irreversible, ceremonial, exposed | Deliberate |

---

## 3. Shape Language

**Core grammar**: Organic fantasy shapes are rounded, chunky, and readable; Astraeus hardware shapes are rectilinear, vertical, modular, and precise. The visual identity depends on the collision between these two shape families.

**Characters and dragons**

- Skye and friendly NPCs use soft triangular and rounded silhouettes, with readable heads, hands, tools, and posture at small scale.
- Dragons require distinct thumbnail silhouettes by element before color is applied:
  - Fire: upward spikes, flame horns, sweeping tail.
  - Ice: crystalline facets, downward points, compact posture.
  - Storm: jagged fins, lightning zigzags, long directional lines.
  - Stone: blocky mass, broad stance, heavy jaw or plating.
  - Venom: curved spines, hooked tail, asymmetrical markings.
  - Shadow: narrow silhouette, broken edges, cloak-like wings.
  - Void: negative-space gaps, unstable outline, anti-symmetry.
- Evolution stages increase silhouette complexity, not just size. Each stage should add one new readable structural feature.

**Environments**

- Pastoral locations use rolling hills, rounded tree canopies, soft paths, and readable landmark silhouettes.
- Hardware intrusions use right angles, server-rack repetition, cable arcs, copper trace roots, vents, fans, panels, and grid breaks.
- Corrupted areas should not become visually mushy. Even at BREACH, broken geometry must preserve navigable silhouettes and landmark readability.

**UI**

- UI echoes a diagnostic overlay, not ornate fantasy parchment.
- Panels use hard-edged rectangles, 1px black outlines, charcoal/navy fills, cyan/gold highlights, and sparse scanline texture.
- Focus states must be visible at rest for gamepad and keyboard navigation. Shape, outline, icon state, and text must carry meaning alongside color.
- HUD forms should be compact, stable, and grid-aligned so values update without layout shift.

**Hierarchy**

- Hero shapes: dragons, eggs, relics, Mirror Admin phases, Crown choices, interactable stations.
- Supporting shapes: terrain tiles, minor props, background hardware, passive scanline effects.
- Important objects receive stronger silhouette contrast before receiving brighter color or animation.

---

## 4. Color System

### Primary Palette

| Color | Hex | Role |
|---|---:|---|
| Pixel Ink | `#05050A` | 1px outlines, deepest shadow, sprite separation |
| Console Charcoal | `#111118` | Primary UI ground, menus, diagnostic panels |
| Render Green | `#62B86A` | Pastoral life, safe world surface, recovery |
| Forge Ember | `#F05A28` | Forge heat, fire, commit actions, danger-adjacent energy |
| Data Cyan | `#36D6E7` | Operator layer, focus, diagnostics, interactable system feedback |
| Restored Gold | `#F6C945` | Rewards, shiny state, stabilization, ending restoration overlays |
| Corruption Magenta | `#D83AF0` | Anomaly, Mirror Admin pressure, unstable simulation states |

### Semantic Rules

- **Red/orange** means heat, damage, forge action, or immediate danger. It must not be used for neutral decoration in combat UI.
- **Cyan** means system readability: focus, diagnostics, operator status, counter readiness, and interactable technical surfaces.
- **Gold** means value, restoration, rare reward, shiny state, or committed world repair.
- **Green** means living rendered-world health or safe pastoral space, but HP safety must also use numeric HP and bar fill.
- **Magenta/purple** means corruption, anomaly, hostile admin activity, or unstable code.
- **White** is reserved for high-priority text, crown-level system exposure, and flash-limited impact accents.
- **Black/charcoal** provides contrast structure and should remain present in UI and sprite outlines across all areas.

### Area Temperature Direction

- Village Edge / Testing Fields: warm greens, sky blues, low corruption.
- Overgrown Buffer: oversaturated greens with cyan seams and misplaced grid artifacts.
- Great Salt Flats: pale desaturated neutrals, hot highlights, sparse color.
- Tundra of Silicon: cold cyan, white, slate, exposed hardware silver.
- Volcanic / Forge views: ember orange, black, copper, hot yellow accents.
- Mainframe Spine / Crown: cold charcoal, cyan, white, magenta corruption, controlled gold only at restoration beats.

### UI Palette

UI uses `#111118` as the base, `#05050A` for outlines, white/off-white for text, Data Cyan for focus and diagnostics, Restored Gold for reward/rare states, Forge Ember for destructive or dangerous confirmations, and Corruption Magenta only for corruption-class or Mirror Admin states.

### Accessibility Requirements

Color never carries required meaning alone. Element type, shiny state, corruption class, stability class, HP danger, owned/in-pack state, disabled actions, and counter readiness must also use icon shape, text label, fill state, outline pattern, motion profile, or position. Reduced-motion and reduced-flash settings must suppress aggressive glitch pulses, full-screen flashes, and hatchery reveal intensity.
