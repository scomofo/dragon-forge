---
name: add-dragon
description: Add a new dragon element to Dragon Forge end-to-end — stats, type chart, sprites, default save, tests. Use when asked to add a new dragon, element, or evolution line.
---

# Add a new dragon

Follow the same trail as the Light Dragon (commits `9ad3fee`, `37f0f49`, `994b750`). A new dragon is complete only when every step below is done — a missing step crashes the battle screen or asset manifest test.

## 1. Data (`src/gameData.js`)
- Add the dragon entry: id, name, element, base stats, growth, moves.
- Update the **type chart** — both the new element's row (attacking) and every existing element's entry against it (defending). An asymmetric chart is the most common bug here.
- Add `stageSprites` paths for stages 1–4 (`/assets/dragons/<element>_stage1.png` … `_stage4.png`) plus the base `<element>.png`.

## 2. Sprites (`public/assets/dragons/`)
- Required files: `<element>.png`, `<element>_stage1.png` … `<element>_stage4.png`.
- Placeholders are acceptable initially (copy an existing dragon's files), but real art should come from the `/generate-art` skill.
- `src/assetManifest.test.js` verifies every referenced sprite exists under `public/` — run it.

## 3. Save schema (`src/persistence.js`)
- If the dragon should appear in new games, add it to `DEFAULT_SAVE`.
- Existing saves load through `migrateSave` — add a migration step if existing players must receive the dragon; otherwise they get it through gameplay.

## 4. Verify
```powershell
npx vitest run src/assetManifest.test.js
npx vitest run src/battleEngine.test.js src/fusionEngine.test.js
npm test
```
Then smoke it live: start a battle with the new dragon (the Light Dragon's missed case was a battle-screen crash, fixed in `994b750`), hatch/fuse it, and check all 4 evolution stages render.

## 5. Godot mirror (only if the dragon ships in the Godot build)
- Data: `dragon-forge-godot/scripts/sim/` dragon data module.
- Art: copy sprites under `dragon-forge-godot/assets/` and open the editor once so `.import` files are generated; commit them (repo convention — every PNG has a committed `.import` sibling).
- Smoke: `.\run-godot.ps1 test`
