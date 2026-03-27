const ALCHEMY = {
  'fire_fire': 'fire',
  'ice_ice': 'ice',
  'storm_storm': 'storm',
  'stone_stone': 'stone',
  'venom_venom': 'venom',
  'shadow_shadow': 'shadow',
  'fire_ice': 'storm',
  'fire_storm': 'fire',
  'fire_stone': 'stone',
  'fire_venom': 'shadow',
  'fire_shadow': 'fire',
  'ice_storm': 'ice',
  'ice_stone': 'stone',
  'ice_venom': 'venom',
  'ice_shadow': 'shadow',
  'stone_storm': 'storm',
  'storm_venom': 'venom',
  'shadow_storm': 'shadow',
  'stone_venom': 'venom',
  'shadow_stone': 'stone',
  'shadow_venom': 'shadow',
};

const OPPOSING_PAIRS = [
  ['fire', 'ice'],
  ['storm', 'stone'],
  ['venom', 'shadow'],
];

function sortedKey(a, b) {
  return [a, b].sort().join('_');
}

export function getFusionElement(elementA, elementB) {
  return ALCHEMY[sortedKey(elementA, elementB)] || elementA;
}

export function getStabilityTier(elementA, elementB) {
  if (elementA === elementB) return 'stable';
  for (const [a, b] of OPPOSING_PAIRS) {
    if ((elementA === a && elementB === b) || (elementA === b && elementB === a)) {
      return 'unstable';
    }
  }
  return 'normal';
}

export function calculateFusionStats(statsA, statsB, stabilityTier) {
  const avg = {
    hp:  (statsA.hp + statsB.hp) / 2,
    atk: (statsA.atk + statsB.atk) / 2,
    def: (statsA.def + statsB.def) / 2,
    spd: (statsA.spd + statsB.spd) / 2,
  };

  let fused = {
    hp:  Math.floor(avg.hp * 1.1),
    atk: Math.floor(avg.atk * 1.1),
    def: Math.floor(avg.def * 1.1),
    spd: Math.floor(avg.spd * 1.1),
  };

  if (stabilityTier === 'stable') {
    fused = {
      hp:  Math.floor(fused.hp * 1.25),
      atk: Math.floor(fused.atk * 1.25),
      def: Math.floor(fused.def * 1.25),
      spd: Math.floor(fused.spd * 1.25),
    };
  } else if (stabilityTier === 'unstable') {
    fused.hp = Math.floor(fused.hp * 0.8);
    fused.atk = Math.floor(fused.atk * 1.1);
  }

  return fused;
}
