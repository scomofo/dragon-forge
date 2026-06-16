import { dragons, stageMultipliers } from './gameData';
import { calculateStatsForLevel, getStageForLevel } from './battleEngine';

const BASE_ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow'];
const BASE_NPC_IDS = ['firewall_sentinel', 'bit_wraith', 'glitch_hydra', 'recursive_golem'];

export const STAGES = [
  { stage: 0, name: 'Dormant', description: 'The Elemental Matrix is stable.' },
  { stage: 1, name: 'Anomaly Detected', description: 'Strange readings in the Matrix.' },
  { stage: 2, name: 'Signal Growing', description: 'Something is feeding on elemental energy.' },
  { stage: 3, name: 'Matrix Unstable', description: 'The Matrix is destabilizing.' },
  { stage: 4, name: 'Breach Imminent', description: 'Defenses are failing.' },
  { stage: 5, name: 'The Singularity', description: 'The Singularity has breached the Matrix.' },
];

export function getSingularityStage(save) {
  if (save.singularityComplete) return 0;
  const ownedCount = BASE_ELEMENTS.filter(el => save.dragons[el]?.owned).length;
  const hasElder = Object.values(save.dragons).some(d => d.owned && d.level >= 50);
  const defeatedNpcs = save.defeatedNpcs || [];
  const allNpcsDefeated = BASE_NPC_IDS.every(id => defeatedNpcs.includes(id));

  if (allNpcsDefeated) return 5;
  if (hasElder) return 4;
  if (ownedCount >= 6) return 3;
  if (ownedCount >= 4) return 2;
  if (ownedCount >= 2) return 1;
  return 0;
}

export function isSingularityUnlocked(save) {
  if (save.singularityComplete) return true;
  const defeatedNpcs = save.defeatedNpcs || [];
  return defeatedNpcs.includes('protocol_vulture');
}

export function getRemnantProgress(save) {
  const available = save.singularityComplete === true;
  const defeated = Array.isArray(save.remnantDefeated) ? save.remnantDefeated : [];
  const allDefeated =
    defeated.includes('data_corruption_remnant') &&
    defeated.includes('memory_leak_remnant') &&
    defeated.includes('stack_overflow_remnant');
  return { available, defeated, allDefeated };
}

// --- Post-game difficulty knobs (tunable; tweak after playtesting) ---
// Player hits to clear ONE boss phase. Fewer for multi-phase bosses so the
// total fight (player HP carries across phases) stays a reasonable length.
const phasePlayerTtk = (phaseCount) => (phaseCount >= 3 ? 3 : phaseCount === 2 ? 4 : 6);
// The boss needs ~this multiple of the player's total clear-turns to KO them,
// so the player wins with a margin (>1 = player-favoured; lower = harder).
const BOSS_SURVIVAL_MARGIN = 1.8;
const REPLAY_STEP = 0.1; // each repeat clear adds this much HP+ATK ...
const REPLAY_CAP = 0.5;  // ... capped here, so replays get harder, not free.

// Fixed-TTK boss scaling: set boss HP and ATK from the player's ACTUAL damage
// output and HP so the fight lasts ~the same number of turns at any player
// level (the audit's "target a fixed TTK, decoupled from level" goal), instead
// of inflating HP into a damage sponge the player one-shots anyway.
export function scaleBossForPlayer(boss, save) {
  // Player baseline = their strongest (highest-level) owned dragon — the likely pick.
  const owned = Object.entries(save.dragons || {}).filter(([, d]) => d.owned);
  let pLevel = boss.level || 30;
  let pStats;
  if (owned.length) {
    const [repId, repD] = owned.reduce((best, cur) => (cur[1].level > best[1].level ? cur : best));
    pLevel = repD.level;
    const base = repD.fusedBaseStats || dragons[repId]?.baseStats || { hp: 100, atk: 30, def: 20, spd: 20 };
    pStats = calculateStatsForLevel(base, repD.level, repD.shiny);
  } else {
    pStats = calculateStatsForLevel({ hp: 100, atk: 30, def: 20, spd: 20 }, pLevel);
  }
  const pStageMult = stageMultipliers[getStageForLevel(pLevel)] ?? 1.0;
  // Representative neutral player damage per hit (avg move power ~1.0; type/crit/def ignored).
  const estPlayerDmg = Math.max(1, pStats.atk * pStageMult * 2);

  const replays = save.singularityProgress?.replayCounts?.[boss.id] || 0;
  const replayMult = 1 + Math.min(REPLAY_CAP, replays * REPLAY_STEP);

  const phaseCount = boss.phases ? boss.phases.length : 1;
  const perPhaseTtk = phasePlayerTtk(phaseCount);
  const bossTtk = perPhaseTtk * phaseCount * BOSS_SURVIVAL_MARGIN;
  const targetBossDmg = pStats.hp / bossTtk;
  // The boss attacks at stageMult 1.0 (no stage on the boss). Invert
  // dmg = atk*1.0*1.0*2 - playerDef*0.5  for the ATK it needs to hit targetBossDmg.
  const targetBossAtk = Math.max(1, (targetBossDmg + pStats.def * 0.5) / 2);

  const buildStats = (stats, hpWeight, atkWeight) => ({
    hp:  Math.max(1, Math.round(perPhaseTtk * estPlayerDmg * hpWeight * replayMult)),
    atk: Math.max(1, Math.round(targetBossAtk * atkWeight * replayMult)),
    def: stats.def,
    spd: stats.spd,
  });

  if (boss.phases) {
    const avgHp = (boss.phases.reduce((s, p) => s + p.stats.hp, 0) / phaseCount) || 1;
    const avgAtk = (boss.phases.reduce((s, p) => s + p.stats.atk, 0) / phaseCount) || 1;
    const scaledPhases = boss.phases.map((phase) => ({
      ...phase,
      level: Math.max(phase.level, pLevel),
      stats: buildStats(phase.stats, phase.stats.hp / avgHp, phase.stats.atk / avgAtk),
    }));
    return { ...boss, phases: scaledPhases };
  }

  return { ...boss, level: Math.max(boss.level, pLevel), stats: buildStats(boss.stats, 1, 1) };
}
