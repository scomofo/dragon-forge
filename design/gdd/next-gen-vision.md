# Dragon Forge — Next-Generation Vision

> Status: Proposal
> Branch: `next-gen-foundation`
> Purpose: Use the existing Dragon Forge world, systems, silhouettes, encounters, soundtrack identity, and progression as the foundation for a visually and mechanically modern game.

## North star

**Dragon Forge becomes a cinematic 2.5D/3D creature-forging RPG where myth is hardware.**

The existing game already has the right DNA: dragon collection, hatching, fusion, authored boss patterns, four corrupted zones, the Forge as a home base, and the Singularity as an endgame frame. The next-generation version should preserve those ideas while replacing the cartridge-era presentation ceiling with a modern real-time world.

This is not a realism conversion. It should look authored, strange, readable, and unmistakably Dragon Forge.

## Player fantasy

The player is not merely collecting dragons. They are rebuilding living combat programs inside a dying machine-world.

The fantasy loop is:

1. Explore a hostile biome inside the system.
2. Read environmental corruption and enemy behavior.
3. Recover genetic/data fragments, relics, and unstable cores.
4. Return to the Forge.
5. Hatch, tune, fuse, or evolve a dragon.
6. Re-enter the world with a materially different build.
7. Break a boss pattern and permanently alter the region.

The Forge should visibly grow as the player progresses. Every major upgrade should change both mechanics and the physical space.

## What we keep from the current game

- Nine core dragon identities and their distinct silhouettes.
- Element/type relationships and readable battle counters.
- Hatching, fusion, evolution, shop, journal, campaign, and boss progression.
- The four-zone arc: Outer Grid, Frozen Cache, Storm Spine, Admin Core.
- The Singularity and corruption-stage narrative.
- Authored boss patterns rather than stat-only difficulty.
- The existing soundtrack identity and track ownership.
- The concept that the Forge is the player's persistent safe hub.
- Fast battle readability and strong telegraphing.

## What changes

### 1. Presentation becomes spatial

The existing screen-by-screen structure becomes a connected world made from authored compact spaces.

Recommended presentation:

- 3D environments with a controlled isometric/over-the-shoulder camera.
- 3D or 2.5D dragons with strongly authored silhouettes.
- Real-time exploration.
- Seamless or near-seamless transitions between exploration and battle.
- Cinematic camera pushes for attacks, boss phases, hatching, and fusion.

The game should avoid huge empty open worlds. Dense, memorable spaces are a better fit for the fiction and production scope.

### 2. Battles become kinetic but still tactical

Do not turn combat into button-mashing action.

Recommended battle model:

- 1 active dragon + 1 reserve.
- Real-time movement inside compact arenas.
- Four equipped abilities.
- Stamina/heat/cooldown constraints.
- Dodge or guard with timing windows.
- Highly visible enemy tells.
- Elemental interactions that alter the arena.
- Tactical swap opportunities.
- Boss mechanics that require recognition, not grinding.

Examples:

- Ice attacks can freeze conductive puddles and block a lightning chain.
- Stone can create temporary cover against beam attacks.
- Storm can overcharge broken machinery to unlock damage windows.
- Void can erase hazards but also destabilize arena geometry.
- Light can expose hidden corruption nodes.
- Venom can create persistent area-denial zones.

The current authored boss-pattern philosophy remains central.

### 3. Dragons become simulated creatures, not animated icons

Each dragon should have:

- A locomotion set.
- Contextual idle behavior.
- Hit reactions.
- Facial/eye emissive states.
- Ability-specific animation layers.
- Evolution-specific body changes.
- Material changes based on health, corruption, buffs, and elemental state.

The original silhouette laws remain useful even in 3D. A player should identify a dragon by shape before texture.

## Visual direction

### Style

**Dark synthetic fantasy + luminous biological machinery.**

Think forged metal, ceramic armor, glass, cables, crystal, thermal vents, corrupted geometry, volumetric light, sparks, ash, frost, rain, digital particulate matter, and impossible machine architecture.

Do not chase photorealism. Use modern rendering to make stylized art feel physically present.

### Materials

Each type gets a material language:

- Magma: obsidian shell, subsurface heat, cracks, ember particles.
- Ice: translucent facets, trapped bubbles, refraction, frost accumulation.
- Storm: thin conductive membranes, electrical arcing, ionized air.
- Stone: layered mineral/ceramic plating, dust and fracture decals.
- Venom: iridescent wet surfaces, vapor, reactive fluids.
- Shadow: negative-space materials, dithered dissolution, light absorption.
- Void: refractive hollows, gravitational distortion, starless interiors.
- Light: stained-glass plates, caustics, bloom-controlled emissives.
- Synthesis: stable combination of void-frame geometry and illuminated panes.

## Modern rendering budget

The game should use current GPU capability where it improves the experience, with quality tiers so it can still scale down.

Use:

- GPU particles for embers, snow, sparks, toxic clouds, debris, motes, and boss effects.
- Real-time lights with authored limits.
- Volumetric fog and local fog volumes.
- Decals for scorch, frost, cracks, corrosion, impact marks, and boss corruption.
- Shader-driven dissolve, distortion, holograms, force fields, corruption, and elemental reactions.
- Screen-space and post-processing effects used sparingly for impact.
- LODs and visibility ranges for environment density.
- Animation blending rather than sprite-state replacement.
- Background streaming for zone segments.
- Multi-threaded or job-like processing for simulation/data-heavy systems where useful.

Avoid effects that obscure combat telegraphs.

## World structure

### Forge hub

The Forge becomes a walkable, expanding home base.

Core stations:

- Incubation ring.
- Fusion chamber.
- Anvil/upgrade station.
- Archive/journal terminal.
- Shop/trader node.
- Corruption diagnostic array.
- Breach portal.

As bosses fall, dead machinery powers on, new rooms unlock, NPCs arrive, and dragons visibly inhabit the space.

### Outer Grid

Industrial ruins at the edge of the system.

Visual identity:

- Gigantic server architecture.
- Wind through broken cooling stacks.
- Orange data traces.
- Exposed maintenance rails.
- Firewall enemies.
- First major weather and lighting showcase.

### Frozen Cache

A preservation system that has become glacial.

Visual identity:

- Frosted memory vaults.
- Frozen holograms.
- Blue-white shafts of light.
- Crystalline data growth.
- Sliding/falling environmental hazards.

### Storm Spine

A vertical power-transmission region.

Visual identity:

- Thunderclouds inside machinery.
- Suspended platforms.
- Massive power conduits.
- Lightning travelling across surfaces.
- Wind and physics-driven debris.

### Admin Core

The machine's sacred bureaucratic center.

Visual identity:

- Monumental polished architecture.
- Mirror-black floors.
- White administrative light.
- Impossible symmetry.
- Corruption intruding into perfect geometry.
- Mirror Admin and Singularity architecture.

## Simulation opportunities

Modern processing power should improve gameplay, not just visuals.

### Persistent world state

Track meaningful regional state such as:

- Cleared corruption nests.
- Powered machinery.
- Broken bridges.
- Opened shortcuts.
- Environmental elemental state.
- Boss aftermath.
- Forge upgrades.

### Encounter director

Use deterministic rules, not opaque randomness, to vary encounters based on:

- Player party composition.
- Recent ability usage.
- Region corruption.
- Cleared routes.
- Optional objectives.

The goal is replayability without making the game feel generated.

### Reactive arenas

Arenas can simulate:

- Destructible cover.
- Electrical conduction.
- spreading hazards.
- freeze/thaw states.
- heat buildup.
- moving machinery.
- corruption growth.

Keep the simulation bounded and readable.

## Camera

Exploration:

- Controlled third-person or elevated 3/4 camera.
- Strong authored framing.
- Small FOV shifts for speed or danger.

Combat:

- Smart lock-on framing.
- Camera distance based on actor separation.
- Short cinematic emphasis for signature attacks.
- Boss phase transitions can temporarily break the normal camera rules.

Hatching/fusion:

- Full presentation sequences with lighting, particles, sound, and material transformation.

## Audio

Preserve the existing soundtrack direction.

Modernize integration with:

- Layered stems or intensity states when assets permit.
- Positional environmental audio.
- Reactive machine ambience.
- Distinct sonic material for each dragon type.
- Boss telegraphs that are readable by sound as well as animation.

## Accessibility and readability

Next-gen visuals must not reduce clarity.

Required:

- Reduced motion mode.
- High-contrast telegraphs.
- Color-independent attack tells.
- Camera shake slider.
- Flash intensity control.
- Subtitle and combat-caption options.
- Full controller support.
- Rebindable inputs.
- Scalable UI.

## Technical direction

Use the existing Godot 4.6 project as the experimental native runtime instead of starting from an empty repository.

However, do not immediately port all browser systems. First build a **vertical slice** that proves the new presentation and combat model.

Suggested code boundaries:

- `scripts/core/` — game state, save, signals, scene loading.
- `scripts/combat/` — combat simulation and actor controllers.
- `scripts/dragons/` — dragon runtime, abilities, stats, animation hooks.
- `scripts/world/` — exploration, encounters, interactables, streaming.
- `scripts/forge/` — hatching, fusion, upgrades, hub progression.
- `scripts/presentation/` — camera, VFX, materials, screen effects.
- `data/` — canonical content data.

Keep simulation rules independent from presentation wherever practical.

## First vertical slice

Build only this before expanding scope:

### Playable sequence

1. Boot into the Forge.
2. Walk to the incubation ring.
3. Hatch one starter dragon.
4. Open the breach to Outer Grid.
5. Explore one compact route.
6. Fight two normal encounters.
7. Reach one authored mini-boss.
8. Win a core upgrade.
9. Return to the Forge.
10. Install the upgrade and visibly change the hub.

### Content budget

- 1 Forge room cluster.
- 1 exploration zone segment.
- 1 playable dragon.
- 3 enemy types.
- 1 mini-boss.
- 4 abilities.
- 1 environmental interaction system.
- 1 hatch sequence.
- 1 permanent Forge upgrade.

### Success criteria

The slice is successful when:

- Movement feels good with controller and keyboard.
- The dragon feels physically present.
- Combat tells can be read without UI text.
- One elemental interaction materially changes a fight.
- The Forge feels like a place worth returning to.
- The visual identity is clearly Dragon Forge rather than a generic fantasy game.
- Performance scales cleanly across at least three quality presets.

## Production rule

Do not build the entire game at next-gen fidelity before the vertical slice is fun.

The first milestone is not "all current systems ported." It is "one 15–25 minute sequence that proves this version deserves to exist."
