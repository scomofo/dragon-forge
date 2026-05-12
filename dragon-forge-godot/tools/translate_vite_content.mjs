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

function collectExports(src) {
  const names = [];
  const varRe = /^export\s+const\s+(\w+)/gm;
  let m;
  while ((m = varRe.exec(src)) !== null) names.push(m[1]);
  const funcRe = /^export\s+function\s+(\w+)/gm;
  while ((m = funcRe.exec(src)) !== null) names.push(m[1]);
  return names;
}

function stripAndConvert(src) {
  // Use var (not const) so declarations work across the full vm sandbox scope
  return src
    .replace(/^import\s.+$/gm, '')
    .replace(/^export\s+default\s+/gm, 'module.exports.default = ')
    .replace(/^export\s+const\s+(\w+)/gm, 'var $1')
    .replace(/^export\s+function\s+(\w+)/gm, 'function $1')
    .replace(/^export\s+\{([^}]+)\}/gm, '');
}

function loadModule(relPath, extraContext = {}) {
  const src = readFileSync(join(SRC, relPath), 'utf8');
  const exportedVars = collectExports(src);
  let code = stripAndConvert(src);
  // Append export assignments after all declarations
  code += '\n' + exportedVars.map(n => `try { exports.${n} = ${n}; } catch(e) {}`).join('\n');

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
const fdExportedVars = collectExports(fdSrc);
let fdCode = stripAndConvert(fdSrc);
fdCode += '\n' + fdExportedVars.map(n => `try { exports.${n} = ${n}; } catch(e) {}`).join('\n');

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

const milestonesOut = (jm.MILESTONES || []).map(m => ({
  id: m.id,
  name: m.name,
  description: m.description,
  reward: m.reward,
}));
write('milestones.json', milestonesOut);

// ── felixDialogue.js → felix_dialogue.json ───────────────────────────────

console.log('Translating felixDialogue.js...');
const fdiaSrc = readFileSync(join(SRC, 'felixDialogue.js'), 'utf8');
const fdiaExportedVars = collectExports(fdiaSrc);
let fdiaCode = stripAndConvert(fdiaSrc);
fdiaCode += '\n' + fdiaExportedVars.map(n => `try { exports.${n} = ${n}; } catch(e) {}`).join('\n');

const fdiaContext = vm.createContext({
  exports: {},
  module: { exports: {} },
  console,
  OPENING_FELIX_LINES: loreStub.OPENING_FELIX_LINES || [],
});
try { runModule(fdiaCode, fdiaContext); } catch(e) { console.warn('  warn felixDialogue:', e.message); }
const fdia = { ...fdiaContext.exports };

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
