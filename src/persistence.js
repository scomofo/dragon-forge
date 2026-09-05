// @ts-nocheck
import { canEquipRelic } from './forgeData';
import { applyOuterGridAction, getOuterGridProgress } from './outerGrid';
import { applyFrozenCacheAction, getFrozenCacheProgress } from './frozenCache';
import { applyStormSpineAction, getStormSpineProgress } from './stormSpine';
import { applyAdminCoreAction, getAdminCoreProgress } from './adminCore';
import { isExpeditionAvailable } from './expeditions';

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
  outerGrid: getOuterGridProgress({}),
  frozenCache: getFrozenCacheProgress({}),
  stormSpine: getStormSpineProgress({}),
  adminCore: getAdminCoreProgress({}),
  singularityProgress: { defeated: [], finalBossPhase: 0, replayCounts: {} },
  singularityComplete: false,
  mirrorAdminDefeated: false,
  remnantDefeated: [],
  fusionLineage: [],
  bestRanks: {},
  inventory: { cores: {}, xpBoostBattles: 0, stabilityBoost: false },
  stats: { battlesWon: 0, battlesLost: 0, totalScrapsEarned: 0, totalPulls: 0, fusionsCompleted: 0 },
  lastDailyCompleted: 0,
  dailyStreak: 0,
  introSeen: false,
  ngPlus: 0,
  // Engagement telemetry: when they first booted, when they were last here,
  // how many sessions, and how long they've played. Drives the Stats screen
  // and the welcome-back beat.
  activity: { firstPlayed: null, lastPlayed: null, sessions: 0, playtimeMs: 0 },
  records: { fastestWin: null, highestDamage: 0, longestStreak: 0, currentStreak: 0 },
  flags: {
    currentAct: 1,
    metFelix: false,
    felixGreeted: false,
    lastZone: null,
    activeExpedition: null,
    fragmentsUnlocked: [],
    journalBriefingSeen: false,
    felixStageHeard: 0,
    felixIrisHeard: false,
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
  if (save.bestRanks === undefined || save.bestRanks === null) save.bestRanks = {};
  // Light Dragon is the Singularity completion reward; grant retroactively to finishers.
  if (save.singularityComplete && !save.dragons.light.owned) {
    save.dragons.light.owned = true;
    save.dragons.light.discovered = true;
  }
  if (save.inventory === undefined) {
    save.inventory = { cores: {}, xpBoostBattles: 0, stabilityBoost: false };
  }
  if (save.inventory.voidEgg === undefined) save.inventory.voidEgg = false;
  if (save.stats === undefined) {
    save.stats = { battlesWon: 0, battlesLost: 0, totalScrapsEarned: 0, totalPulls: 0, fusionsCompleted: 0 };
  }
  if (save.lastDailyCompleted === undefined) save.lastDailyCompleted = 0;
  if (save.activity === undefined) save.activity = { firstPlayed: null, lastPlayed: null, sessions: 0, playtimeMs: 0 };
  if (save.activity.firstPlayed === undefined) save.activity.firstPlayed = null;
  if (save.activity.lastPlayed === undefined) save.activity.lastPlayed = null;
  if (save.activity.sessions === undefined) save.activity.sessions = 0;
  if (save.activity.playtimeMs === undefined) save.activity.playtimeMs = 0;
  if (save.records === undefined) save.records = { fastestWin: null, highestDamage: 0, longestStreak: 0, currentStreak: 0 };
  if (save.flags === undefined) {
    save.flags = { currentAct: 1, metFelix: false, felixGreeted: false, lastZone: null, fragmentsUnlocked: [], journalBriefingSeen: false, felixStageHeard: 0, felixIrisHeard: false };
  } else {
    if (save.flags.currentAct === undefined) save.flags.currentAct = 1;
    if (save.flags.metFelix === undefined) save.flags.metFelix = false;
    if (save.flags.felixGreeted === undefined) save.flags.felixGreeted = false;
    if (save.flags.lastZone === undefined) save.flags.lastZone = null;
    if (!Array.isArray(save.flags.fragmentsUnlocked)) save.flags.fragmentsUnlocked = [];
    if (save.flags.journalBriefingSeen === undefined) save.flags.journalBriefingSeen = false;
    if (save.flags.felixStageHeard === undefined) save.flags.felixStageHeard = 0;
    if (save.flags.felixIrisHeard === undefined) save.flags.felixIrisHeard = false;
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
  save.outerGrid = getOuterGridProgress(save);
  save.frozenCache = getFrozenCacheProgress(save);
  save.stormSpine = getStormSpineProgress(save);
  save.adminCore = getAdminCoreProgress(save);
  if (!isExpeditionAvailable(save.flags.activeExpedition, save)) save.flags.activeExpedition = null;
  return save;
}

export function loadSave() {
  try {
    if (typeof window === 'undefined' || !window.localStorage) {
      return structuredClone(DEFAULT_SAVE);
    }
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return structuredClone(DEFAULT_SAVE);
    return migrateSave(JSON.parse(raw));
  } catch {
    return structuredClone(DEFAULT_SAVE);
  }
}

export function writeSave(save) {
  if (typeof window === 'undefined' || !window.localStorage) return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(save));
}

export function rememberExpedition(screen) {
  const save = loadSave();
  if (!isExpeditionAvailable(screen, save) || save.flags.activeExpedition === screen) return false;
  save.flags.activeExpedition = screen;
  writeSave(save);
  return true;
}

function actInExpedition(screen, applyAction, action, value) {
  const save = loadSave();
  const next = applyAction(save, action, value);
  if (next === save) return false;
  writeSave({ ...next, flags: { ...next.flags, activeExpedition: screen } });
  return true;
}

export function actInOuterGrid(action, value) {
  return actInExpedition('outerGrid', applyOuterGridAction, action, value);
}

export function actInFrozenCache(action, value) {
  return actInExpedition('frozenCache', applyFrozenCacheAction, action, value);
}

export function actInStormSpine(action, value) {
  return actInExpedition('stormSpine', applyStormSpineAction, action, value);
}

export function actInAdminCore(action, value) {
  return actInExpedition('adminCore', applyAdminCoreAction, action, value);
}

export function meltCores(count = 10, scraps = 250) {
  const save = loadSave();
  const cores = save.inventory?.cores || {};
  let remaining = count;
  for (const el of Object.keys(cores)) {
    if (remaining <= 0) break;
    const take = Math.min(cores[el] || 0, remaining);
    if (take > 0) {
      cores[el] -= take;
      remaining -= take;
    }
  }
  if (remaining > 0) return false;
  save.inventory.cores = cores;
  save.dataScraps += scraps;
  writeSave(save);
  return true;
}

export function addScraps(amount) {
  const save = loadSave();
  save.dataScraps += amount;
  writeSave(save);
}

// Battle-rank skill bonus: S/A/B pay a flat scrap bonus so clean, fast fights
// are worth more than slow ones. Pure so the bonus tiers are unit-testable.
export function getRankBonusScraps(rank) {
  if (rank === 'S') return 15;
  if (rank === 'A') return 8;
  if (rank === 'B') return 4;
  return 0;
}

// Best-rank persistence: each NPC's highest military rank is recorded so the
// campaign map / battle select can show S-rank ribbons and the rank-perfect
// milestone has a counting source. S > A > B > C ordering.
const RANK_ORDER = ['C', 'B', 'A', 'S'];

// Pure comparator — testable without storage.
export function getUpgradedRank(current, next) {
  if (!current) return next;
  return RANK_ORDER.indexOf(next) > RANK_ORDER.indexOf(current) ? next : current;
}

export function recordBattleRank(npcId, rank) {
  const save = loadSave();
  if (!save.bestRanks) save.bestRanks = {};
  save.bestRanks[npcId] = getUpgradedRank(save.bestRanks[npcId], rank);
  writeSave(save);
}

export function getBestRanks(save) {
  return save?.bestRanks || {};
}

export function countSRanks(save) {
  return Object.values(save?.bestRanks || {}).filter(r => r === 'S').length;
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

// Void Egg: the deterministic Void chase. Forged from 5 of each core; the
// hatchery consumes it on the next pull for a guaranteed shiny Void Dragon.
export function setVoidEgg(value) {
  const save = loadSave();
  save.inventory.voidEgg = value;
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
  save.outerGrid = getOuterGridProgress({});
  save.frozenCache = getFrozenCacheProgress({});
  save.stormSpine = getStormSpineProgress({});
  save.adminCore = getAdminCoreProgress({});
  save.singularityProgress = { defeated: [], finalBossPhase: 0, replayCounts: {} };
  save.singularityComplete = false;
  save.mirrorAdminDefeated = false;
  save.remnantDefeated = [];
  save.flags = { ...(save.flags || {}), currentAct: 1, fragmentsUnlocked: [], activeExpedition: null };
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

// === ENGAGEMENT TELEMETRY / RETURN-PLAYER ===

// Whole calendar days between two timestamps (local time, matching the daily
// seed's local-day semantics). Pure for tests.
export function computeDaysAway(lastPlayed, now = Date.now()) {
  if (!lastPlayed) return 0;
  const last = new Date(lastPlayed);
  const cur = new Date(now);
  const lastDay = new Date(last.getFullYear(), last.getMonth(), last.getDate());
  const curDay = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate());
  return Math.max(0, Math.round((curDay - lastDay) / 86400000));
}

export function formatPlaytime(ms) {
  const minutes = Math.floor((ms || 0) / 60000);
  if (minutes < 1) return '<1m';
  const hours = Math.floor(minutes / 60);
  if (hours < 1) return `${minutes}m`;
  return `${hours}h ${minutes % 60}m`;
}

// Welcome-back grant: modest, scales with time away, capped. Pure for tests.
export function getWelcomeBackGrant(daysAway) {
  if (daysAway < 3) return 0;
  return Math.min(200, 50 + daysAway * 25);
}

// One session per page load (module flag survives StrictMode's double-effect
// in dev). Returns { daysAway, grant } from BEFORE this session stamped
// lastPlayed, so the caller can greet a returning player.
let sessionStarted = false;
export function beginSession() {
  if (sessionStarted) return { daysAway: 0, grant: 0 };
  sessionStarted = true;
  const save = loadSave();
  const now = Date.now();
  const daysAway = computeDaysAway(save.activity.lastPlayed, now);
  const hasProgress = (save.defeatedNpcs || []).length > 0 || (save.stats?.battlesWon || 0) > 0;
  const grant = hasProgress ? getWelcomeBackGrant(daysAway) : 0;
  save.activity.sessions++;
  if (!save.activity.firstPlayed) save.activity.firstPlayed = now;
  save.activity.lastPlayed = now;
  save.activity.sessionStart = now;
  writeSave(save);
  return { daysAway, grant };
}

// Separate write so the welcome-back grant can't get clobbered by a concurrent
// battle save (each persistence call load+writes the whole blob).
export function grantWelcomeBack(amount) {
  if (amount <= 0) return;
  const save = loadSave();
  save.dataScraps += amount;
  writeSave(save);
}

// Playtime accrues in heartbeats (App calls this on an interval and on unload).
export function accumulatePlaytime() {
  const save = loadSave();
  const start = save.activity.sessionStart;
  if (!start) return;
  const now = Date.now();
  save.activity.playtimeMs = (save.activity.playtimeMs || 0) + Math.max(0, now - start);
  save.activity.sessionStart = now;
  writeSave(save);
}
