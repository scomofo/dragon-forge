import { typeChart, stageMultipliers, stageThresholds, moves as allMoves } from './gameData';

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

export function calculateStatsForLevel(baseStats, level, shiny = false) {
  const bonus = (level - 1) * 3;
  const mult = shiny ? 1.2 : 1.0;
  return {
    hp:  Math.floor((baseStats.hp + bonus) * mult),
    atk: Math.floor((baseStats.atk + bonus) * mult),
    def: Math.floor((baseStats.def + bonus) * mult),
    spd: Math.floor((baseStats.spd + bonus) * mult),
  };
}

export function pickNpcMove(npcMoveKeys, npcElement, playerElement) {
  const availableKeys = [...npcMoveKeys, 'basic_attack'];

  // Find super-effective moves
  const superEffective = availableKeys.filter((key) => {
    const move = allMoves[key];
    return move && getTypeEffectiveness(move.element, playerElement) > 1.0;
  });

  // 70% chance to pick super-effective if available
  if (superEffective.length > 0 && Math.random() < 0.7) {
    return superEffective[Math.floor(Math.random() * superEffective.length)];
  }

  // Otherwise random from all available (excluding basic_attack 50% of the time)
  const preferred = npcMoveKeys.length > 0 && Math.random() < 0.5
    ? npcMoveKeys
    : availableKeys;
  return preferred[Math.floor(Math.random() * preferred.length)];
}

export function resolveTurn(playerState, npcState, playerMoveKey, npcMoveKey) {
  let player = { ...playerState, defending: false };
  let npc = { ...npcState, defending: false };
  const events = [];

  // Determine order by speed
  const playerFirst = player.spd >= npc.spd;

  const first = playerFirst
    ? { state: player, moveKey: playerMoveKey, label: 'player' }
    : { state: npc, moveKey: npcMoveKey, label: 'npc' };

  const second = playerFirst
    ? { state: npc, moveKey: npcMoveKey, label: 'npc' }
    : { state: player, moveKey: playerMoveKey, label: 'player' };

  // Resolve first attacker
  resolveAction(first, events,
    () => first.label === 'player' ? npc : player,
    (updatedTarget) => { if (first.label === 'player') npc = updatedTarget; else player = updatedTarget; },
    (updatedSelf) => { if (first.label === 'player') player = updatedSelf; else npc = updatedSelf; }
  );

  // Check if target is KO'd
  const firstTargetAfter = first.label === 'player' ? npc : player;
  if (firstTargetAfter.hp > 0) {
    // Update second actor's state reference before resolving
    second.state = second.label === 'player' ? player : npc;

    // Resolve second attacker
    resolveAction(second, events,
      () => second.label === 'player' ? npc : player,
      (updatedTarget) => { if (second.label === 'player') npc = updatedTarget; else player = updatedTarget; },
      (updatedSelf) => { if (second.label === 'player') player = updatedSelf; else npc = updatedSelf; }
    );
  }

  return { player, npc, events };
}

function resolveAction(actor, events, getTarget, setTarget, setSelf) {
  if (actor.moveKey === 'defend') {
    const updated = { ...actor.state, defending: true };
    setSelf(updated);
    events.push({
      attacker: actor.label,
      action: 'defend',
      damage: 0,
      effectiveness: 1.0,
      hit: true,
    });
    return;
  }

  const move = allMoves[actor.moveKey] || allMoves.basic_attack;
  const target = getTarget();
  const result = calculateDamage(
    { atk: actor.state.atk, element: actor.state.element, stage: actor.state.stage },
    { def: target.def, element: target.element, defending: target.defending },
    move
  );

  const newTargetHp = Math.max(0, target.hp - result.damage);
  setTarget({ ...target, hp: newTargetHp });

  events.push({
    attacker: actor.label,
    action: 'attack',
    moveName: move.name,
    moveKey: actor.moveKey,
    vfxKey: move.vfxKey,
    damage: result.damage,
    effectiveness: result.effectiveness,
    hit: result.hit,
    targetHp: newTargetHp,
  });
}
