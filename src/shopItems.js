export const ELEMENTS_FOR_CORES = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow'];

export const CORE_DROP_CHANCE = 0.6; // 60% chance per battle win
export const CORE_DOUBLE_CHANCE = 0.2; // 20% chance for 2 cores instead of 1

export const BUY_ITEMS = [
  {
    id: 'xp_booster',
    name: 'XP Booster',
    description: 'Next 3 battles give 2x XP',
    cost: 150,
    icon: '⚡',
    effect: 'xpBoost',
    stackable: true,
  },
  {
    id: 'shiny_charm',
    name: 'Shiny Charm',
    description: 'Upgrade one owned dragon to shiny',
    cost: 500,
    icon: '✨',
    effect: 'shinyUpgrade',
    stackable: false,
    requiresTarget: true,
  },
  {
    id: 'pity_reset',
    name: 'Pity Reset',
    description: 'Next hatchery pull guaranteed Rare+',
    cost: 100,
    icon: '🎯',
    effect: 'pityReset',
    stackable: false,
  },
  {
    id: 'element_reroll',
    name: 'Element Reroll',
    description: 'Re-roll a dragon\'s fused base stats',
    cost: 200,
    icon: '🔄',
    effect: 'reroll',
    stackable: false,
    requiresTarget: true,
    requiresFused: true,
  },
  {
    id: 'data_fragment',
    name: 'Data Fragment',
    description: 'Grants 50 XP to a chosen dragon',
    cost: 50,
    icon: '💎',
    effect: 'grantXp',
    xpAmount: 50,
    stackable: false,
    requiresTarget: true,
  },
];

export const FORGE_RECIPES = [
  {
    id: 'dragon_essence',
    name: 'Dragon Essence',
    description: 'Grants 200 XP to a dragon of the core\'s element',
    cores: { same: 3 }, // 3 of the same element
    scrapsCost: 0,
    icon: '🧬',
    effect: 'grantXpElement',
    xpAmount: 200,
  },
  {
    id: 'stability_matrix',
    name: 'Stability Matrix',
    description: 'Next fusion has +1 stability tier',
    cores: { different: 3 }, // 3 different elements
    scrapsCost: 100,
    icon: '🔮',
    effect: 'stabilityBoost',
  },
  {
    id: 'elder_shard',
    name: 'Elder Shard',
    description: 'Grants 500 XP to any dragon',
    cores: { any: 5 }, // any 5 cores
    scrapsCost: 300,
    icon: '💠',
    effect: 'grantXp',
    xpAmount: 500,
  },
  {
    id: 'void_fragment',
    name: 'Void Fragment',
    description: 'Free Exotic hatchery pull',
    cores: { allSix: true }, // 1 of each of 6 elements
    scrapsCost: 500,
    icon: '🌀',
    effect: 'exoticPull',
  },
];

export function canAffordBuy(item, save) {
  return save.dataScraps >= item.cost;
}

export function canForge(recipe, save) {
  const inv = save.inventory || {};
  const cores = inv.cores || {};

  if (save.dataScraps < recipe.scrapsCost) return false;

  if (recipe.cores.same) {
    return ELEMENTS_FOR_CORES.some(el => (cores[el] || 0) >= recipe.cores.same);
  }
  if (recipe.cores.different) {
    const owned = ELEMENTS_FOR_CORES.filter(el => (cores[el] || 0) >= 1);
    return owned.length >= recipe.cores.different;
  }
  if (recipe.cores.any) {
    const total = ELEMENTS_FOR_CORES.reduce((sum, el) => sum + (cores[el] || 0), 0);
    return total >= recipe.cores.any;
  }
  if (recipe.cores.allSix) {
    return ELEMENTS_FOR_CORES.every(el => (cores[el] || 0) >= 1);
  }
  return false;
}

export function getForgeableElement(recipe, save) {
  if (!recipe.cores.same) return null;
  const cores = save.inventory?.cores || {};
  return ELEMENTS_FOR_CORES.find(el => (cores[el] || 0) >= recipe.cores.same) || null;
}
