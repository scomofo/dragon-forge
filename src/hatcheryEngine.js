import { rarityTiers, SHINY_CHANCE, PITY_THRESHOLD } from './gameData';
import { applyDragonXp } from './persistence';

export function rollRarity(pityCounter) {
  if (pityCounter >= PITY_THRESHOLD - 1) {
    const rareAndAbove = rarityTiers.filter(t => t.name === 'Rare' || t.name === 'Exotic');
    const totalChance = rareAndAbove.reduce((sum, t) => sum + t.chance, 0);
    let roll = Math.random() * totalChance;
    for (const tier of rareAndAbove) {
      roll -= tier.chance;
      if (roll <= 0) return tier;
    }
    return rareAndAbove[rareAndAbove.length - 1];
  }

  let roll = Math.random();
  for (const tier of rarityTiers) {
    roll -= tier.chance;
    if (roll <= 0) return tier;
  }
  return rarityTiers[rarityTiers.length - 1];
}

export function rollElement(rarityTier) {
  const elements = rarityTier.elements;
  return elements[Math.floor(Math.random() * elements.length)];
}

export function rollShiny(guaranteedShiny) {
  if (guaranteedShiny) return true;
  return Math.random() < SHINY_CHANCE;
}

export function executePull(pityCounter) {
  const rarityTier = rollRarity(pityCounter);
  const element = rollElement(rarityTier);
  const shiny = rollShiny(!!rarityTier.guaranteedShiny);

  const isRarePlus = rarityTier.name === 'Rare' || rarityTier.name === 'Exotic';
  const newPityCounter = isRarePlus ? 0 : pityCounter + 1;

  return {
    element,
    rarityName: rarityTier.name,
    rarityMultiplier: rarityTier.multiplier,
    shiny,
    newPityCounter,
  };
}

// Void Egg pull: fully deterministic — the forged egg hatches into a shiny
// Void Dragon, no RNG. Same shape as executePull so the ceremony + apply path
// are identical (Exotic telegraphing included).
export function executeVoidEggPull() {
  return {
    element: 'void',
    rarityName: 'Exotic',
    rarityMultiplier: 5,
    shiny: true,
    newPityCounter: 0,
  };
}

export function applyPullResult(save, pull) {
  const newSave = structuredClone(save);
  const dragon = newSave.dragons[pull.element];
  let isNew = false;
  let xpGained = 0;

  if (!dragon.owned) {
    dragon.owned = true;
    dragon.discovered = true;
    if (pull.shiny) dragon.shiny = true;
    isNew = true;
  } else {
    xpGained = 50 * pull.rarityMultiplier;
    applyDragonXp(dragon, xpGained); // one canonical XP curve (see persistence.js)
    if (pull.shiny && !dragon.shiny) {
      dragon.shiny = true;
    }
  }

  newSave.pityCounter = pull.newPityCounter;

  return { save: newSave, isNew, xpGained };
}

// === RARITY-TELEGRAPHED CEREMONY ===
// The pull is rolled before the hatch animation starts, so the ceremony can
// telegraph the tier: glow color, extra shake escalation, a hold-your-breath
// beat before the burst, and a post-reveal stinger. Pure data so the screen
// stays a shell and the escalation is unit-testable.
const RARITY_CEREMONY = {
  Common:   { glow: null,      extraShakes: 0, holdMs: 0,   stinger: null },
  Uncommon: { glow: '#44aaff', extraShakes: 0, holdMs: 0,   stinger: null },
  Rare:     { glow: '#aa66ff', extraShakes: 2, holdMs: 250, stinger: 'levelUp' },
  Exotic:   { glow: '#ffcc00', extraShakes: 4, holdMs: 600, stinger: 'journalUnlock' },
};

export function getRarityCeremony(rarityName) {
  return RARITY_CEREMONY[rarityName] || RARITY_CEREMONY.Common;
}

// 10-pull grid: order cards so the most exciting pull lands last (genre
// convention), keeping pull order within ties (stable sort). Pure.
export function rankPullExcitement({ pull, apply }) {
  return (pull.rarityMultiplier || 1) * 10 + (pull.shiny ? 5 : 0) + (apply?.isNew ? 2 : 0);
}

export function orderGridResults(results) {
  return [...results].sort((a, b) => rankPullExcitement(a) - rankPullExcitement(b));
}
