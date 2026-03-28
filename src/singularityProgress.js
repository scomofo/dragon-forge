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
  if (save.singularityComplete) return 3;
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
  return BASE_NPC_IDS.every(id => defeatedNpcs.includes(id));
}
