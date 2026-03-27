import { typeChart, stageMultipliers, stageThresholds } from './gameData';

export function getTypeEffectiveness(attackerElement, defenderElement) {
  if (!typeChart[attackerElement]) return 1.0;
  return typeChart[attackerElement][defenderElement] ?? 1.0;
}

export function calculateDamage(attacker, defender, move) {
  // Accuracy check
  const accuracyRoll = Math.random() * 100;
  if (accuracyRoll > move.accuracy) {
    return { damage: 0, effectiveness: 1.0, hit: false };
  }

  const stageMult = stageMultipliers[attacker.stage] ?? 1.0;
  const baseDamage = (attacker.atk * stageMult * 2) - (defender.def * 0.5);
  const effectiveness = getTypeEffectiveness(move.element, defender.element);
  let typedDamage = baseDamage * effectiveness;

  if (defender.defending) {
    typedDamage *= 0.5;
  }

  const roll = 0.85 + Math.random() * 0.15;
  const finalDamage = Math.max(1, Math.floor(typedDamage * roll));

  return { damage: finalDamage, effectiveness, hit: true };
}

export function getStageForLevel(level) {
  if (level >= stageThresholds[4]) return 4;
  if (level >= stageThresholds[3]) return 3;
  if (level >= stageThresholds[2]) return 2;
  return 1;
}

export function calculateXpGain(baseXP, playerLevel, enemyLevel) {
  const ratio = enemyLevel / playerLevel;
  return Math.max(1, Math.floor(baseXP * ratio));
}

export function calculateStatsForLevel(baseStats, level) {
  const bonus = (level - 1) * 3;
  return {
    hp:  baseStats.hp + bonus,
    atk: baseStats.atk + bonus,
    def: baseStats.def + bonus,
    spd: baseStats.spd + bonus,
  };
}
