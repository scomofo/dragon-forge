import { rarityTiers, SHINY_CHANCE, PITY_THRESHOLD, XP_OVERFLOW_SCRAP_RATE } from './gameData';
import { applyDragonXpWithOverflow, recordDiscovery } from './persistence';

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
  let scrapsGained = 0;

  if (!dragon.owned) {
    dragon.owned = true;
    dragon.discovered = true;
    recordDiscovery(newSave, pull.element);
    if (pull.shiny) dragon.shiny = true;
    isNew = true;
  } else {
    xpGained = 50 * pull.rarityMultiplier;
    const xpResult = applyDragonXpWithOverflow(dragon, xpGained); // one canonical XP curve (see persistence.js)
    // XP past the level-50 cap would otherwise vanish; convert it to
    // DataScraps at the stingy hatchery rate instead of discarding it.
    scrapsGained = Math.floor(xpResult.overflowXp / XP_OVERFLOW_SCRAP_RATE);
    if (scrapsGained > 0) {
      newSave.dataScraps = (newSave.dataScraps || 0) + scrapsGained;
    }
    if (pull.shiny && !dragon.shiny) {
      dragon.shiny = true;
    }
  }

  newSave.pityCounter = pull.newPityCounter;

  return { save: newSave, isNew, xpGained, scrapsGained };
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
  Exotic:   { glow: '#ffcc00', extraShakes: 4, holdMs: 900, stinger: 'journalUnlock' },
};

export function getRarityCeremony(rarityName) {
  return RARITY_CEREMONY[rarityName] || RARITY_CEREMONY.Common;
}

// === PITY-PULL RITUAL ===
// The pity-guaranteed pull (made with pityCounter == PITY_THRESHOLD - 1) gets
// its own ritual layered on top of the rarity ceremony: a hot-pink aura
// (distinct from the Exotic gold) plus an extra hold-your-breath beat before
// the burst. Pure data so the screen stays a shell, like the rarity ceremony.
const PITY_RITUAL = { glow: '#ff66aa', extraHoldMs: 600, css: 'egg-pity-glow' };
const NO_PITY_RITUAL = { glow: null, extraHoldMs: 0, css: '' };

export function getPityRitual(isPityPull) {
  return isPityPull ? PITY_RITUAL : NO_PITY_RITUAL;
}

// Pity countdown ring: fraction of the way to the guaranteed Rare+ pull
// (pityCounter / PITY_THRESHOLD), clamped to [0, 1].
export function getPityProgress(pityCounter) {
  return Math.min(1, Math.max(0, pityCounter / PITY_THRESHOLD));
}

// 10-pull grid: order cards so the most exciting pull lands last (genre
// convention), keeping pull order within ties (stable sort). Pure.
export function rankPullExcitement({ pull, apply }) {
  return (pull.rarityMultiplier || 1) * 10 + (pull.shiny ? 5 : 0) + (apply?.isNew ? 2 : 0);
}

export function orderGridResults(results) {
  return [...results].sort((a, b) => rankPullExcitement(a) - rankPullExcitement(b));
}
