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
    console.warn(`  warn: could not read ${relPath} -- file may not exist in archive`);
    return '';
  }
}

function write(filename, data) {
  const path = join(OUT, filename);
  writeFileSync(path, JSON.stringify(data, null, 2), 'utf8');
  console.log(`  wrote ${filename}`);
}

// lore_canon.gd -> lore.json

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

// captain_log_fragments -- read from forge_data.json
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

// story_data.gd -> story.json

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

// weaver_data.gd -> weaver.json

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

// restoration_data.gd -> restoration.json

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
