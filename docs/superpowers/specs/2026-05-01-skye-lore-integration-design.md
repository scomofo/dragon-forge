# Skye Lore Integration Design

## Goal

Bring the current browser build back into alignment with the larger Dragon Forge canon without rebuilding the whole game structure. The first pass should make the player identity, premise, and lore delivery clear:

- The player is Skye.
- Felix is Skye's mentor/operator.
- The fantasy world is a rendered system under failure.
- Dragons are living guardians/protocols, not just collectible skins.
- The Mirror Admin/Astraeus mythology is the long threat.

## Current State

The browser game already has pieces of this canon:

- `src/forgeData.js` contains Felix's Forge, Captain's Logs, Analog Relics, and Skye save-state concepts.
- `src/persistence.js` stores `save.skye` state such as wrench tier, relics, bounties, and companion dragon.
- `src/ForgeScreen.jsx` displays Forge interactions, fragments, relics, and Felix lines.
- `src/felixDialogue.js` drives the current opening terminal dialogue.

The heavier Skye mythology currently lives outside the runtime path:

- `dragon-forge-godot/docs/project-memory.md`
- `dragon-forge-godot/docs/outstanding-game-roadmap.md`
- `dragon-forge-godot/docs/*`
- `dragon-forge-reborn/src/lore/canon.ts`
- `dragon-forge-reborn/src/sim/world.ts`

## Scope

This is a lore integration pass, not a full game-structure migration. It should change text, data, and small UI surfaces only where needed.

In scope:

- Opening/boot sequence rewrite.
- Felix opening dialogue rewrite.
- Browser-sized canon registry for Skye, Felix, Astraeus, Mirror Admin, dragons-as-protocols, and the Hardware Husk.
- Captain's Log expansion/rewrite for early mythology.
- Minor Forge hub copy updates that make Skye and the larger canon visible.
- Tests for canonical data shape where practical.

Out of scope:

- Tile overworld movement.
- Godot project migration.
- Full act structure implementation.
- New cutscene system.
- Large new UI redesigns.
- Importing every lore document verbatim.

## Approach

Use the current browser app as the playable shell and fold canon into existing surfaces.

### 1. Runtime Canon Module

Create a small browser-native canon module, likely `src/loreCanon.js`.

It should export concise data objects:

- `PLAYER_CANON`: Skye identity, role, and short player-facing premise.
- `FELIX_CANON`: Felix role, tone, and relationship to Skye.
- `WORLD_CANON`: rendered world, Astraeus, Hardware Husk, Mirror Admin, Great Reset.
- `DRAGON_PROTOCOL_CANON`: dragons as elemental guardians/protocols.
- `OPENING_BOOT_LINES`: terminal boot text for `TitleScreen`.
- `OPENING_FELIX_LINES`: first Felix address to Skye.

The module should adapt the larger docs into compact runtime copy rather than duplicating long markdown passages.

### 2. Opening Identity Pass

Update `TitleScreen.jsx`/`felixDialogue.js` so the first minute establishes the canon clearly.

The boot should feel like a failed system wakeup:

- Address Skye by name.
- Mention the Astraeus or rendered layer.
- Show stability/Matrix/system failure language.
- Hint that Felix is speaking through emergency systems.
- Make the start button feel like Skye choosing to enter the Forge, not just starting an app.

Felix's first dialogue should explain enough to orient the player:

- Skye is needed.
- Dragons are guardians/protocols.
- The Mirror Admin is no longer just a helper.
- The Forge is the safe place where Skye can recover, hatch, and prepare.

### 3. Forge Lore Hub Seed

Update `forgeData.js` so Captain's Logs and Felix contextual lines become the early lore archive.

Captain's Log first arc should cover:

- The Astraeus.
- The rendered world.
- Mirror Admin's original safety purpose.
- The first memory/living-signal failures.
- Dragons as maintenance/security protocols.
- Skye's role as emerging administrator.

Forge copy should make the current hidden `save.skye` state feel intentional. This can be mostly text for the first pass, with a visible Skye panel left for a later implementation pass if needed.

### 4. Keep The Game Moving

Lore should be short, discoverable, and tied to progression.

Rules:

- Opening text can be dramatic but must stay skippable.
- Captain's Logs should be bite-sized.
- Felix lines should be characterful, not encyclopedia entries.
- Avoid dumping Godot docs directly into screens.
- Preserve the existing hatchery/battle/map loop.

## Data Flow

`loreCanon.js` should be imported by:

- `felixDialogue.js` for opening/Felix lines.
- `forgeData.js` for Captain's Log and contextual Forge copy where appropriate.
- Tests can import the canon module directly.

Save-state gates remain in `persistence.js` and `forgeData.js`:

- `flags.metFelix`
- `flags.fragmentsUnlocked`
- `flags.currentAct`
- `skye.*`
- `stats.battlesWon`

## Testing

Add focused tests for:

- Canon module exports required fields for Skye, Felix, world, and dragons.
- Opening dialogue includes "Skye" and at least one core threat term such as "Mirror Admin" or "Astraeus".
- Captain's Log fragments have unique IDs and non-empty titles/bodies.

Run:

- `npm test -- src/loreCanon.test.js src/soundEngine.test.js`
- `npm run build`
- Full `npm test` before completion.

## Success Criteria

The current browser game should no longer feel detached from the larger mythology. A new player should understand within the opening and early Forge visit:

- who they are,
- who Felix is,
- why dragons matter,
- what is wrong with the world,
- and why the Forge exists.

The implementation should leave room for later work: campaign node lore, Skye status UI, Hardware Dungeon concepts, Mirror Admin events, and deeper act progression.
