import { canEquipRelic } from './forgeData';

const STORAGE_KEY = 'dragonforge_save';

const DEFAULT_SAVE = {
  dragons: {
    fire:   { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
    ice:    { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
    storm:  { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
    stone:  { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
    venom:  { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
    shadow: { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
    void:   { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
    light:  { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
  },
  dataScraps: 0,
  pityCounter: 0,
  milestones: [],
  defeatedNpcs: [],
  singularityProgress: { defeated: [], finalBossPhase: 0 },
  singularityComplete: false,
  inventory: { cores: {}, xpBoostBattles: 0, stabilityBoost: false },
  stats: { battlesWon: 0, battlesLost: 0, totalScrapsEarned: 0, totalPulls: 0, fusionsCompleted: 0 },
  lastDailyCompleted: 0,
  records: { fastestWin: null, highestDamage: 0, longestStreak: 0, currentStreak: 0 },
  flags: {
    currentAct: 1,
    metFelix: false,
    lastZone: null,
    fragmentsUnlocked: [],
  },
  skye: {
    wrenchTier: 1,
    relicSlots: 1,
    relicsOwned: [],
    relicsEquipped: [],
    bountiesCleared: 0,
    companionDragonId: null,
  },
};

function migrateSave(save) {
  for (const id of Object.keys(save.dragons)) {
    const d = save.dragons[id];
    if (d.owned === undefined) {
      d.owned = d.level > 1 || d.xp > 0;
    }
    if (d.shiny === undefined) {
      d.shiny = false;
    }
    if (d.fusedBaseStats === undefined) {
      d.fusedBaseStats = null;
    }
  }
  if (save.dataScraps === undefined) save.dataScraps = 0;
  if (save.pityCounter === undefined) save.pityCounter = 0;
  if (save.milestones === undefined) save.milestones = [];
  if (!save.dragons.void) {
    save.dragons.void = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };
  }
  if (save.defeatedNpcs === undefined) save.defeatedNpcs = [];
  if (save.singularityProgress === undefined) {
    save.singularityProgress = { defeated: [], finalBossPhase: 0 };
  }
  if (save.singularityComplete === undefined) save.singularityComplete = false;
  if (save.inventory === undefined) {
    save.inventory = { cores: {}, xpBoostBattles: 0, stabilityBoost: false };
  }
  if (save.stats === undefined) {
    save.stats = { battlesWon: 0, battlesLost: 0, totalScrapsEarned: 0, totalPulls: 0, fusionsCompleted: 0 };
  }
  if (save.lastDailyCompleted === undefined) save.lastDailyCompleted = 0;
  if (save.records === undefined) save.records = { fastestWin: null, highestDamage: 0, longestStreak: 0, currentStreak: 0 };
  if (save.flags === undefined) {
    save.flags = { currentAct: 1, metFelix: false, lastZone: null, fragmentsUnlocked: [] };
  } else {
    if (save.flags.currentAct === undefined) save.flags.currentAct = 1;
    if (save.flags.metFelix === undefined) save.flags.metFelix = false;
    if (save.flags.lastZone === undefined) save.flags.lastZone = null;
    if (!Array.isArray(save.flags.fragmentsUnlocked)) save.flags.fragmentsUnlocked = [];
  }
  if (save.skye === undefined) {
    save.skye = { wrenchTier: 1, relicSlots: 1, relicsOwned: [], relicsEquipped: [], bountiesCleared: 0, companionDragonId: null };
  } else {
    if (save.skye.wrenchTier === undefined) save.skye.wrenchTier = 1;
    if (save.skye.relicSlots === undefined) save.skye.relicSlots = 1;
    if (!Array.isArray(save.skye.relicsOwned)) save.skye.relicsOwned = [];
    if (!Array.isArray(save.skye.relicsEquipped)) save.skye.relicsEquipped = [];
    if (save.skye.bountiesCleared === undefined) save.skye.bountiesCleared = 0;
    if (save.skye.companionDragonId === undefined) save.skye.companionDragonId = null;
  }
  return save;
}

export function loadSave() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return structuredClone(DEFAULT_SAVE);
    return migrateSave(JSON.parse(raw));
  } catch {
    return structuredClone(DEFAULT_SAVE);
  }
}

export function writeSave(save) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(save));
}

export function saveDragonProgress(dragonId, level, xp) {
  const save = loadSave();
  save.dragons[dragonId] = { ...save.dragons[dragonId], level, xp };
  writeSave(save);
}

export function addScraps(amount) {
  const save = loadSave();
  save.dataScraps += amount;
  writeSave(save);
}

export function spendScraps(amount) {
  const save = loadSave();
  if (save.dataScraps < amount) return false;
  save.dataScraps -= amount;
  writeSave(save);
  return true;
}

export function updatePityCounter(newValue) {
  const save = loadSave();
  save.pityCounter = newValue;
  writeSave(save);
}

export function unlockDragon(dragonId, shiny) {
  const save = loadSave();
  save.dragons[dragonId] = { ...save.dragons[dragonId], owned: true };
  if (shiny) save.dragons[dragonId].shiny = true;
  writeSave(save);
}

export function addDragonXp(dragonId, bonusXp) {
  const save = loadSave();
  const d = save.dragons[dragonId];
  d.xp += bonusXp;
  const xpPerLevel = 100;
  while (d.xp >= xpPerLevel) {
    d.xp -= xpPerLevel;
    d.level++;
  }
  writeSave(save);
}

export function upgradeDragonShiny(dragonId) {
  const save = loadSave();
  save.dragons[dragonId].shiny = true;
  writeSave(save);
}

export function claimMilestone(milestoneId, reward) {
  const save = loadSave();
  if (save.milestones.includes(milestoneId)) return false;
  save.milestones.push(milestoneId);
  save.dataScraps += reward;
  writeSave(save);
  return true;
}

export function trackStat(statKey, amount = 1) {
  const save = loadSave();
  if (!save.stats) save.stats = {};
  save.stats[statKey] = (save.stats[statKey] || 0) + amount;
  writeSave(save);
}

export function setDragonNickname(dragonId, nickname) {
  const save = loadSave();
  if (save.dragons[dragonId]) {
    save.dragons[dragonId].nickname = nickname || null;
    writeSave(save);
  }
}

export function recordNpcDefeat(npcId) {
  const save = loadSave();
  if (!save.defeatedNpcs.includes(npcId)) {
    save.defeatedNpcs.push(npcId);
    writeSave(save);
  }
}

export function recordSingularityDefeat(bossId) {
  const save = loadSave();
  if (!save.singularityProgress.defeated.includes(bossId)) {
    save.singularityProgress.defeated.push(bossId);
    writeSave(save);
  }
}

export function updateFinalBossPhase(phase) {
  const save = loadSave();
  save.singularityProgress.finalBossPhase = phase;
  writeSave(save);
}

export function markSingularityComplete() {
  const save = loadSave();
  save.singularityComplete = true;
  save.singularityProgress.finalBossPhase = 4;
  writeSave(save);
}

export function addCore(element, count = 1) {
  const save = loadSave();
  if (!save.inventory.cores[element]) save.inventory.cores[element] = 0;
  save.inventory.cores[element] += count;
  writeSave(save);
}

export function spendCores(coreMap) {
  const save = loadSave();
  for (const [el, count] of Object.entries(coreMap)) {
    save.inventory.cores[el] = (save.inventory.cores[el] || 0) - count;
    if (save.inventory.cores[el] <= 0) delete save.inventory.cores[el];
  }
  writeSave(save);
}

export function setXpBoost(battles) {
  const save = loadSave();
  save.inventory.xpBoostBattles = battles;
  writeSave(save);
}

export function decrementXpBoost() {
  const save = loadSave();
  if (save.inventory.xpBoostBattles > 0) {
    save.inventory.xpBoostBattles--;
    writeSave(save);
  }
}

export function setStabilityBoost(value) {
  const save = loadSave();
  save.inventory.stabilityBoost = value;
  writeSave(save);
}

export function fuseDragons(parentAId, parentBId, offspringElement, offspringLevel, offspringXp, offspringShiny, fusedBaseStats) {
  const save = loadSave();
  if (save.dataScraps < 100) return null;
  save.dragons[parentAId] = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };
  save.dragons[parentBId] = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };
  save.dragons[offspringElement] = {
    level: offspringLevel,
    xp: offspringXp,
    owned: true,
    shiny: offspringShiny,
    fusedBaseStats,
  };
  save.dataScraps -= 100;
  writeSave(save);
  return save;
}

export function updateRecords({ turns, maxDamage, won }) {
  const save = loadSave();
  if (!save.records) save.records = { fastestWin: null, highestDamage: 0, longestStreak: 0, currentStreak: 0 };

  if (won) {
    if (save.records.fastestWin === null || turns < save.records.fastestWin) {
      save.records.fastestWin = turns;
    }
    save.records.currentStreak++;
    if (save.records.currentStreak > save.records.longestStreak) {
      save.records.longestStreak = save.records.currentStreak;
    }
  } else {
    save.records.currentStreak = 0;
  }

  if (maxDamage > save.records.highestDamage) {
    save.records.highestDamage = maxDamage;
  }

  writeSave(save);
}

export function completeDailyChallenge(seed) {
  const save = loadSave();
  save.lastDailyCompleted = seed;
  writeSave(save);
}

export function resetSave() {
  localStorage.removeItem(STORAGE_KEY);
}

// === FORGE / SKYE STATE ===

export function unlockFragment(fragmentId) {
  const save = loadSave();
  if (!save.flags.fragmentsUnlocked.includes(fragmentId)) {
    save.flags.fragmentsUnlocked.push(fragmentId);
    writeSave(save);
    return true;
  }
  return false;
}

export function setFlag(key, value) {
  const save = loadSave();
  save.flags[key] = value;
  writeSave(save);
}

export function setCompanionDragon(dragonId) {
  const save = loadSave();
  save.skye.companionDragonId = dragonId;
  writeSave(save);
}

export function grantRelic(relicId) {
  const save = loadSave();
  if (!save.skye.relicsOwned.includes(relicId)) {
    save.skye.relicsOwned.push(relicId);
    writeSave(save);
    return true;
  }
  return false;
}

export function equipRelic(relicId) {
  const save = loadSave();
  if (!canEquipRelic({
    relicId,
    owned: save.skye.relicsOwned,
    equipped: save.skye.relicsEquipped,
    slots: save.skye.relicSlots,
  })) return false;
  save.skye.relicsEquipped.push(relicId);
  writeSave(save);
  return true;
}

export function unequipRelic(relicId) {
  const save = loadSave();
  save.skye.relicsEquipped = save.skye.relicsEquipped.filter(id => id !== relicId);
  writeSave(save);
  return true;
}
