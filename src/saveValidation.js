// Validate supplied progress before migration can replace malformed fields. Missing
// fields remain valid legacy data: migrate first, then fill defaults so ownership,
// discovery, and intro backfills keep their original meaning.
const isObject = value => value !== null && typeof value === 'object' && !Array.isArray(value);

function requireType(condition, path, expected) {
  if (!condition) throw new Error(`Invalid save field ${path}: expected ${expected}.`);
}

function object(value, path) {
  requireType(isObject(value), path, 'an object');
}

function number(value, path, minimum = 0) {
  requireType(typeof value === 'number' && Number.isFinite(value) && value >= minimum,
    path, `a finite number greater than or equal to ${minimum}`);
}

function boolean(value, path) {
  requireType(typeof value === 'boolean', path, 'a boolean');
}

function string(value, path) {
  requireType(typeof value === 'string', path, 'a string');
}

const nullable = check => (value, path) => { if (value !== null) check(value, path); };
const strings = (value, path) => {
  requireType(Array.isArray(value), path, 'an array of strings');
  value.forEach((entry, index) => string(entry, `${path}[${index}]`));
};

function fields(value, path, schema) {
  object(value, path);
  for (const [key, check] of Object.entries(schema)) {
    if (value[key] !== undefined) check(value[key], `${path}.${key}`);
  }
}

const shape = schema => (value, path) => fields(value, path, schema);
const numbers = keys => Object.fromEntries(keys.map(key => [key, number]));
const booleans = keys => Object.fromEntries(keys.map(key => [key, boolean]));
const record = check => (value, path) => {
  object(value, path);
  for (const [key, entry] of Object.entries(value)) check(entry, `${path}.${key}`);
};

function fusedStats(value, path) {
  object(value, path);
  // Fusion writes these together. A partial object overrides the species' base
  // stats and would introduce undefined/NaN values into battle calculations.
  for (const key of ['hp', 'atk', 'def', 'spd']) number(value[key], `${path}.${key}`);
  requireType(value.hp > 0, `${path}.hp`, 'a positive number');
}

const dragon = shape({
  level: (value, path) => number(value, path, 1),
  xp: number,
  ...booleans(['owned', 'discovered', 'shiny']),
  nickname: nullable(string),
  fusedBaseStats: nullable(fusedStats),
});

function dragonRoster(value, path) {
  object(value, path);
  for (const [id, entry] of Object.entries(value)) {
    // Legacy/future dragon IDs may survive, but inherited object names would
    // resolve to built-ins in existing content-table lookups instead of dragons.
    requireType(!Object.hasOwn(Object.prototype, id), `${path}.${id}`, 'a dragon ID');
    dragon(entry, `${path}.${id}`);
  }
}

function lineage(value, path) {
  requireType(Array.isArray(value), path, 'an array of fusion records');
  value.forEach((entry, index) => fields(entry, `${path}[${index}]`, {
    parentA: string, parentB: string, offspring: string, offspringLevel: number,
  }));
}

const schema = {
  dragons: dragonRoster,
  ...numbers(['dataScraps', 'pityCounter', 'lastDailyCompleted', 'dailyStreak', 'ngPlus']),
  ...booleans(['introSeen', 'singularityComplete', 'mirrorAdminDefeated']),
  milestones: strings,
  defeatedNpcs: strings,
  remnantDefeated: strings,
  fusionLineage: lineage,
  bestRanks: record(string),
  inventory: shape({ cores: record(number), xpBoostBattles: number, stabilityBoost: boolean, voidEgg: boolean }),
  stats: shape(numbers(['battlesWon', 'battlesLost', 'totalScrapsEarned', 'totalPulls', 'fusionsCompleted'])),
  records: shape({
    ...numbers(['highestDamage', 'longestStreak', 'currentStreak']),
    fastestWin: nullable(number),
  }),
  activity: shape({
    ...numbers(['sessions', 'playtimeMs']),
    firstPlayed: nullable(number), lastPlayed: nullable(number), sessionStart: nullable(number),
  }),
  singularityProgress: shape({ defeated: strings, finalBossPhase: number, replayCounts: record(number) }),
  flags: shape({
    ...numbers(['currentAct', 'felixStageHeard']),
    ...booleans(['metFelix', 'felixGreeted', 'journalBriefingSeen', 'felixIrisHeard']),
    lastZone: nullable(string), fragmentsUnlocked: strings,
    // activeExpedition is deliberately repaired by isExpeditionAvailable in migration.
  }),
  skye: shape({
    ...numbers(['wrenchTier', 'relicSlots', 'bountiesCleared']),
    relicsOwned: strings, relicsEquipped: strings, companionDragonId: nullable(string),
  }),
  // Each expedition already sanitizes its individual checkpoints, route choices,
  // and flags. Keep those repairs without accepting a broken progress container.
  outerGrid: object, frozenCache: object, stormSpine: object, adminCore: object,
};

export function validateSaveShape(save) {
  object(save, 'save');
  object(save.dragons, 'save.dragons');
  fields(save, 'save', schema);
  return save;
}

// Clone both supplied values and defaults. Unknown fields survive, arrays are
// retained as complete values, and no default may overwrite existing progress.
// Object.fromEntries also preserves JSON keys such as "__proto__" as own data.
export function fillSaveDefaults(save, defaults) {
  if (save === undefined) return structuredClone(defaults);
  if (!isObject(save) || !isObject(defaults)) return structuredClone(save);
  const keys = new Set([...Object.keys(defaults), ...Object.keys(save)]);
  return Object.fromEntries([...keys].map(key => [key, fillSaveDefaults(
    Object.hasOwn(save, key) ? save[key] : undefined,
    Object.hasOwn(defaults, key) ? defaults[key] : undefined,
  )]));
}
