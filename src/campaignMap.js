export const CAMPAIGN_NODES = [
  {
    id: 'signal-breach',
    label: 'Signal Breach',
    description: 'A corrupted firewall blinks at the edge of the matrix.',
    npcId: 'firewall_sentinel',
    type: 'normal',
    element: 'stone',
    difficulty: 'Easy',
    position: { x: 10, y: 62 },
    prerequisiteIds: [],
    rewardPreview: '25 XP · 30 DataScraps · Stone core chance',
  },
  {
    id: 'overflow-vent',
    label: 'Overflow Vent',
    description: 'Heat vents spit unstable packets into the forge route.',
    npcId: 'buffer_overflow',
    type: 'normal',
    element: 'fire',
    difficulty: 'Easy',
    position: { x: 24, y: 45 },
    prerequisiteIds: ['signal-breach'],
    rewardPreview: '30 XP · 40 DataScraps · Fire core chance',
  },
  {
    id: 'wraith-cache',
    label: 'Wraith Cache',
    description: 'A shadow process guards a forgotten memory cache.',
    npcId: 'bit_wraith',
    type: 'normal',
    element: 'shadow',
    difficulty: 'Medium',
    position: { x: 39, y: 60 },
    prerequisiteIds: ['signal-breach'],
    rewardPreview: '40 XP · 50 DataScraps · Shadow core chance',
  },
  {
    id: 'crypto-lock',
    label: 'Crypto Lock',
    description: 'Frozen ciphers seal the route toward the inner gates.',
    npcId: 'crypto_crab',
    type: 'elite',
    element: 'ice',
    difficulty: 'Medium',
    position: { x: 52, y: 35 },
    prerequisiteIds: ['overflow-vent'],
    rewardPreview: '45 XP · 60 DataScraps · Ice core chance',
  },
  {
    id: 'siren-loop',
    label: 'Siren Loop',
    description: 'A venomous lure repeats through the damaged signal lanes.',
    npcId: 'phishing_siren',
    type: 'elite',
    element: 'venom',
    difficulty: 'Medium',
    position: { x: 55, y: 70 },
    prerequisiteIds: ['wraith-cache'],
    rewardPreview: '50 XP · 70 DataScraps · Venom core chance',
  },
  {
    id: 'hydra-spine',
    label: 'Hydra Spine',
    description: 'Storm forks crawl through a three-headed glitch spine.',
    npcId: 'glitch_hydra',
    type: 'elite',
    element: 'storm',
    difficulty: 'Hard',
    position: { x: 70, y: 48 },
    prerequisiteIds: ['crypto-lock', 'siren-loop'],
    rewardPreview: '60 XP · 80 DataScraps · Storm core chance',
  },
  {
    id: 'logic-core',
    label: 'Logic Core',
    description: 'An armed logic bomb pulses inside a cracked processor vault.',
    npcId: 'logic_bomb',
    type: 'elite',
    element: 'fire',
    difficulty: 'Hard',
    position: { x: 82, y: 31 },
    prerequisiteIds: ['hydra-spine'],
    rewardPreview: '65 XP · 90 DataScraps · Fire core chance',
  },
  {
    id: 'recursive-gate',
    label: 'Recursive Gate',
    description: 'A stone recursion locks the first boss gate in place.',
    npcId: 'recursive_golem',
    type: 'boss',
    element: 'stone',
    difficulty: 'Boss',
    position: { x: 88, y: 62 },
    prerequisiteIds: ['hydra-spine'],
    rewardPreview: '80 XP · 120 DataScraps · Boss core chance',
  },
  {
    id: 'protocol-perch',
    label: 'Protocol Perch',
    description: 'The route ends beneath a shadow protocol watching from above.',
    npcId: 'protocol_vulture',
    type: 'boss',
    element: 'shadow',
    difficulty: 'Boss',
    position: { x: 96, y: 45 },
    prerequisiteIds: ['logic-core', 'recursive-gate'],
    rewardPreview: 'Boss XP · DataScraps · Singularity pressure reduced',
  },
];

export function isCampaignNodeCleared(node, save) {
  if (!node) return false;
  const clearedNodeIds = save?.campaign?.clearedNodeIds || [];
  const defeatedNpcs = save?.defeatedNpcs || [];
  return clearedNodeIds.includes(node.id) || defeatedNpcs.includes(node.npcId);
}

export function getCampaignNodeState(node, save) {
  if (isCampaignNodeCleared(node, save)) return 'cleared';

  const prerequisitesMet = node.prerequisiteIds.every((id) => {
    const prerequisite = CAMPAIGN_NODES.find((candidate) => candidate.id === id);
    return isCampaignNodeCleared(prerequisite, save);
  });

  return prerequisitesMet ? 'available' : 'locked';
}

export function getCampaignNodeStates(save) {
  return Object.fromEntries(
    CAMPAIGN_NODES.map((node) => [node.id, getCampaignNodeState(node, save)])
  );
}

export function getAvailableCampaignNodes(save) {
  return CAMPAIGN_NODES.filter((node) => getCampaignNodeState(node, save) === 'available');
}

export function getCampaignNodeById(nodeId) {
  return CAMPAIGN_NODES.find((node) => node.id === nodeId) || null;
}
