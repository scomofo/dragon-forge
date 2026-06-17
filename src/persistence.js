import { canEquipRelic } from './forgeData';

const STORAGE_KEY = 'dragonforge_save';

const DEFAULT_SAVE = {
  // `discovered` is a permanent codex flag: once a dragon has ever been owned it stays
  // true even if fusion later consumes it (owned → false). Collection-count milestones
  // count `discovered`, not `owned`, so fusing never reverts collection progress.
  dragons: {
    fire:   { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
    ice:    { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
    storm:  { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
    stone:  { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
    venom:  { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
    shadow: { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
    void:      { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
    light:     { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
    synthesis: { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
  },
  dataScraps: 0,
  pityCounter: 0,
  milestones: [],
  defeatedNpcs: [],
  singularityProgress: { defeated: [], finalBossPhase: 0, replayCounts: {} },
  singularityComplete: false,
  mirrorAdminDefeated: false,
  remnantDefeated: [],
  fusionLineage: [],
  inventory: { cores: {}, xpBoostBattles: 0, stabilityBoost: false },
  stats: { battlesWon: 0, battlesLost: 0, totalScrapsEarned: 0, totalPulls: 0, fusionsCompleted: 0 },
  lastDailyCompleted: 0,
  dailyStreak: 0,
  introSeen: false,
  ngPlus: 0,
  records: { fastestWin: null, highestDamage: 0, longestStreak: 0, currentStreak: 0 },
  flags: {
    currentAct: 1,
    metFelix: false,
    felixGreeted: false,
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
    // Backfill the codex flag: anything currently owned (or showing signs of past
    // ownership) counts as discovered.
    if (d.discovered === undefined) {
      d.discovered = d.owned || d.level > 1 || d.xp > 0 || !!d.fusedBaseStats;
    }
  }
  // Repair pre-`discovered` saves whose collection regressed: any dragon that was ever
  // a fusion parent was genuinely discovered even if fusion since flipped it to unowned.
  if (Array.isArray(save.fusionLineage)) {
    for (const entry of save.fusionLineage) {
      for (const id of [entry?.parentA, entry?.parentB, entry?.offspring]) {
        if (id && save.dragons[id]) save.dragons[id].discovered = true;
      }
    }
  }
  if (save.dataScraps === undefined) save.dataScraps = 0;
  if (save.pityCounter === undefined) save.pityCounter = 0;
  if (save.milestones === undefined) save.milestones = [];
  // Retroactively grant full_roster for saves that met the old 6-dragon threshold before it was raised to 8.
  if (!save.milestones.includes('full_roster') &&
      Object.values(save.dragons).filter(d => d.discovered).length >= 8) {
    save.milestones.push('full_roster');
    save.dataScraps += 500;
  }
  if (!save.dragons.void) {
    save.dragons.void = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };
  }
  if (!save.dragons.light) {
    save.dragons.light = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };
  }
  if (!save.dragons.synthesis) {
    save.dragons.synthesis = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };
  }
  if (save.defeatedNpcs === undefined) save.defeatedNpcs = [];
  if (save.singularityProgress === undefined) {
    save.singularityProgress = { defeated: [], finalBossPhase: 0, replayCounts: {} };
  } else if (!save.singularityProgress.replayCounts) {
    save.singularityProgress.replayCounts = {};
  }
  if (save.dailyStreak === undefined) save.dailyStreak = 0;
  // Returning players who have already owned a dragon have seen the boot sequence; skip the wall for them.
  if (save.introSeen === undefined) save.introSeen = Object.values(save.dragons).some(d => d.owned);
  if (save.ngPlus === undefined) save.ngPlus = 0;
  if (save.singularityComplete === undefined) save.singularityComplete = false;
  if (save.mirrorAdminDefeated === undefined) save.mirrorAdminDefeated = false;
  if (!Array.isArray(save.remnantDefeated)) save.remnantDefeated = [];
  if (!Array.isArray(save.fusionLineage)) save.fusionLineage = [];
  // Light Dragon is the Singularity completion reward; grant retroactively to finishers.
  if (save.singularityComplete && !save.dragons.light.owned) {
    save.dragons.light.owned = true;
    save.dragons.light.discovered = true;
  }
  if (save.inventory === undefined) {
    save.inventory = { cores: {}, xpBoostBattles: 0, stabilityBoost: false };
  }
  if (save.stats === undefined) {
    save.stats = { battlesWon: 0, battlesLost: 0, totalScrapsEarned: 0, totalPulls: 0, fusionsCompleted: 0 };
  }
  if (save.lastDailyCompleted === undefined) save.lastDailyCompleted = 0;
  if (save.records === undefined) save.records = { fastestWin: null, highestDamage: 0, longestStreak: 0, currentStreak: 0 };
  if (save.flags === undefined) {
    save.flags = { currentAct: 1, metFelix: false, felixGreeted: false, lastZone: null, fragmentsUnlocked: [] };
  } else {
    if (save.flags.currentAct === undefined) save.flags.currentAct = 1;
    if (save.flags.metFelix === undefined) save.flags.metFelix = false;
    if (save.flags.felixGreeted === undefined) save.flags.felixGreeted = false;
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
  save.dragons[dragonId] = { ...save.dragons[dragonId], owned: true, discovered: true };
  if (shiny) save.dragons[dragonId].shiny = true;
  writeSave(save);
}

export function xpForLevel(level) { return 50 + (level - 1) * 5; }  // L1:50 .. L49:290, smooth ramp

// Single source of truth for XP->level progression. Mutates `dragon` in place on
// the one canonical curve, capping at level 50. EVERY XP source (battle wins,
// duplicate pulls, shop items) must go through this so a dragon levels the same
// no matter where the XP came from.
export function applyDragonXp(dragon, amount) {
  dragon.xp += amount;
  let need = xpForLevel(dragon.level);
  while (dragon.xp >= need && dragon.level < 50) {
    dragon.xp -= need;
    dragon.level++;
    need = xpForLevel(dragon.level);
  }
  if (dragon.level >= 50) dragon.xp = 0;
  return dragon;
}

export function addDragonXp(dragonId, bonusXp) {
  const save = loadSave();
  applyDragonXp(save.dragons[dragonId], bonusXp);
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

// Endgame replay reward: every 5th total clear of a Singularity boss yields a
// core cache, so replays (which scale harder — see scaleBossForPlayer's rising
// REPLAY_CAP) stay worth repeating. Pure + deterministic so it is unit-testable.
const REPLAY_REWARD_CORE_ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow'];
export function getReplayReward(clearCount) {
  if (!clearCount || clearCount % 5 !== 0) return null;
  const element = REPLAY_REWARD_CORE_ELEMENTS[((clearCount / 5) - 1) % REPLAY_REWARD_CORE_ELEMENTS.length];
  return { element, count: 5 };
}

function grantReplayReward(save, clearCount) {
  const reward = getReplayReward(clearCount);
  if (!reward) return;
  if (!save.inventory.cores[reward.element]) save.inventory.cores[reward.element] = 0;
  save.inventory.cores[reward.element] = Math.min(99, save.inventory.cores[reward.element] + reward.count);
}

export function recordSingularityDefeat(bossId) {
  const save = loadSave();
  if (!save.singularityProgress.defeated.includes(bossId)) {
    save.singularityProgress.defeated.push(bossId);
  }
  const clearCount = (save.singularityProgress.replayCounts[bossId] || 0) + 1;
  save.singularityProgress.replayCounts[bossId] = clearCount;
  grantReplayReward(save, clearCount);
  writeSave(save);
}

export function updateFinalBossPhase(phase) {
  const save = loadSave();
  save.singularityProgress.finalBossPhase = phase;
  writeSave(save);
}

export function markIntroSeen() {
  const save = loadSave();
  if (save.introSeen) return;
  save.introSeen = true;
  writeSave(save);
}

export function markMirrorAdminDefeated() {
  const save = loadSave();
  save.mirrorAdminDefeated = true;
  const clearCount = (save.singularityProgress.replayCounts['mirror_admin'] || 0) + 1;
  save.singularityProgress.replayCounts['mirror_admin'] = clearCount;
  grantReplayReward(save, clearCount);
  writeSave(save);
}

export function recordRemnantDefeat(remnantId) {
  const save = loadSave();
  if (!Array.isArray(save.remnantDefeated)) save.remnantDefeated = [];
  if (!save.remnantDefeated.includes(remnantId)) {
    save.remnantDefeated.push(remnantId);
  }
  writeSave(save);
}

export function markSingularityComplete() {
  const save = loadSave();
  save.singularityComplete = true;
  save.singularityProgress.finalBossPhase = 4;
  save.singularityProgress.replayCounts['the_singularity'] =
    (save.singularityProgress.replayCounts['the_singularity'] || 0) + 1;
  if (save.dragons.light && !save.dragons.light.owned) {
    save.dragons.light.owned = true;
    save.dragons.light.discovered = true;
  }
  writeSave(save);
}

export function addCore(element, count = 1) {
  const save = loadSave();
  if (!save.inventory.cores[element]) save.inventory.cores[element] = 0;
  save.inventory.cores[element] = Math.min(99, (save.inventory.cores[element] || 0) + count);
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
  offspringLevel = Math.min(offspringLevel, 50);
  // Consume the parents but KEEP `discovered` — they were collected, so collection-count
  // milestones must not regress when fusion flips them back to unowned.
  save.dragons[parentAId] = { ...save.dragons[parentAId], level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null, discovered: true };
  save.dragons[parentBId] = { ...save.dragons[parentBId], level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null, discovered: true };
  save.dragons[offspringElement] = {
    ...save.dragons[offspringElement],
    level: offspringLevel,
    xp: offspringXp,
    owned: true,
    discovered: true,
    shiny: offspringShiny,
    fusedBaseStats,
  };
  save.dataScraps -= 100;
  save.stats.fusionsCompleted = (save.stats.fusionsCompleted || 0) + 1;
  if (!Array.isArray(save.fusionLineage)) save.fusionLineage = [];
  save.fusionLineage.push({ parentA: parentAId, parentB: parentBId, offspring: offspringElement, offspringLevel });
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

function getYesterdaySeed() {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
}

export function completeDailyChallenge(seed) {
  const save = loadSave();
  const yesterdaySeed = getYesterdaySeed();
  save.dailyStreak = save.lastDailyCompleted === yesterdaySeed ? (save.dailyStreak || 0) + 1 : 1;
  save.lastDailyCompleted = seed;
  writeSave(save);
}

// New Game+: after a true-final clear, re-lock the campaign + Singularity for
// another, harder run while KEEPING the collection (dragons, scraps, cores,
// milestones, records, stats, skye). save.ngPlus scales enemies + rewards.
// Pure so the reset semantics can be unit-tested.
export function applyNewGamePlus(save) {
  save.ngPlus = (save.ngPlus || 0) + 1;
  save.defeatedNpcs = [];
  save.singularityProgress = { defeated: [], finalBossPhase: 0, replayCounts: {} };
  save.singularityComplete = false;
  save.mirrorAdminDefeated = false;
  save.remnantDefeated = [];
  save.flags = { ...(save.flags || {}), currentAct: 1, fragmentsUnlocked: [] };
  return save;
}

export function startNewGamePlus() {
  const save = loadSave();
  if (!save.mirrorAdminDefeated) return false; // only offered after a true-final clear
  applyNewGamePlus(save);
  writeSave(save);
  return true;
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

export function upgradeWrench(nextTier, nextSlots, cost) {
  const save = loadSave();
  if (save.dataScraps < cost) return false;
  save.dataScraps -= cost;
  save.skye.wrenchTier = nextTier;
  save.skye.relicSlots = nextSlots;
  writeSave(save);
  return true;
}

export function incrementBountiesCleared() {
  const save = loadSave();
  save.skye.bountiesCleared = (save.skye.bountiesCleared || 0) + 1;
  writeSave(save);
}

export function setLastZone(zone) {
  const save = loadSave();
  save.flags.lastZone = zone ?? null;
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
