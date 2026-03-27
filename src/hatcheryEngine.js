import { rarityTiers, SHINY_CHANCE, PITY_THRESHOLD } from './gameData';

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
