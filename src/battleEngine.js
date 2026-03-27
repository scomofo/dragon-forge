import { typeChart, stageMultipliers, stageThresholds, moves as allMoves, STATUS_EFFECTS, STATUS_APPLY_CHANCE } from './gameData';

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

export function applyStatus(moveElement) {
  const effect = STATUS_EFFECTS[moveElement];
  if (!effect) return null;
  return { effect: moveElement, turnsLeft: effect.duration };
}

export function processStatusTick(combatantState) {
  if (!combatantState.status) {
    return { ...combatantState, statusEvent: null };
  }

  const effect = STATUS_EFFECTS[combatantState.status.effect];
  let hp = combatantState.hp;
  let damage = 0;
  const turnsLeft = combatantState.status.turnsLeft - 1;
  const expired = turnsLeft <= 0;

  if (effect.type === 'dot') {
    damage = Math.max(1, Math.floor(combatantState.maxHp * effect.value));
    hp = Math.max(0, hp - damage);
  }

  return {
    ...combatantState,
    hp,
    status: expired ? null : { ...combatantState.status, turnsLeft },
    statusEvent: {
      type: effect.type,
      damage,
      effectName: effect.name,
      expired,
    },
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
    (t) => { if (first.label === 'player') npc = t; else player = t; },
    (s) => { if (first.label === 'player') player = s; else npc = s; }
  );

  // Check if target is KO'd
  const firstTarget = first.label === 'player' ? npc : player;
  if (firstTarget.hp > 0) {
    second.state = second.label === 'player' ? player : npc;

    resolveAction(second, events,
      () => second.label === 'player' ? npc : player,
      (t) => { if (second.label === 'player') npc = t; else player = t; },
      (s) => { if (second.label === 'player') player = s; else npc = s; }
    );
  }

  // Process status ticks at end of turn (if alive)
  if (player.hp > 0 && player.status) {
    const playerTick = processStatusTick({ ...player, maxHp: playerState.maxHp || player.maxHp });
    player = { ...player, hp: playerTick.hp, status: playerTick.status };
    if (playerTick.statusEvent) {
      events.push({ attacker: 'status', target: 'player', ...playerTick.statusEvent });
    }
  }
  if (npc.hp > 0 && npc.status) {
    const npcTick = processStatusTick({ ...npc, maxHp: npcState.maxHp || npc.maxHp });
    npc = { ...npc, hp: npcTick.hp, status: npcTick.status };
    if (npcTick.statusEvent) {
      events.push({ attacker: 'status', target: 'npc', ...npcTick.statusEvent });
    }
  }

  return { player, npc, events };
}

function resolveAction(actor, events, getTarget, setTarget, setSelf) {
  // Check for Freeze — skip entirely
  if (actor.state.status?.effect === 'ice') {
    events.push({
      attacker: actor.label,
      action: 'statusSkip',
      statusName: 'Freeze',
    });
    return;
  }

  // Check for Paralyze — 50% chance to skip
  if (actor.state.status?.effect === 'storm') {
    if (Math.random() < STATUS_EFFECTS.storm.value) {
      events.push({
        attacker: actor.label,
        action: 'statusSkip',
        statusName: 'Paralyze',
      });
      return;
    }
  }

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

  // Apply Guard Break debuff to effective DEF
  let effectiveDef = target.def;
  if (target.status?.effect === 'stone') {
    effectiveDef = Math.floor(effectiveDef * (1 - STATUS_EFFECTS.stone.value));
  }

  // Apply Blind debuff to effective accuracy
  let effectiveAccuracy = move.accuracy;
  if (actor.state.status?.effect === 'shadow') {
    effectiveAccuracy = Math.max(0, effectiveAccuracy - STATUS_EFFECTS.shadow.value * 100);
  }

  const result = calculateDamage(
    { atk: actor.state.atk, element: actor.state.element, stage: actor.state.stage },
    { def: effectiveDef, element: target.element, defending: target.defending },
    { ...move, accuracy: effectiveAccuracy }
  );

  const newTargetHp = Math.max(0, target.hp - result.damage);
  setTarget({ ...target, hp: newTargetHp });

  // Status application roll
  let appliedStatus = null;
  if (result.hit && move.canApplyStatus && Math.random() < STATUS_APPLY_CHANCE) {
    appliedStatus = applyStatus(move.element);
    if (appliedStatus) {
      const updatedTarget = getTarget();
      setTarget({ ...updatedTarget, status: appliedStatus });
    }
  }

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
    appliedStatus: appliedStatus ? STATUS_EFFECTS[appliedStatus.effect].name : null,
  });
}
