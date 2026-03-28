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
  },
  dataScraps: 0,
  pityCounter: 0,
  milestones: [],
  defeatedNpcs: [],
  singularityProgress: { defeated: [], finalBossPhase: 0 },
  singularityComplete: false,
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

export function fuseDragons(parentAId, parentBId, offspringElement, offspringLevel, offspringXp, offspringShiny, fusedBaseStats) {
  const save = loadSave();
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

export function resetSave() {
  localStorage.removeItem(STORAGE_KEY);
}
