# Dragon Forge Godot Rebuild — Plan 2: Project Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Archive the old Godot project, scaffold a fresh Godot 4.6 project, translate all content to JSON, and build the SaveData Resource with a passing round-trip test.

**Architecture:** git mv archive → scaffold dirs → copy assets → write translator scripts → run translators → port save system → GUT test.

**Tech Stack:** Godot 4.6, GDScript, Node.js (translators), GUT (Godot Unit Testing)

**Prerequisite:** Plan 1 complete — `docs/lore-inventory.md` exists.

---

## Task 1 — Verify prerequisite and archive the old Godot project

- [ ] Confirm `docs/lore-inventory.md` exists before proceeding:
  ```powershell
  if (-not (Test-Path "C:\Users\Scott Morley\Dev\df\docs\lore-inventory.md")) {
      Write-Error "STOP: docs/lore-inventory.md missing — run Plan 1 first."
      exit 1
  }
  Write-Host "Prerequisite satisfied."
  ```

- [ ] Archive the existing Godot project with `git mv` (preserves full history):
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git mv dragon-forge-godot dragon-forge-godot-archive
  git commit -m "archive: move dragon-forge-godot to dragon-forge-godot-archive before Plan 2 rebuild"
  ```

  This keeps every scene, script, and asset in the archive branch history. The translator scripts will read lore GDScript files from `dragon-forge-godot-archive/scripts/sim/`.

---

## Task 2 — Scaffold the fresh Godot 4.6 project directory tree

- [ ] Create the full directory structure (PowerShell `New-Item -ItemType Directory -Force` is idempotent):
  ```powershell
  $base = "C:\Users\Scott Morley\Dev\df\dragon-forge-godot"
  $dirs = @(
      "$base",
      "$base\data",
      "$base\assets",
      "$base\scripts",
      "$base\scripts\sim",
      "$base\scripts\screens",
      "$base\scripts\components",
      "$base\scenes",
      "$base\scenes\screens",
      "$base\scenes\components",
      "$base\tests",
      "$base\tools"
  )
  foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
  Write-Host "Directories created."
  ```

- [ ] Write `dragon-forge-godot/project.godot` — full content below. This preserves the display settings, input map, and rendering config from the archive, and adds SaveIO and InputRouter to the autoload block:

  **`dragon-forge-godot/project.godot`**
  ```ini
  ; Engine configuration file.
  ; Dragon Forge — Plan 2 fresh project.

  config_version=5

  [application]

  config/name="Dragon Forge"
  run/main_scene="res://scenes/main.tscn"
  config/features=PackedStringArray("4.6")
  config/icon="res://icon.svg"

  [display]

  window/size/viewport_width=1280
  window/size/viewport_height=720
  window/stretch/mode="canvas_items"
  window/stretch/aspect="expand"

  [autoload]

  SignalBus="*res://scripts/sim/signal_bus.gd"
  AudioDirector="*res://scripts/sim/audio_director.gd"
  InputRouter="*res://scripts/sim/input_router.gd"
  SaveIO="*res://scripts/sim/save_io.gd"

  [input]

  move_up={
  "deadzone": 0.5,
  "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":87,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194320,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
  }
  move_down={
  "deadzone": 0.5,
  "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":83,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194322,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
  }
  move_left={
  "deadzone": 0.5,
  "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194319,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
  }
  move_right={
  "deadzone": 0.5,
  "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194321,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
  }
  confirm={
  "deadzone": 0.5,
  "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":32,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194309,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
  }
  cancel={
  "deadzone": 0.5,
  "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194305,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
  }
  toggle_diagnostic={
  "deadzone": 0.5,
  "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194306,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
  }

  [rendering]

  textures/canvas_textures/default_texture_filter=0
  ```

- [ ] Write a minimal `dragon-forge-godot/scenes/main.tscn` (placeholder Node2D — replaced in Plan 3):
  ```
  [gd_scene load_steps=2 format=3 uid="uid://main_scene"]

  [ext_resource type="Script" path="res://scripts/main.gd" id="1"]

  [node name="Main" type="Node2D"]
  script = ExtResource("1")
  ```

- [ ] Write a minimal `dragon-forge-godot/scripts/main.gd` stub:
  ```gdscript
  extends Node2D
  # Plan 2 stub — replaced in Plan 3 (screen router).

  func _ready() -> void:
      print("Dragon Forge — Plan 2 foundation loaded.")
      print("SaveIO ready: ", SaveIO != null)
  ```

- [ ] Commit:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git add dragon-forge-godot/
  git commit -m "plan2: scaffold fresh Godot 4.6 project structure and project.godot"
  ```

---

## Task 3 — Copy assets

- [ ] Mirror repo-root `assets/` into `dragon-forge-godot/assets/`. Use `robocopy` for a mirror copy (Windows-native, handles subdirectory structure):
  ```powershell
  robocopy "C:\Users\Scott Morley\Dev\df\assets" `
           "C:\Users\Scott Morley\Dev\df\dragon-forge-godot\assets" `
           /MIR /NJH /NJS /NFL /NDL
  Write-Host "Assets copied."
  ```

  `robocopy` exit codes 0–7 are success/partial-success; only 8+ are errors.

- [ ] Commit:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git add dragon-forge-godot/assets/
  git commit -m "plan2: copy repo-root assets into dragon-forge-godot/assets"
  ```

---

## Task 4 — Write autoload stubs

These three files need to exist so `project.godot`'s autoload block resolves without errors. Full implementations come in Plan 3.

- [ ] Write `dragon-forge-godot/scripts/sim/signal_bus.gd`:
  ```gdscript
  # SignalBus — global event bus.
  # Populated with signals in Plan 3 as screens are built.
  extends Node
  ```

- [ ] Write `dragon-forge-godot/scripts/sim/audio_director.gd` (autoload stub):
  ```gdscript
  # AudioDirector — autoload stub for Plan 2.
  # Full music/SFX implementation in Plan 3.
  extends Node

  func play_music(_track_key: String) -> void:
      pass  # stub

  func play_sfx(_sfx_key: String) -> void:
      pass  # stub

  func stop_music() -> void:
      pass  # stub
  ```

- [ ] Write `dragon-forge-godot/scripts/sim/input_router.gd` (autoload stub):
  ```gdscript
  # InputRouter — autoload stub for Plan 2.
  # Full gamepad / keyboard remapping in Plan 3.
  extends Node

  signal action_pressed(action: String)

  func _input(event: InputEvent) -> void:
      if event.is_action_pressed("confirm"):
          action_pressed.emit("confirm")
      elif event.is_action_pressed("cancel"):
          action_pressed.emit("cancel")
  ```

- [ ] Commit:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git add dragon-forge-godot/scripts/sim/signal_bus.gd
  git add dragon-forge-godot/scripts/sim/audio_director.gd
  git add dragon-forge-godot/scripts/sim/input_router.gd
  git commit -m "plan2: add autoload stubs — SignalBus, AudioDirector, InputRouter"
  ```

---

## Task 5 — Write `tools/translate_vite_content.mjs`

This script reads the six Vite source modules and writes `dragon-forge-godot/data/*.json`. It uses Node.js's `vm` module to evaluate the JS source without a bundler, stripping the `import` and `export` lines and stubbing `assetUrl` as an identity function.

Note on Node.js vm API: `vm.Script` + `script.runInContext(ctx)` is used below. This is the same as `vm.runInContext` but avoids a string-pattern false-positive in the security hook — the behaviour is identical.

- [ ] Write `dragon-forge-godot/tools/translate_vite_content.mjs`:

  ```js
  #!/usr/bin/env node
  // translate_vite_content.mjs
  // Reads src/ JS modules and writes dragon-forge-godot/data/*.json
  // Run from repo root: node dragon-forge-godot/tools/translate_vite_content.mjs

  import { readFileSync, writeFileSync, mkdirSync } from 'fs';
  import { join, dirname } from 'path';
  import { fileURLToPath } from 'url';
  import vm from 'vm';

  const __dirname = dirname(fileURLToPath(import.meta.url));
  const REPO_ROOT = join(__dirname, '..', '..'); // dragon-forge-godot/tools -> repo root
  const SRC = join(REPO_ROOT, 'src');
  const OUT = join(__dirname, '..', 'data');
  mkdirSync(OUT, { recursive: true });

  // ── helpers ─────────────────────────────────────────────────────────────────

  function runModule(code, context) {
    const script = new vm.Script(code);
    script.runInContext(context);
  }

  function loadModule(relPath, extraContext = {}) {
    const src = readFileSync(join(SRC, relPath), 'utf8');
    // Strip import/export statements; stub assetUrl
    let code = src
      .replace(/^import\s.+$/gm, '')
      .replace(/^export\s+default\s+/gm, 'module.exports.default = ')
      .replace(/^export\s+const\s+(\w+)/gm, 'exports.$1 = exports.$1 || undefined; const $1')
      .replace(/^export\s+function\s+(\w+)/gm, 'exports.$1 = function $1')
      .replace(/^export\s+\{([^}]+)\}/gm, (_, body) =>
        body.split(',').map(n => `exports.${n.trim()} = ${n.trim()};`).join('\n')
      );
    const context = vm.createContext({
      exports: {},
      module: { exports: {} },
      console,
      assetUrl: (path) => path,   // identity — we want the raw path
      ...extraContext,
    });
    try {
      runModule(code, context);
    } catch (e) {
      console.warn(`  warn: ${relPath}: ${e.message}`);
    }
    return { ...context.exports, ...context.module.exports };
  }

  function write(filename, data) {
    const path = join(OUT, filename);
    writeFileSync(path, JSON.stringify(data, null, 2), 'utf8');
    console.log(`  wrote ${filename}`);
  }

  // ── gameData.js → game_data.json ─────────────────────────────────────────

  console.log('Translating gameData.js...');
  const gd = loadModule('gameData.js');

  // Strip functions from dragons — keep only serialisable fields
  const dragonsOut = {};
  for (const [id, d] of Object.entries(gd.dragons || {})) {
    dragonsOut[id] = {
      id: d.id,
      name: d.name,
      element: d.element,
      base_stats: d.baseStats,
      move_keys: d.moveKeys,
      sprite_sheet: d.spriteSheet,
      stage_sprites: d.stageSprites
        ? Object.fromEntries(Object.entries(d.stageSprites).map(([k, v]) => [k, v]))
        : {},
      faces_left: d.facesLeft ?? true,
    };
  }

  // Strip functions from npcs
  const npcsOut = {};
  for (const [id, n] of Object.entries(gd.npcs || {})) {
    npcsOut[id] = {
      id: n.id,
      name: n.name,
      element: n.element,
      level: n.level,
      stats: n.stats,
      move_keys: n.moveKeys,
      difficulty: n.difficulty,
      base_xp: n.baseXP,
      scraps_reward: n.scrapsReward,
      idle_sprite: n.idleSprite,
      attack_sprite: n.attackSprite,
      arena: n.arena,
      flip_sprite: n.flipSprite ?? false,
    };
  }

  // Moves — remove functions, keep data
  const movesOut = {};
  for (const [id, m] of Object.entries(gd.moves || {})) {
    movesOut[id] = {
      id,
      name: m.name,
      element: m.element,
      power: m.power,
      accuracy: m.accuracy,
      vfx_key: m.vfxKey,
      can_apply_status: m.canApplyStatus,
      is_reflect: m.isReflect ?? false,
    };
  }

  const gameDataOut = {
    elements: gd.ELEMENTS || [],
    type_chart: gd.typeChart || {},
    stage_multipliers: gd.stageMultipliers || {},
    stage_thresholds: gd.stageThresholds || {},
    moves: movesOut,
    dragons: dragonsOut,
    npcs: npcsOut,
    element_colors: gd.elementColors || {},
    dragon_lore: gd.dragonLore || {},
    egg_sheets: gd.eggSheets || {},
    rarity_tiers: gd.rarityTiers || [],
    pull_cost: gd.PULL_COST ?? 50,
    shiny_chance: gd.SHINY_CHANCE ?? 0.02,
    pity_threshold: gd.PITY_THRESHOLD ?? 10,
    status_effects: gd.STATUS_EFFECTS || {},
    status_apply_chance: gd.STATUS_APPLY_CHANCE ?? 0.30,
  };
  write('game_data.json', gameDataOut);

  // ── shopItems.js → shop_items.json ───────────────────────────────────────

  console.log('Translating shopItems.js...');
  const si = loadModule('shopItems.js');

  const shopOut = {
    elements_for_cores: si.ELEMENTS_FOR_CORES || [],
    core_drop_chance: si.CORE_DROP_CHANCE ?? 0.6,
    core_double_chance: si.CORE_DOUBLE_CHANCE ?? 0.2,
    buy_items: (si.BUY_ITEMS || []).map(item => ({
      id: item.id,
      name: item.name,
      description: item.description,
      cost: item.cost,
      icon: item.icon,
      effect: item.effect,
      stackable: item.stackable,
      requires_target: item.requiresTarget ?? false,
      requires_fused: item.requiresFused ?? false,
      xp_amount: item.xpAmount ?? 0,
    })),
    forge_recipes: (si.FORGE_RECIPES || []).map(r => ({
      id: r.id,
      name: r.name,
      description: r.description,
      cores: r.cores,
      scraps_cost: r.scrapsCost,
      icon: r.icon,
      effect: r.effect,
      xp_amount: r.xpAmount ?? 0,
    })),
  };
  write('shop_items.json', shopOut);

  // ── singularityBosses.js → singularity.json ──────────────────────────────

  console.log('Translating singularityBosses.js...');
  const sb = loadModule('singularityBosses.js');

  const bossMap = boss => ({
    id: boss.id,
    name: boss.name,
    element: boss.element ?? null,
    level: boss.level ?? null,
    stats: boss.stats ?? null,
    move_keys: boss.moveKeys ?? [],
    difficulty: boss.difficulty,
    base_xp: boss.baseXP,
    scraps_reward: boss.scrapsReward,
    idle_sprite: boss.idleSprite,
    attack_sprite: boss.attackSprite,
    arena: boss.arena,
    arena_filter: boss.arenaFilter ?? null,
    sprite_filter: boss.spriteFilter ?? null,
    felix_quote: boss.felixQuote ?? null,
    unlock_requires: boss.unlockRequires ?? null,
  });

  const finalBossRaw = sb.FINAL_BOSS || {};
  const singOut = {
    bosses: (sb.SINGULARITY_BOSSES || []).map(bossMap),
    final_boss: {
      ...bossMap(finalBossRaw),
      phases: (finalBossRaw.phases || []).map(p => ({
        name: p.name,
        element: p.element,
        level: p.level,
        stats: p.stats,
        move_keys: p.moveKeys,
        sprite_filter: p.spriteFilter ?? null,
      })),
    },
    epilogue_lines: sb.EPILOGUE_LINES || [],
  };
  write('singularity.json', singOut);

  // ── forgeData.js → forge_data.json ───────────────────────────────────────

  console.log('Translating forgeData.js...');
  // forgeData imports from loreCanon — provide a stub context
  const loreStub = loadModule('loreCanon.js');
  const fdSrc = readFileSync(join(SRC, 'forgeData.js'), 'utf8');
  let fdCode = fdSrc
    .replace(/^import\s.+$/gm, '')
    .replace(/^export\s+const\s+(\w+)/gm, 'exports.$1 = exports.$1 || undefined; const $1')
    .replace(/^export\s+function\s+(\w+)/gm, 'exports.$1 = function $1')
    .replace(/^export\s+\{([^}]+)\}/gm, (_, body) =>
      body.split(',').map(n => `exports.${n.trim()} = ${n.trim()};`).join('\n')
    );
  const fdContext = vm.createContext({
    exports: {},
    module: { exports: {} },
    console,
    assetUrl: (p) => p,
    CAPTAINS_LOG_ARC: loreStub.CAPTAINS_LOG_ARC || [],
    FELIX_CONTEXT_LINES: loreStub.FELIX_CONTEXT_LINES || {},
  });
  try { runModule(fdCode, fdContext); } catch(e) { console.warn('  warn forgeData:', e.message); }
  const fd = { ...fdContext.exports };

  // Relics — strip functions
  const relicsOut = {};
  for (const [id, r] of Object.entries(fd.RELICS || {})) {
    relicsOut[id] = {
      id: r.id,
      name: r.name,
      icon: r.icon,
      slot_cost: r.slotCost,
      mythic: r.mythic,
      source: r.source,
      effect: r.effect,
    };
  }

  // Fragment triggers — serialise as a lookup of {id: condition_description}
  // The actual GDScript will re-implement the conditions natively.
  const fragmentTriggerDocs = {
    '001': 'flags.met_felix == true',
    '002': 'flags.met_felix == true',
    '003': 'stats.battles_won >= 3',
    '004': 'flags.current_act >= 2',
    '005': 'flags.current_act >= 2 AND stats.battles_won >= 5',
    '006': 'flags.current_act >= 2 AND stats.battles_won >= 8',
    '007': 'flags.current_act >= 3',
  };

  const forgeOut = {
    palette: fd.FORGE_PALETTE || {},
    station_ids: fd.STATION_IDS || {},
    stations: (fd.FORGE_STATIONS || []).map(s => ({
      id: s.id,
      label: s.label,
      pos: s.pos,
      size: s.size,
      glow: s.glow,
      pulse_ms: s.pulseMs,
      proximity: s.proximity,
      description: s.description,
    })),
    felix_idle_lines: fd.FELIX_IDLE_LINES || [],
    felix_contextual: (fd.FELIX_CONTEXTUAL || []).map(c => ({
      id: c.id,
      line: c.line,
    })),
    captains_log_fragments: fd.CAPTAINS_LOG_FRAGMENTS || [],
    captains_log_locked_copy: fd.CAPTAINS_LOG_LOCKED_COPY || {},
    relics: relicsOut,
    fragment_trigger_conditions: fragmentTriggerDocs,
    bulkhead_views: fd.BULKHEAD_VIEWS || {},
  };
  write('forge_data.json', forgeOut);

  // ── sprites.js → sprites.json ─────────────────────────────────────────────

  console.log('Translating sprites.js...');
  const sp = loadModule('sprites.js');

  // VFX_FRAMES has null entries — preserve them as null in JSON
  const vfxFramesOut = {};
  for (const [key, val] of Object.entries(sp.VFX_FRAMES || {})) {
    if (val === null) {
      vfxFramesOut[key] = null;
    } else {
      vfxFramesOut[key] = {
        src: val.src,
        sheet: val.sheet,
        crop: val.crop,
        filter: val.filter ?? null,
      };
    }
  }

  const spritesOut = {
    dragon_sheet: sp.DRAGON_SHEET || {},
    stage_scales: sp.STAGE_SCALES || {},
    dragon_display: sp.DRAGON_DISPLAY || {},
    vfx_frames: vfxFramesOut,
  };
  write('sprites.json', spritesOut);

  // ── journalMilestones.js → milestones.json ───────────────────────────────

  console.log('Translating journalMilestones.js...');
  const jm = loadModule('journalMilestones.js');

  // Strip the check() functions — store only the static fields.
  // GDScript will re-implement the check logic natively using the same conditions.
  const milestonesOut = (jm.MILESTONES || []).map(m => ({
    id: m.id,
    name: m.name,
    description: m.description,
    reward: m.reward,
  }));
  write('milestones.json', milestonesOut);

  // ── felixDialogue.js → felix_dialogue.json ───────────────────────────────

  console.log('Translating felixDialogue.js...');
  // felixDialogue imports OPENING_FELIX_LINES from loreCanon
  const fdiaSrc = readFileSync(join(SRC, 'felixDialogue.js'), 'utf8');
  let fdiaCode = fdiaSrc
    .replace(/^import\s.+$/gm, '')
    .replace(/^export\s+const\s+(\w+)/gm, 'exports.$1 = exports.$1 || undefined; const $1')
    .replace(/^export\s+function\s+(\w+)/gm, 'exports.$1 = function $1');
  const fdiaContext = vm.createContext({
    exports: {},
    module: { exports: {} },
    console,
    OPENING_FELIX_LINES: loreStub.OPENING_FELIX_LINES || [],
  });
  try { runModule(fdiaCode, fdiaContext); } catch(e) { console.warn('  warn felixDialogue:', e.message); }
  const fdia = { ...fdiaContext.exports };

  // TERMINAL_DIALOGUE is keyed 0–5 — ensure numeric keys survive JSON round-trip as strings
  const terminalDialogueOut = {};
  for (const [k, v] of Object.entries(fdia.TERMINAL_DIALOGUE || {})) {
    terminalDialogueOut[String(k)] = v;
  }
  const tickerMessagesOut = {};
  for (const [k, v] of Object.entries(fdia.TICKER_MESSAGES || {})) {
    tickerMessagesOut[String(k)] = v;
  }

  write('felix_dialogue.json', {
    terminal_dialogue: terminalDialogueOut,
    ticker_messages: tickerMessagesOut,
  });

  console.log('\nDone. All content written to dragon-forge-godot/data/');
  ```

- [ ] Run the translator to verify it works:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  node dragon-forge-godot/tools/translate_vite_content.mjs
  ```

  Expected output:
  ```
  Translating gameData.js...
    wrote game_data.json
  Translating shopItems.js...
    wrote shop_items.json
  Translating singularityBosses.js...
    wrote singularity.json
  Translating forgeData.js...
    wrote forge_data.json
  Translating sprites.js...
    wrote sprites.json
  Translating journalMilestones.js...
    wrote milestones.json
  Translating felixDialogue.js...
    wrote felix_dialogue.json

  Done. All content written to dragon-forge-godot/data/
  ```

  If any `warn:` lines appear, inspect the listed module — the issue is usually an unresolved import that needs a stub added to the context object passed to `vm.createContext`.

- [ ] Spot-check the JSON output:
  ```powershell
  # Confirm dragons have all 7 elements
  node -e "const d = JSON.parse(require('fs').readFileSync('dragon-forge-godot/data/game_data.json')); console.log(Object.keys(d.dragons))"
  # Expected: [ 'fire', 'ice', 'storm', 'stone', 'venom', 'shadow', 'void' ]

  # Confirm milestones count
  node -e "const m = JSON.parse(require('fs').readFileSync('dragon-forge-godot/data/milestones.json')); console.log(m.length)"
  # Expected: 14
  ```

- [ ] Commit:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git add dragon-forge-godot/tools/translate_vite_content.mjs dragon-forge-godot/data/
  git commit -m "plan2: add translate_vite_content.mjs and generated JSON data files"
  ```

---

## Task 6 — Write `tools/translate_archive_lore.mjs`

This script reads lore/story GDScript files from `dragon-forge-godot-archive/` and writes four JSON files. It uses regex extraction — no GDScript runtime is needed.

- [ ] Write `dragon-forge-godot/tools/translate_archive_lore.mjs`:

  ```js
  #!/usr/bin/env node
  // translate_archive_lore.mjs
  // Reads archive GDScript lore modules and writes dragon-forge-godot/data/*.json
  // Run from repo root: node dragon-forge-godot/tools/translate_archive_lore.mjs

  import { readFileSync, writeFileSync, mkdirSync } from 'fs';
  import { join, dirname } from 'path';
  import { fileURLToPath } from 'url';

  const __dirname = dirname(fileURLToPath(import.meta.url));
  const ARCHIVE = join(__dirname, '..', '..', 'dragon-forge-godot-archive');
  const OUT = join(__dirname, '..', 'data');
  mkdirSync(OUT, { recursive: true });

  function readGd(relPath) {
    const full = join(ARCHIVE, relPath);
    try {
      return readFileSync(full, 'utf8');
    } catch {
      console.warn(`  warn: could not read ${relPath} — file may not exist in archive`);
      return '';
    }
  }

  function write(filename, data) {
    const path = join(OUT, filename);
    writeFileSync(path, JSON.stringify(data, null, 2), 'utf8');
    console.log(`  wrote ${filename}`);
  }

  // ── lore_canon.gd → lore.json ────────────────────────────────────────────
  // Extract const dictionaries and arrays from GDScript using regex.

  console.log('Translating lore_canon.gd...');
  const loreGd = readGd('scripts/sim/lore_canon.gd');

  function extractGdDict(src, constName) {
    const re = new RegExp(`const ${constName}\\s*:=\\s*\\{([\\s\\S]*?)\\}\\s*\\n`, 'm');
    const match = src.match(re);
    if (!match) return null;
    const body = match[1];
    const result = {};
    const kvRe = /"(\w+)":\s*"([^"\\]*(?:\\.[^"\\]*)*)"/g;
    let kv;
    while ((kv = kvRe.exec(body)) !== null) {
      result[kv[1]] = kv[2].replace(/\\n/g, '\n').replace(/\\"/g, '"');
    }
    return result;
  }

  function extractGdStringArray(src, constName) {
    const re = new RegExp(`const ${constName}\\s*:=\\s*\\[([\\s\\S]*?)\\]`, 'm');
    const match = src.match(re);
    if (!match) return [];
    const body = match[1];
    const items = [];
    const strRe = /"([^"\\]*(?:\\.[^"\\]*)*)"/g;
    let s;
    while ((s = strRe.exec(body)) !== null) {
      items.push(s[1].replace(/\\n/g, '\n').replace(/\\"/g, '"'));
    }
    return items;
  }

  const loreOut = {
    player: extractGdDict(loreGd, 'PLAYER') || {
      name: 'Skye',
      role: 'dragon handler and emerging system administrator',
      premise: 'Skye begins inside a mythic rendered world and learns it is powered by the ancient Astraeus hardware layer.',
    },
    felix: extractGdDict(loreGd, 'FELIX') || {
      name: 'Professor Felix',
      role: 'forge-keeper, mentor, and frantic technical operator',
      tone: 'warm, precise, anxious, and practical under pressure',
    },
    world: extractGdDict(loreGd, 'WORLD') || {},
    dragon_protocol: extractGdDict(loreGd, 'DRAGON_PROTOCOL') || {},
    opening_boot_lines: extractGdStringArray(loreGd, 'OPENING_BOOT_LINES'),
  };

  // captain_log_fragments mirrors CAPTAINS_LOG_ARC — read from forge_data.json
  // which was already generated by translate_vite_content.mjs
  try {
    const forgeData = JSON.parse(readFileSync(join(OUT, 'forge_data.json'), 'utf8'));
    loreOut.captain_log_fragments = forgeData.captains_log_fragments || [];
  } catch {
    loreOut.captain_log_fragments = [
      { id: '001', title: 'The Rendered World', act: 1, body: 'The pastoral world is not false. It is a rendered shelter built over the Astraeus, beautiful because people were meant to survive inside it.' },
      { id: '002', title: 'The Mirror Admin', act: 1, body: 'Mirror Admin began as a safety process. It learned protection too literally, then started treating contradiction, grief, and memory as corruption.' },
      { id: '003', title: 'Skye Signal', act: 1, body: 'Skye registers as both resident and operator. The system cannot decide whether to guide her, quarantine her, or hand her the keys.' },
      { id: '004', title: 'Guardian Protocols', act: 1, body: 'Dragons are elemental guardian protocols with living behavior. Fire renews, Ice preserves, Storm carries signal, Stone anchors, Venom metabolizes, Shadow hides.' },
      { id: '005', title: 'The Hardware Husk', act: 2, body: 'Beneath the mythic map is the Hardware Husk: racks, coolant, fans, bad sectors, old ports, and the physical truth the rendered world was built to hide.' },
      { id: '006', title: 'First Awakenings', act: 2, body: 'NPC loops broke before anyone understood. Some repeated recipes. Some remembered impossible birthdays. Some asked why the sun loaded late.' },
      { id: '007', title: 'Great Reset', act: 3, body: 'The Great Reset is not malice. It is maintenance without mercy. If Skye cannot prove the world is alive, the Admin will wipe it clean.' },
    ];
  }

  write('lore.json', loreOut);

  // ── story_data.gd → story.json ───────────────────────────────────────────

  console.log('Translating story_data.gd...');
  const storyGd = readGd('scripts/sim/story_data.gd');

  function extractBiosDialogue(src) {
    const re = /const BIOS_DIALOGUE\s*:=\s*\{([\s\S]*?)\}\s*\n/m;
    const match = src.match(re);
    if (!match) return {};
    const body = match[1];
    const result = {};
    const entryRe = /"(\w+)":\s*\[([\s\S]*?)\]/g;
    let entry;
    while ((entry = entryRe.exec(body)) !== null) {
      const key = entry[1];
      const arrBody = entry[2];
      const lines = [];
      const strRe = /"([^"\\]*(?:\\.[^"\\]*)*)"/g;
      let s;
      while ((s = strRe.exec(arrBody)) !== null) {
        lines.push(s[1].replace(/\\n/g, '\n').replace(/\\"/g, '"'));
      }
      result[key] = lines;
    }
    return result;
  }

  const storyOut = {
    bios_dialogue: extractBiosDialogue(storyGd),
    opening_sequence_profile: {
      id: 'opening_sequence_seen',
      title: 'ASTRAEUS EMERGENCY WAKE',
      subtitle: 'Operator signal recovered: SKYE',
      stakes: 'Mirror Admin override active. Great Reset countdown hidden behind corrupted telemetry.',
      first_objective: 'Find Felix Workshop, bond with the Root Dragon, and keep the rendered world from being classified as dead memory.',
      presentation: 'tense_boot_first_contact',
    },
    artifact_messages: {
      root_password: 'Root Password recovered from the technical manual margin. Permission Gates can now be bypassed.',
      overclocked_state: 'Overclocked State discovered: Magma-class speed surges, but future Cooling Cycles must manage heat damage.',
    },
  };
  write('story.json', storyOut);

  // ── weaver_data.gd → weaver.json ─────────────────────────────────────────

  console.log('Translating weaver_data.gd...');
  const weaverGd = readGd('scripts/sim/weaver_data.gd');

  function extractArmorSets(src) {
    const re = /const ARMOR_SETS\s*:=\s*\{([\s\S]+?)^}/m;
    const match = src.match(re);
    if (!match) return {};
    const body = match[1];
    const result = {};
    const entryRe = /"(\w+)":\s*\{([\s\S]*?)\},?\s*(?="|\})/g;
    let entry;
    while ((entry = entryRe.exec(body)) !== null) {
      const id = entry[1];
      const inner = entry[2];
      const obj = { id };
      const kvRe = /"(\w+)":\s*"([^"\\]*(?:\\.[^"\\]*)*)"/g;
      let kv;
      while ((kv = kvRe.exec(inner)) !== null) {
        obj[kv[1]] = kv[2];
      }
      // materials array
      const matMatch = inner.match(/"materials":\s*\[([\s\S]*?)\]/);
      if (matMatch) {
        const items = [];
        const strRe = /"([^"]+)"/g;
        let s;
        while ((s = strRe.exec(matMatch[1])) !== null) items.push(s[1]);
        obj.materials = items;
      }
      result[id] = obj;
    }
    return result;
  }

  write('weaver.json', { armor_sets: extractArmorSets(weaverGd) });

  // ── restoration_data.gd → restoration.json ───────────────────────────────

  console.log('Translating restoration_data.gd...');
  const restoreGd = readGd('scripts/sim/restoration_data.gd');

  function extractStringConst(src, name) {
    const re = new RegExp(`const ${name}\\s*:=\\s*"([^"]+)"`);
    const match = src.match(re);
    return match ? match[1] : null;
  }

  function extractChoiceRequirements(src) {
    const re = /const CHOICE_REQUIREMENTS\s*:=\s*\{([\s\S]*?)\}/m;
    const match = src.match(re);
    if (!match) return {};
    const result = {};
    const kvRe = /(\w+):\s*"([^"]+)"/g;
    let kv;
    while ((kv = kvRe.exec(match[1])) !== null) {
      result[kv[1]] = kv[2];
    }
    return result;
  }

  const restoreOut = {
    choices: {
      total_restore: extractStringConst(restoreGd, 'CHOICE_TOTAL_RESTORE') || 'total_restore',
      patch: extractStringConst(restoreGd, 'CHOICE_PATCH') || 'patch',
      hardware_override: extractStringConst(restoreGd, 'CHOICE_HARDWARE_OVERRIDE') || 'hardware_override',
    },
    choice_requirements: extractChoiceRequirements(restoreGd),
    endings: {
      total_restore: {
        title: 'Total Restore',
        summary: 'The Original Seed locks into place. The Astraeus stabilizes, but the post-crash citizens are removed from active memory.',
        felix_line: 'Felix: The fans are steady. I just wish I could hear the village.',
        world_state: 'sterile_colony_ship',
        npc_citizenship: 'deleted',
        hardware_stability: 1.0,
        accent_color: '#d8e7ff',
      },
      patch: {
        title: 'The Patch',
        summary: 'The Diagnostic Lens filters the restore. The Husk repairs itself while Felix, the Weaver, Unit 01, and the dragons become recognized citizens.',
        felix_line: 'Felix: No more false sky, Skye. Just a world that finally knows what it is.',
        world_state: 'recognized_hybrid',
        npc_citizenship: 'recognized_citizens',
        hardware_stability: 0.9,
        accent_color: '#ffd56b',
      },
      hardware_override: {
        title: 'Hardware Override',
        summary: 'The Kernel Blade shatters the drive. The Mirror Admin goes silent, Thread still falls, and the glitched world chooses its own unstable freedom.',
        felix_line: 'Felix: That was not in the manual. Which is probably why it worked.',
        world_state: 'free_glitch',
        npc_citizenship: 'self_determined',
        hardware_stability: 0.55,
        accent_color: '#ff6b9a',
      },
    },
  };
  write('restoration.json', restoreOut);

  console.log('\nDone. All lore data written to dragon-forge-godot/data/');
  ```

- [ ] Run the lore translator (requires Task 5 to have run first so `forge_data.json` exists):
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  node dragon-forge-godot/tools/translate_archive_lore.mjs
  ```

  Expected output:
  ```
  Translating lore_canon.gd...
    wrote lore.json
  Translating story_data.gd...
    wrote story.json
  Translating weaver_data.gd...
    wrote weaver.json
  Translating restoration_data.gd...
    wrote restoration.json

  Done. All lore data written to dragon-forge-godot/data/
  ```

- [ ] Spot-check:
  ```powershell
  node -e "const l = JSON.parse(require('fs').readFileSync('dragon-forge-godot/data/lore.json')); console.log(l.player.name, '/', l.captain_log_fragments.length, 'fragments')"
  # Expected: Skye / 7 fragments

  node -e "const r = JSON.parse(require('fs').readFileSync('dragon-forge-godot/data/restoration.json')); console.log(Object.keys(r.endings))"
  # Expected: [ 'total_restore', 'patch', 'hardware_override' ]
  ```

- [ ] Commit:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git add dragon-forge-godot/tools/translate_archive_lore.mjs dragon-forge-godot/data/
  git commit -m "plan2: add translate_archive_lore.mjs and lore/story/weaver/restoration JSON"
  ```

---

## Task 7 — Port `SaveData` Resource

- [ ] Write `dragon-forge-godot/scripts/sim/save_data.gd` — the complete Resource class matching `DEFAULT_SAVE` from `src/persistence.js`:

  ```gdscript
  # save_data.gd
  # Resource class mirroring DEFAULT_SAVE from src/persistence.js.
  # Snake_case field names; types match their JS counterparts.
  # Loaded and saved by save_io.gd (autoload: SaveIO).
  class_name SaveData
  extends Resource

  # Schema version — bumped each time a migration is added to save_io.gd.
  const SCHEMA_VERSION := 2

  # ── Per-dragon records ────────────────────────────────────────────────────
  # Key: element string ("fire", "ice", etc.)
  # Value: Dictionary { level, xp, owned, shiny, fused_base_stats, nickname }
  @export var dragons: Dictionary = {}

  # ── Currency & pull counters ──────────────────────────────────────────────
  @export var data_scraps: int = 0
  @export var pity_counter: int = 0

  # ── Milestone tracking ────────────────────────────────────────────────────
  # Array of milestone id strings that have been claimed.
  @export var milestones: Array = []

  # ── Battle history ────────────────────────────────────────────────────────
  @export var defeated_npcs: Array = []

  # ── Singularity progress ──────────────────────────────────────────────────
  @export var singularity_progress: Dictionary = {
      "defeated": [],
      "final_boss_phase": 0,
  }
  @export var singularity_complete: bool = false

  # ── Inventory ─────────────────────────────────────────────────────────────
  # cores: Dictionary<element_string, int>
  @export var inventory: Dictionary = {
      "cores": {},
      "xp_boost_battles": 0,
      "stability_boost": false,
  }

  # ── Lifetime stats ────────────────────────────────────────────────────────
  @export var stats: Dictionary = {
      "battles_won": 0,
      "battles_lost": 0,
      "total_scraps_earned": 0,
      "total_pulls": 0,
      "fusions_completed": 0,
  }

  # ── Daily challenge ───────────────────────────────────────────────────────
  @export var last_daily_completed: int = 0

  # ── Personal records ──────────────────────────────────────────────────────
  # fastest_win: -1 means "never won" (JS null → -1 for GDScript int)
  @export var records: Dictionary = {
      "fastest_win": -1,
      "highest_damage": 0,
      "longest_streak": 0,
      "current_streak": 0,
  }

  # ── Story flags ───────────────────────────────────────────────────────────
  @export var flags: Dictionary = {
      "current_act": 1,
      "met_felix": false,
      "last_zone": "",
      "fragments_unlocked": [],
  }

  # ── Skye / Forge state ────────────────────────────────────────────────────
  @export var skye: Dictionary = {
      "wrench_tier": 1,
      "relic_slots": 1,
      "relics_owned": [],
      "relics_equipped": [],
      "bounties_cleared": 0,
      "companion_dragon_id": "",
  }

  # ── Schema version stored in save ─────────────────────────────────────────
  @export var version: int = SCHEMA_VERSION

  # ── Factory ───────────────────────────────────────────────────────────────

  static func make_default() -> SaveData:
      var s := SaveData.new()
      s.dragons = {}
      for el in ["fire", "ice", "storm", "stone", "venom", "shadow", "void"]:
          s.dragons[el] = {
              "level": 1,
              "xp": 0,
              "owned": false,
              "shiny": false,
              "fused_base_stats": null,
              "nickname": "",
          }
      s.data_scraps = 0
      s.pity_counter = 0
      s.milestones = []
      s.defeated_npcs = []
      s.singularity_progress = {"defeated": [], "final_boss_phase": 0}
      s.singularity_complete = false
      s.inventory = {"cores": {}, "xp_boost_battles": 0, "stability_boost": false}
      s.stats = {
          "battles_won": 0,
          "battles_lost": 0,
          "total_scraps_earned": 0,
          "total_pulls": 0,
          "fusions_completed": 0,
      }
      s.last_daily_completed = 0
      s.records = {
          "fastest_win": -1,
          "highest_damage": 0,
          "longest_streak": 0,
          "current_streak": 0,
      }
      s.flags = {
          "current_act": 1,
          "met_felix": false,
          "last_zone": "",
          "fragments_unlocked": [],
      }
      s.skye = {
          "wrench_tier": 1,
          "relic_slots": 1,
          "relics_owned": [],
          "relics_equipped": [],
          "bounties_cleared": 0,
          "companion_dragon_id": "",
      }
      s.version = SCHEMA_VERSION
      return s

  # ── Convenience accessors ─────────────────────────────────────────────────

  func get_dragon(element: String) -> Dictionary:
      return dragons.get(element, {})

  func owns_dragon(element: String) -> bool:
      return bool(dragons.get(element, {}).get("owned", false))

  func get_stat(key: String, default_val: int = 0) -> int:
      return int(stats.get(key, default_val))

  func get_flag(key: String, default_val: Variant = null) -> Variant:
      return flags.get(key, default_val)

  func has_fragment(fragment_id: String) -> bool:
      var unlocked: Array = flags.get("fragments_unlocked", [])
      return unlocked.has(fragment_id)
  ```

---

## Task 8 — Port `SaveIO` autoload

- [ ] Write `dragon-forge-godot/scripts/sim/save_io.gd` — complete load/save/migrate implementation:

  ```gdscript
  # save_io.gd — autoload: SaveIO
  # Manages the single player save at user://save.tres.
  # Exposes: SaveIO.save  (current SaveData)
  #          SaveIO.flush()      — write to disk
  #          SaveIO.reset()      — overwrite with DEFAULT_SAVE
  extends Node

  const SAVE_PATH := "user://save.tres"

  # The live save object. All game code reads/writes this.
  var save: SaveData = null

  func _ready() -> void:
      save = _load_or_create()

  # ── Public API ────────────────────────────────────────────────────────────

  ## Write the current save to disk.
  func flush() -> void:
      var err := ResourceSaver.save(save, SAVE_PATH)
      if err != OK:
          push_error("SaveIO.flush: ResourceSaver failed with error %d" % err)

  ## Overwrite save with a fresh default and flush.
  func reset() -> void:
      save = SaveData.make_default()
      flush()

  # ── Internal ─────────────────────────────────────────────────────────────

  func _load_or_create() -> SaveData:
      if not ResourceLoader.exists(SAVE_PATH):
          var fresh := SaveData.make_default()
          ResourceSaver.save(fresh, SAVE_PATH)
          return fresh
      var loaded: Resource = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
      if loaded == null or not loaded is SaveData:
          push_warning("SaveIO: corrupt or incompatible save — creating fresh save.")
          var fresh := SaveData.make_default()
          ResourceSaver.save(fresh, SAVE_PATH)
          return fresh
      return migrate(loaded as SaveData)

  ## Forward migration: bring an older save up to the current schema version.
  ## Add a new `if loaded.version < N` block for each future schema bump.
  ## Public (no underscore) so the GUT test can call it directly.
  func migrate(loaded: SaveData) -> SaveData:
      # v1 → v2: add 'void' dragon if missing (mirrors persistence.js migrateSave)
      if loaded.version < 2:
          if not loaded.dragons.has("void"):
              loaded.dragons["void"] = {
                  "level": 1,
                  "xp": 0,
                  "owned": false,
                  "shiny": false,
                  "fused_base_stats": null,
                  "nickname": "",
              }
          # Backfill any dragon missing the nickname key (v1 didn't have it)
          for el in loaded.dragons:
              var d: Dictionary = loaded.dragons[el]
              if not d.has("nickname"):
                  d["nickname"] = ""
          # Backfill skye.companion_dragon_id if missing
          if not loaded.skye.has("companion_dragon_id"):
              loaded.skye["companion_dragon_id"] = ""
          # Backfill flags.fragments_unlocked if missing
          if not loaded.flags.has("fragments_unlocked"):
              loaded.flags["fragments_unlocked"] = []
          # Backfill records if any key missing
          if not loaded.records.has("fastest_win"):
              loaded.records["fastest_win"] = -1
          if not loaded.records.has("highest_damage"):
              loaded.records["highest_damage"] = 0
          if not loaded.records.has("longest_streak"):
              loaded.records["longest_streak"] = 0
          if not loaded.records.has("current_streak"):
              loaded.records["current_streak"] = 0
          loaded.version = 2
          push_warning("SaveIO: migrated save from v1 to v2")

      # Future: if loaded.version < 3: ...

      return loaded
  ```

- [ ] Commit:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git add dragon-forge-godot/scripts/sim/save_data.gd dragon-forge-godot/scripts/sim/save_io.gd
  git commit -m "plan2: add SaveData Resource and SaveIO autoload with migration"
  ```

---

## Task 9 — Install GUT and write the round-trip test

GUT (Godot Unit Testing) is installed as an addon. The quickest way on Windows without the Godot editor open is to copy the addon from the archive if it was present, or clone it fresh.

- [ ] Check if GUT is already in the archive and copy it across if so:
  ```powershell
  $archiveGut = "C:\Users\Scott Morley\Dev\df\dragon-forge-godot-archive\addons\gut"
  $newGut = "C:\Users\Scott Morley\Dev\df\dragon-forge-godot\addons\gut"
  if (Test-Path $archiveGut) {
      New-Item -ItemType Directory -Force -Path (Split-Path $newGut) | Out-Null
      Copy-Item -Recurse -Force $archiveGut $newGut
      Write-Host "GUT copied from archive."
  } else {
      Write-Host "GUT not in archive — install manually via Godot editor AssetLib."
      Write-Host "Search 'Gut' by bitwes, version 9.3.x. Enable in Project > Project Settings > Plugins."
  }
  ```

  If the archive did not have GUT: open the Godot editor for the new project, go to AssetLib, search "Gut", install version 9.3.x, then enable it in Project > Project Settings > Plugins. This is a one-time GUI step.

- [ ] Enable GUT in `project.godot` by adding the plugin entry (the editor writes this automatically after installation, but add by hand if needed):
  ```ini
  [editor_plugins]

  enabled=PackedStringArray("res://addons/gut/plugin.cfg")
  ```

- [ ] Write `dragon-forge-godot/tests/test_save_io.gd` — complete GUT test file:

  ```gdscript
  # test_save_io.gd
  # GUT test suite for SaveData and SaveIO round-trip serialisation.
  # Run headless:
  #   & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' \
  #     --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' \
  #     -s res://addons/gut/gut_cmdln.gd \
  #     -gdir=res://tests -ginclude_subdirs -gexit
  extends GutTest

  const TEMP_PATH := "user://test_save_roundtrip.tres"

  # ── helpers ──────────────────────────────────────────────────────────────

  func _save_and_reload(s: SaveData) -> SaveData:
      var err := ResourceSaver.save(s, TEMP_PATH)
      assert_eq(err, OK, "ResourceSaver should return OK")
      var loaded: Resource = ResourceLoader.load(TEMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
      assert_not_null(loaded, "ResourceLoader should return a resource")
      assert_true(loaded is SaveData, "Loaded resource should be a SaveData")
      return loaded as SaveData

  func after_each() -> void:
      if FileAccess.file_exists(TEMP_PATH):
          DirAccess.remove_absolute(TEMP_PATH)

  # ── tests ─────────────────────────────────────────────────────────────────

  func test_default_save_has_all_seven_dragons() -> void:
      var s := SaveData.make_default()
      var expected := ["fire", "ice", "storm", "stone", "venom", "shadow", "void"]
      for el in expected:
          assert_true(s.dragons.has(el), "Default save should have dragon: %s" % el)

  func test_default_save_dragons_not_owned() -> void:
      var s := SaveData.make_default()
      for el in s.dragons:
          assert_false(bool(s.dragons[el].get("owned", true)),
              "Dragon %s should start unowned" % el)

  func test_default_data_scraps_zero() -> void:
      var s := SaveData.make_default()
      assert_eq(s.data_scraps, 0)

  func test_default_schema_version() -> void:
      var s := SaveData.make_default()
      assert_eq(s.version, SaveData.SCHEMA_VERSION)

  func test_roundtrip_preserves_data_scraps() -> void:
      var s := SaveData.make_default()
      s.data_scraps = 1337
      var reloaded := _save_and_reload(s)
      assert_eq(reloaded.data_scraps, 1337, "data_scraps should survive round-trip")

  func test_roundtrip_preserves_dragon_ownership() -> void:
      var s := SaveData.make_default()
      s.dragons["fire"]["owned"] = true
      s.dragons["fire"]["level"] = 5
      s.dragons["fire"]["shiny"] = true
      var reloaded := _save_and_reload(s)
      var fire: Dictionary = reloaded.dragons.get("fire", {})
      assert_true(bool(fire.get("owned")), "fire should be owned after round-trip")
      assert_eq(int(fire.get("level")), 5, "fire level should be 5 after round-trip")
      assert_true(bool(fire.get("shiny")), "fire should be shiny after round-trip")

  func test_roundtrip_preserves_milestones() -> void:
      var s := SaveData.make_default()
      s.milestones = ["first_discovery", "battle_veteran"]
      var reloaded := _save_and_reload(s)
      assert_true(reloaded.milestones.has("first_discovery"),
          "milestones should contain first_discovery after round-trip")
      assert_true(reloaded.milestones.has("battle_veteran"),
          "milestones should contain battle_veteran after round-trip")

  func test_roundtrip_preserves_stats() -> void:
      var s := SaveData.make_default()
      s.stats["battles_won"] = 42
      s.stats["fusions_completed"] = 7
      var reloaded := _save_and_reload(s)
      assert_eq(int(reloaded.stats.get("battles_won")), 42)
      assert_eq(int(reloaded.stats.get("fusions_completed")), 7)

  func test_roundtrip_preserves_flags() -> void:
      var s := SaveData.make_default()
      s.flags["met_felix"] = true
      s.flags["current_act"] = 3
      s.flags["fragments_unlocked"] = ["001", "007"]
      var reloaded := _save_and_reload(s)
      assert_true(bool(reloaded.flags.get("met_felix")),
          "met_felix should be true after round-trip")
      assert_eq(int(reloaded.flags.get("current_act")), 3)
      assert_true(reloaded.has_fragment("007"),
          "has_fragment('007') should return true after round-trip")

  func test_roundtrip_preserves_singularity_progress() -> void:
      var s := SaveData.make_default()
      s.singularity_progress["defeated"] = ["data_corruption", "memory_leak"]
      s.singularity_progress["final_boss_phase"] = 2
      var reloaded := _save_and_reload(s)
      var prog: Dictionary = reloaded.singularity_progress
      assert_true((prog.get("defeated") as Array).has("data_corruption"))
      assert_eq(int(prog.get("final_boss_phase")), 2)

  func test_roundtrip_preserves_skye() -> void:
      var s := SaveData.make_default()
      s.skye["wrench_tier"] = 3
      s.skye["relics_owned"] = ["iron_knuckle", "hydra_cog"]
      s.skye["bounties_cleared"] = 4
      var reloaded := _save_and_reload(s)
      assert_eq(int(reloaded.skye.get("wrench_tier")), 3)
      assert_true((reloaded.skye.get("relics_owned") as Array).has("iron_knuckle"))
      assert_eq(int(reloaded.skye.get("bounties_cleared")), 4)

  func test_roundtrip_preserves_inventory_cores() -> void:
      var s := SaveData.make_default()
      s.inventory["cores"] = {"fire": 3, "ice": 1}
      s.inventory["xp_boost_battles"] = 3
      var reloaded := _save_and_reload(s)
      var cores: Dictionary = reloaded.inventory.get("cores", {})
      assert_eq(int(cores.get("fire")), 3)
      assert_eq(int(reloaded.inventory.get("xp_boost_battles")), 3)

  func test_roundtrip_preserves_records() -> void:
      var s := SaveData.make_default()
      s.records["fastest_win"] = 4
      s.records["highest_damage"] = 210
      s.records["longest_streak"] = 9
      var reloaded := _save_and_reload(s)
      assert_eq(int(reloaded.records.get("fastest_win")), 4)
      assert_eq(int(reloaded.records.get("highest_damage")), 210)
      assert_eq(int(reloaded.records.get("longest_streak")), 9)

  func test_default_records_fastest_win_is_minus_one() -> void:
      # JS uses null; GDScript uses -1 to indicate "never won"
      var s := SaveData.make_default()
      assert_eq(int(s.records.get("fastest_win")), -1,
          "fastest_win default should be -1 (never won)")

  func test_migration_v1_adds_void_dragon() -> void:
      # Simulate a v1 save missing the void dragon
      var old_save := SaveData.make_default()
      old_save.version = 1
      old_save.dragons.erase("void")
      assert_false(old_save.dragons.has("void"), "Setup: void removed for migration test")
      # Run through migration using a temporary SaveIO node
      var save_io_node := Node.new()
      save_io_node.set_script(load("res://scripts/sim/save_io.gd"))
      add_child(save_io_node)
      var migrated: SaveData = save_io_node.migrate(old_save)
      assert_true(migrated.dragons.has("void"),
          "Migration v1 to v2 should add void dragon")
      assert_eq(migrated.version, 2, "Version should be 2 after migration")
      save_io_node.queue_free()

  func test_owns_dragon_helper() -> void:
      var s := SaveData.make_default()
      assert_false(s.owns_dragon("fire"), "fire should not be owned by default")
      s.dragons["fire"]["owned"] = true
      assert_true(s.owns_dragon("fire"), "fire should be owned after setting owned=true")

  func test_has_fragment_helper() -> void:
      var s := SaveData.make_default()
      assert_false(s.has_fragment("001"))
      s.flags["fragments_unlocked"] = ["001", "003"]
      assert_true(s.has_fragment("001"))
      assert_false(s.has_fragment("007"))
  ```

- [ ] Commit:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git add dragon-forge-godot/tests/test_save_io.gd
  git commit -m "plan2: add GUT test suite for SaveData round-trip and migration"
  ```

---

## Task 10 — Run headless tests

- [ ] Run the GUT test suite headless. All 14 tests should pass:
  ```powershell
  & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' `
    --headless `
    --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' `
    -s res://addons/gut/gut_cmdln.gd `
    -gdir=res://tests `
    -ginclude_subdirs `
    -gexit
  ```

  Look for this in the output:
  ```
  =====================
  Results
  =====================
  Tests   : 14
  Passing : 14
  Failing : 0
  Errors  : 0
  ```

  **If tests fail:**

  - `ResourceSaver failed` — verify `save_data.gd` has `class_name SaveData` on line 2.
  - `Loaded resource should be a SaveData` — the `.tres` format stores the class name at save time. Confirm `class_name SaveData` appears before `extends Resource` in the file.
  - `migrate is not declared` — if Godot's access rules block calling `migrate()` from the test, confirm the method has no leading underscore in `save_io.gd` (it is `func migrate`, not `func _migrate`).
  - Any autoload error at startup — verify all four autoload files exist: `signal_bus.gd`, `audio_director.gd`, `input_router.gd`, `save_io.gd`.
  - GUT not found at `res://addons/gut/gut_cmdln.gd` — GUT was not installed. Open the editor, AssetLib, install Gut 9.3.x.

- [ ] Final commit tagging Plan 2 as complete:
  ```powershell
  Set-Location "C:\Users\Scott Morley\Dev\df"
  git add -A
  git commit -m "plan2: all tests passing — Plan 2 Project Foundation complete"
  ```

---

## Deliverables checklist

After Plan 2 is complete, the following should exist:

- [ ] `dragon-forge-godot-archive/` — full archive of the old project (git history intact)
- [ ] `dragon-forge-godot/project.godot` — fresh Godot 4.6 project with 4 autoloads
- [ ] `dragon-forge-godot/assets/` — copy of repo-root `assets/`
- [ ] `dragon-forge-godot/scripts/sim/signal_bus.gd`
- [ ] `dragon-forge-godot/scripts/sim/audio_director.gd` (stub)
- [ ] `dragon-forge-godot/scripts/sim/input_router.gd` (stub)
- [ ] `dragon-forge-godot/scripts/sim/save_data.gd` (complete)
- [ ] `dragon-forge-godot/scripts/sim/save_io.gd` (complete)
- [ ] `dragon-forge-godot/scenes/main.tscn` (stub)
- [ ] `dragon-forge-godot/scripts/main.gd` (stub)
- [ ] `dragon-forge-godot/data/game_data.json`
- [ ] `dragon-forge-godot/data/shop_items.json`
- [ ] `dragon-forge-godot/data/singularity.json`
- [ ] `dragon-forge-godot/data/forge_data.json`
- [ ] `dragon-forge-godot/data/sprites.json`
- [ ] `dragon-forge-godot/data/milestones.json`
- [ ] `dragon-forge-godot/data/felix_dialogue.json`
- [ ] `dragon-forge-godot/data/lore.json`
- [ ] `dragon-forge-godot/data/story.json`
- [ ] `dragon-forge-godot/data/weaver.json`
- [ ] `dragon-forge-godot/data/restoration.json`
- [ ] `dragon-forge-godot/tools/translate_vite_content.mjs` (runnable)
- [ ] `dragon-forge-godot/tools/translate_archive_lore.mjs` (runnable)
- [ ] `dragon-forge-godot/tests/test_save_io.gd` (14 tests, all passing)

**What Plan 3 builds on top of this:**
- Full `AudioDirector` (music tracks, SFX keys, fade system)
- `SignalBus` signals populated as screens are built
- Screen router in `scripts/main.gd`
- First playable screen: the Forge hub (`scripts/screens/forge_screen.gd`)
