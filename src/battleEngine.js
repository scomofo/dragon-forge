import { typeChart, stageMultipliers, stageThresholds, moves as allMoves, STATUS_EFFECTS, STATUS_APPLY_CHANCE } from './gameData';

export const CRIT_CHANCE = 0.10;
export const CRIT_MULTIPLIER = 1.5;

// Charged moves hit at this attack multiplier when their windup resolves.
export const CHARGE_ATK_MULTIPLIER = 1.4;
// Ceiling on combined attack-up sources (timed atkBuff × charged-move boost) so they
// can't multiply into a runaway spike — e.g. charge 1.4× × npc_focus 1.3× = 1.82×,
// which is reachable on phishing_siren / protocol_vulture. Clamped here to 1.5×.
export const MAX_ATK_MULTIPLIER = 1.5;

// Combine every attack-up source under MAX_ATK_MULTIPLIER. Pure + exported so the
// cap can be unit-tested directly (the effective-attack path is otherwise buried in
// resolveAction behind RNG damage rolls).
export function effectiveAttack(atk, atkBuff, chargeMultiplier = 1) {
  const buffMult = atkBuff?.multiplier ?? 1;
  const mult = Math.min(buffMult * chargeMultiplier, MAX_ATK_MULTIPLIER);
  return Math.floor(atk * mult);
}

export function getTypeEffectiveness(attackerElement, defenderElement) {
  if (!typeChart[attackerElement]) return 1.0;
  return typeChart[attackerElement][defenderElement] ?? 1.0;
}

export function getTypeEffectivenessLabel(attackerElement, defenderElement) {
  const effectiveness = getTypeEffectiveness(attackerElement, defenderElement);
  if (effectiveness > 1.0) return 'ADVANTAGE';
  if (effectiveness < 1.0) return 'RESISTED';
  return 'NORMAL';
}

export function calculateDamage(attacker, defender, move) {
  // Accuracy check
  const accuracyRoll = Math.random() * 100;
  if (accuracyRoll > move.accuracy) {
    return { damage: 0, effectiveness: 1.0, hit: false, isCritical: false };
  }

  const stageMult = stageMultipliers[attacker.stage] ?? 1.0;
  const powerScale = (move.power ?? 65) / 65;
  const baseDamage = (attacker.atk * stageMult * powerScale * 2) - (defender.def * 0.5);
  const effectiveness = getTypeEffectiveness(move.element, defender.element);
  let typedDamage = baseDamage * effectiveness;

  if (defender.defending) {
    typedDamage *= 0.5;
  }

  const roll = 0.85 + Math.random() * 0.15;
  let finalDamage = Math.max(1, Math.floor(typedDamage * roll));

  const isCritical = Math.random() < CRIT_CHANCE;
  if (isCritical) {
    finalDamage = Math.floor(finalDamage * CRIT_MULTIPLIER);
  }

  return { damage: finalDamage, effectiveness, hit: true, isCritical };
}

export function getStageForLevel(level) {
  if (level >= stageThresholds[4]) return 4;
  if (level >= stageThresholds[3]) return 3;
  if (level >= stageThresholds[2]) return 2;
  return 1;
}

export function calculateXpGain(baseXP, playerLevel, enemyLevel) {
  const ratio = Math.min(2, Math.max(0.25, enemyLevel / playerLevel));
  return Math.max(1, Math.floor(baseXP * ratio));
}

export function calculateStatsForLevel(baseStats, level, shiny = false) {
  const levels = level - 1;
  const totalBase = baseStats.hp + baseStats.atk + baseStats.def + baseStats.spd;
  const budget = levels * 12; // identical total to the old flat +3 across 4 stats — power-neutral
  const mult = shiny ? 1.2 : 1.0;
  const grow = (base) => Math.floor((base + budget * (base / totalBase)) * mult);
  return { hp: grow(baseStats.hp), atk: grow(baseStats.atk), def: grow(baseStats.def), spd: grow(baseStats.spd) };
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

export function pickNpcMove(npcMoveKeys, npcElement, playerElement, playerStatus, battleContext = {}) {
  const {
    playerMoveHistory = [],
    turnCount = 0,
    playerHpRatio = 1.0,
    enemyHpRatio = 1.0,
    npcAtkBuff = null,
    npcDefBuff = null,
  } = battleContext;

  const filteredKeys = npcMoveKeys.filter(key => {
    const move = allMoves[key];
    return !move?.isReflect;
  });
  const availableKeys = [...filteredKeys, 'basic_attack'];

  const desperationMode = enemyHpRatio < 0.30;
  const exploitMode = !desperationMode && enemyHpRatio > 0.70 && playerHpRatio < 0.40 && !playerStatus;

  // Desperation: skip all buffs and status moves, just hit hardest
  if (desperationMode) {
    const offensiveKeys = filteredKeys.filter(k => !allMoves[k]?.actionType);
    const pool = offensiveKeys.length > 0 ? offensiveKeys : availableKeys;
    const sorted = [...pool].sort((a, b) => (allMoves[b]?.power || 0) - (allMoves[a]?.power || 0));
    return sorted[0] || pool[0];
  }

  // Anti-stack: don't re-buff if buff is already active
  const buffFiltered = filteredKeys.filter(k => {
    if (k === 'npc_focus' && npcAtkBuff) return false;
    if (k === 'npc_harden' && npcDefBuff) return false;
    return true;
  });

  // Buff timing: prefer to buff on early turns
  const buffMoves = buffFiltered.filter(k => allMoves[k]?.actionType === 'buff');
  const offensiveMoves = buffFiltered.filter(k => !allMoves[k]?.actionType);
  if (buffMoves.length > 0 && turnCount <= 2 && Math.random() < 0.45) {
    return buffMoves[Math.floor(Math.random() * buffMoves.length)];
  }

  // Counter-element adaptation: if player spammed same element, counter it
  const recentElements = playerMoveHistory.slice(-3)
    .map(k => allMoves[k]?.element)
    .filter(Boolean);
  if (recentElements.length >= 2 && recentElements.every(e => e === recentElements[0])) {
    const dominantElement = recentElements[0];
    const counterMoves = offensiveMoves.filter(k => {
      const m = allMoves[k];
      return m && getTypeEffectiveness(m.element, dominantElement) > 1.0;
    });
    if (counterMoves.length > 0 && Math.random() < 0.75) {
      return counterMoves[Math.floor(Math.random() * counterMoves.length)];
    }
  }

  const offensivePool = offensiveMoves.length > 0 ? offensiveMoves : availableKeys.filter(k => !allMoves[k]?.actionType);

  // Find super-effective moves (from offensive pool only)
  const superEffective = offensivePool.filter(key => {
    const move = allMoves[key];
    return move && getTypeEffectiveness(move.element, playerElement) > 1.0;
  });

  // 70% chance to pick super-effective if available
  if (superEffective.length > 0 && Math.random() < 0.7) {
    return superEffective[Math.floor(Math.random() * superEffective.length)];
  }

  // Exploit wounded player: raise status move chance to 70%
  const statusChance = exploitMode ? 0.70 : 0.40;
  if (!playerStatus && Math.random() < statusChance) {
    const statusMoves = offensivePool.filter(key => allMoves[key]?.canApplyStatus);
    if (statusMoves.length > 0) {
      return statusMoves[Math.floor(Math.random() * statusMoves.length)];
    }
  }

  // Prefer higher-power moves (60% chance to pick strongest)
  if (offensivePool.length > 1 && Math.random() < 0.6) {
    const sorted = [...offensivePool].sort((a, b) => (allMoves[b]?.power || 0) - (allMoves[a]?.power || 0));
    return sorted[0];
  }

  // Otherwise random from offensive moves
  const preferred = offensivePool.length > 0 && Math.random() < 0.7
    ? offensivePool
    : [...offensivePool, 'basic_attack'];
  return preferred[Math.floor(Math.random() * preferred.length)];
}

export function resolveTurn(playerState, npcState, playerMoveKey, npcMoveKey, playerMoveKeys, npcMoveKeys) {
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

  // Glitch randomization
  if (first.state.status?.effect === 'void') {
    const keys = first.label === 'player' ? playerMoveKeys : npcMoveKeys;
    if (keys && keys.length > 0) {
      first.moveKey = keys[Math.floor(Math.random() * keys.length)];
    }
  }
  if (second.state.status?.effect === 'void') {
    const keys = second.label === 'player' ? playerMoveKeys : npcMoveKeys;
    if (keys && keys.length > 0) {
      second.moveKey = keys[Math.floor(Math.random() * keys.length)];
    }
  }

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

  // Clear reflecting at end of turn
  player = { ...player, reflecting: false };
  npc = { ...npc, reflecting: false };

  // Decrement active buff durations
  player = decrementBuff(decrementBuff(player, 'atkBuff'), 'defBuff');
  npc    = decrementBuff(decrementBuff(npc,    'atkBuff'), 'defBuff');

  return { player, npc, events };
}

function decrementBuff(state, buffKey) {
  const buff = state[buffKey];
  if (!buff) return state;
  const turnsLeft = buff.turnsLeft - 1;
  return turnsLeft <= 0
    ? { ...state, [buffKey]: null }
    : { ...state, [buffKey]: { ...buff, turnsLeft } };
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

  const moveData = allMoves[actor.moveKey];
  const move = moveData || allMoves.basic_attack;

  // Reflect handler
  if (moveData?.isReflect) {
    setSelf({ ...actor.state, reflecting: true });
    events.push({
      attacker: actor.label,
      action: 'reflect',
      moveName: move.name,
      moveKey: actor.moveKey,
      vfxKey: move.vfxKey,
      damage: 0,
      effectiveness: 1.0,
      hit: true,
    });
    return;
  }

  // Buff action handler
  if (moveData?.actionType === 'buff') {
    const buffKey = moveData.buffStat === 'atk' ? 'atkBuff' : 'defBuff';
    // +1 so the end-of-turn decrement still leaves turnsLeft > 0 on the application turn,
    // making the buff active for the full intended number of subsequent attack turns.
    setSelf({
      ...actor.state,
      [buffKey]: { multiplier: moveData.buffMultiplier, turnsLeft: moveData.buffDuration + 1 },
    });
    events.push({
      attacker: actor.label,
      action: 'buff',
      moveName: move.name,
      moveKey: actor.moveKey,
      vfxKey: move.vfxKey,
      buffStat: moveData.buffStat,
      buffMultiplier: moveData.buffMultiplier,
      buffDuration: moveData.buffDuration,
    });
    return;
  }

  const target = getTarget();

  // Apply Guard Break debuff to effective DEF
  let effectiveDef = target.def;
  if (target.status?.effect === 'stone') {
    effectiveDef = Math.floor(effectiveDef * (1 - STATUS_EFFECTS.stone.value));
  }
  // Apply defender's defBuff
  if (target.defBuff) {
    effectiveDef = Math.floor(effectiveDef * target.defBuff.multiplier);
  }

  // Apply Blind debuff to effective accuracy
  let effectiveAccuracy = move.accuracy;
  if (actor.state.status?.effect === 'shadow') {
    effectiveAccuracy = Math.max(0, effectiveAccuracy - STATUS_EFFECTS.shadow.value * 100);
  }

  // Apply attacker's atkBuff and any charged-move boost under one shared ceiling
  const effectiveAtk = effectiveAttack(actor.state.atk, actor.state.atkBuff, actor.state.chargeMultiplier);

  const result = calculateDamage(
    { atk: effectiveAtk, element: actor.state.element, stage: actor.state.stage },
    { def: effectiveDef, element: target.element, defending: target.defending },
    { ...move, accuracy: effectiveAccuracy }
  );

  // Check if target is reflecting
  if (target.reflecting) {
    if (result.hit) {
      // Reflect damage back to attacker
      const newSelfHp = Math.max(0, actor.state.hp - result.damage);
      setSelf({ ...actor.state, hp: newSelfHp });
      setTarget({ ...target, reflecting: false });

      events.push({
        attacker: actor.label,
        action: 'attack',
        moveName: move.name,
        moveKey: actor.moveKey,
        vfxKey: move.vfxKey,
        damage: result.damage,
        effectiveness: result.effectiveness,
        hit: result.hit,
        reflected: true,
        isCritical: result.isCritical,
        targetHp: newSelfHp,
      });
    } else {
      // Miss — clear reflect, push normal miss event
      setTarget({ ...target, reflecting: false });

      events.push({
        attacker: actor.label,
        action: 'attack',
        moveName: move.name,
        moveKey: actor.moveKey,
        vfxKey: move.vfxKey,
        damage: 0,
        effectiveness: result.effectiveness,
        hit: false,
        targetHp: target.hp,
      });
    }
    return;
  }

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
    isCritical: result.isCritical,
    targetHp: newTargetHp,
    appliedStatus: appliedStatus ? STATUS_EFFECTS[appliedStatus.effect].name : null,
  });
}
