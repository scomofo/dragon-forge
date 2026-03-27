const STORAGE_KEY = 'dragonforge_save';

const DEFAULT_SAVE = {
  dragons: {
    fire:   { level: 1, xp: 0 },
    ice:    { level: 1, xp: 0 },
    storm:  { level: 1, xp: 0 },
    stone:  { level: 1, xp: 0 },
    venom:  { level: 1, xp: 0 },
    shadow: { level: 1, xp: 0 },
  },
};

export function loadSave() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_SAVE };
    return JSON.parse(raw);
  } catch {
    return { ...DEFAULT_SAVE };
  }
}

export function saveDragonProgress(dragonId, level, xp) {
  const save = loadSave();
  save.dragons[dragonId] = { level, xp };
  localStorage.setItem(STORAGE_KEY, JSON.stringify(save));
}

export function resetSave() {
  localStorage.removeItem(STORAGE_KEY);
}
