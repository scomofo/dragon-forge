const STORAGE_KEY = 'dragonforge_save';

const DEFAULT_SAVE = {
  dragons: {
    fire:   { level: 1, xp: 0, owned: false, shiny: false },
    ice:    { level: 1, xp: 0, owned: false, shiny: false },
    storm:  { level: 1, xp: 0, owned: false, shiny: false },
    stone:  { level: 1, xp: 0, owned: false, shiny: false },
    venom:  { level: 1, xp: 0, owned: false, shiny: false },
    shadow: { level: 1, xp: 0, owned: false, shiny: false },
  },
  dataScraps: 0,
  pityCounter: 0,
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
  }
  if (save.dataScraps === undefined) save.dataScraps = 0;
  if (save.pityCounter === undefined) save.pityCounter = 0;
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

export function resetSave() {
  localStorage.removeItem(STORAGE_KEY);
}
