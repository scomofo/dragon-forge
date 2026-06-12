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

export function scaleBossForPlayer(boss, save) {
  const playerMaxLevel = Object.values(save.dragons)
    .filter(d => d.owned)
    .reduce((max, d) => Math.max(max, d.level), 1);
  const replayCounts = save.singularityProgress?.replayCounts || {};
  const replayBonus = (replayCounts[boss.id] || 0) * 5;

  const scaleStats = (stats, factor) =>
    Object.fromEntries(Object.entries(stats).map(([k, v]) => [k, Math.floor(v * factor)]));

  if (boss.phases) {
    const baseLevel = boss.phases[0].level;
    const scaledBase = Math.max(baseLevel, playerMaxLevel) + replayBonus;
    const factor = scaledBase / baseLevel;
    const scaledPhases = boss.phases.map((phase, i) => ({
      ...phase,
      level: Math.max(phase.level, playerMaxLevel + i) + replayBonus,
      stats: scaleStats(phase.stats, factor),
    }));
    return { ...boss, phases: scaledPhases };
  }

  const scaledLevel = Math.max(boss.level, playerMaxLevel) + replayBonus;
  const factor = scaledLevel / boss.level;
  return { ...boss, level: scaledLevel, stats: scaleStats(boss.stats, factor) };
}
