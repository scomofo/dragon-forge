import { useState, useReducer, useCallback, useEffect, useRef } from 'react';
import { wait } from './utils';
import { playSound, playMusic, stopMusic, startHeartbeat, stopHeartbeat } from './soundEngine';
import { dragons, npcs, moves, elementColors, STATUS_EFFECTS } from './gameData';
import {
  resolveTurn, pickNpcMove, calculateStatsForLevel,
  getStageForLevel, calculateXpGain,
} from './battleEngine';
import { loadSave, saveDragonProgress, addScraps, recordNpcDefeat, recordSingularityDefeat, markSingularityComplete, addCore, decrementXpBoost, trackStat, completeDailyChallenge, updateRecords, unlockFragment } from './persistence';
import { FRAGMENT_TRIGGERS } from './forgeData';
import { CORE_DROP_CHANCE, CORE_DOUBLE_CHANCE } from './shopItems';
import { EPILOGUE_LINES } from './singularityBosses';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';
import DamageNumber from './DamageNumber';
import VfxOverlay from './VfxOverlay';
import { getBattlePresentationProfile, getBattleResultCallout, shouldAnimateBattleEvent } from './battlePresentation';
import useGamepadController from './useGamepadController';
import {
  screenShake, hitFlash, criticalHit, shatterKO,
  shieldUp, shieldDeflect, shieldDismiss,
  statusAuraApply, npcLunge, playerLunge, hitSquash,
  pixelShake, hitStop, targetKnockback, hitFlicker,
} from './animationEngine';

const PHASES = {
  PLAYER_TURN: 'playerTurn',
  ANIMATING: 'animating',
  VICTORY: 'victory',
  DEFEAT: 'defeat',
  PHASE_SHIFT: 'phaseShift',
  EPILOGUE: 'epilogue',
};

function getScaledNpcStats(baseStats, baseLevel, playerLevel) {
  // Scale NPC stats when player out-levels them. No scaling below base level.
  if (playerLevel <= baseLevel) return { stats: baseStats, level: baseLevel };
  const scale = 1 + (playerLevel - baseLevel) * 0.04; // +4% per level above NPC
  const scaledStats = {};
  for (const key of Object.keys(baseStats)) {
    scaledStats[key] = Math.floor(baseStats[key] * scale);
  }
  return { stats: scaledStats, level: Math.max(baseLevel, Math.floor(baseLevel + (playerLevel - baseLevel) * 0.5)) };
}

function getHpState(current, max) {
  const ratio = max > 0 ? current / max : 0;
  if (ratio <= 0.25) return 'danger';
  if (ratio <= 0.5) return 'warning';
  return 'stable';
}

function getMoveEffectivenessLabel(moveElement, defenderElement) {
  if (!moveElement || moveElement === 'neutral') return 'NORMAL';
  const chart = {
    fire: { strong: ['ice'], weak: ['stone', 'fire'] },
    ice: { strong: ['storm'], weak: ['fire', 'ice'] },
    storm: { strong: ['stone'], weak: ['ice', 'storm'] },
    stone: { strong: ['fire'], weak: ['storm', 'stone'] },
    venom: { strong: ['stone'], weak: ['shadow', 'venom'] },
    shadow: { strong: ['venom'], weak: ['fire', 'shadow'] },
  };
  if (chart[moveElement]?.strong.includes(defenderElement)) return 'ADVANTAGE';
  if (chart[moveElement]?.weak.includes(defenderElement)) return 'RESISTED';
  return 'NORMAL';
}

function getMoveProfileText(moveKeys) {
  return moveKeys
    .map((key) => moves[key]?.element)
    .filter(Boolean)
    .map((element) => element.toUpperCase())
    .filter((element, index, list) => list.indexOf(element) === index)
    .slice(0, 3)
    .join(' / ') || 'UNKNOWN';
}

function getBattleEdge(playerHpPercent, npcHpPercent, playerHpState, npcHpState) {
  if (playerHpState === 'danger') {
    return { tone: 'danger', label: 'DANGER', detail: 'HOLD LINE' };
  }
  if (npcHpState === 'danger') {
    return { tone: 'advantage', label: 'PRESSURE', detail: 'FINISH IT' };
  }
  const delta = playerHpPercent - npcHpPercent;
  if (delta >= 18) return { tone: 'advantage', label: 'EDGE', detail: 'PLAYER' };
  if (delta <= -18) return { tone: 'warning', label: 'EDGE', detail: 'ENEMY' };
  return { tone: 'neutral', label: 'EDGE', detail: 'EVEN' };
}

function getBattleRank(turnCount, maxDamage, playerHpPercent) {
  let score = 0;
  if (turnCount <= 3) score += 2;
  else if (turnCount <= 5) score += 1;
  if (maxDamage >= 24) score += 2;
  else if (maxDamage >= 14) score += 1;
  if (playerHpPercent >= 70) score += 2;
  else if (playerHpPercent >= 40) score += 1;

  if (score >= 6) return 'S';
  if (score >= 4) return 'A';
  if (score >= 2) return 'B';
  return 'C';
}

function initBattle(dragonId, npcId, save, battleConfig) {
  const dragon = dragons[dragonId];

  let npc;
  if (battleConfig?.boss) {
    const boss = battleConfig.boss;
    const phase = boss.phases ? boss.phases[0] : null;
    npc = {
      id: boss.id,
      name: phase ? phase.name : boss.name,
      element: phase ? phase.element : boss.element,
      level: phase ? phase.level : boss.level,
      stats: phase ? phase.stats : boss.stats,
      moveKeys: phase ? phase.moveKeys : boss.moveKeys,
      difficulty: boss.difficulty,
      baseXP: boss.baseXP,
      scrapsReward: boss.scrapsReward,
      idleSprite: boss.idleSprite,
      attackSprite: boss.attackSprite,
      arena: boss.arena,
      arenaFilter: boss.arenaFilter || null,
      spriteFilter: phase ? phase.spriteFilter : (boss.spriteFilter || null),
      flipSprite: false,
    };
  } else if (battleConfig?.dailyNpc) {
    npc = battleConfig.dailyNpc;
  } else {
    const baseNpc = npcs[npcId];
    const progress = save.dragons[dragonId] || { level: 1, xp: 0 };
    const scaled = getScaledNpcStats(baseNpc.stats, baseNpc.level, progress.level);
    npc = { ...baseNpc, stats: scaled.stats, level: scaled.level };
  }
  const progress = save.dragons[dragonId] || { level: 1, xp: 0 };
  const stage = getStageForLevel(progress.level);
  const stats = calculateStatsForLevel(progress.fusedBaseStats || dragon.baseStats, progress.level, progress.shiny);

  return {
    phase: PHASES.PLAYER_TURN,
    dragon,
    npc,
    dragonId,
    playerLevel: progress.level,
    playerXp: progress.xp,
    playerStage: stage,
    playerStats: stats,
    playerHp: stats.hp,
    playerMaxHp: stats.hp,
    playerDefending: false,
    npcHp: npc.stats.hp,
    npcMaxHp: npc.stats.hp,
    npcDefending: false,
    damageNumbers: [],
    playerSpriteClass: '',
    npcSpriteClass: '',
    npcAttacking: false,
    playerForcedFrame: null,
    xpGained: 0,
    leveledUp: false,
    newLevel: progress.level,
    scrapsGained: 0,
    playerStatus: null,
    npcStatus: null,
    vfxActive: null,
    battleCallout: null,
    currentPhase: 0,
    battleLog: [],
    turnCount: 0,
    maxDamageDealt: 0,
  };
}

function battleReducer(state, action) {
  switch (action.type) {
    case 'START_ANIMATION':
      return { ...state, phase: PHASES.ANIMATING };
    case 'SET_PLAYER_SPRITE_CLASS':
      return { ...state, playerSpriteClass: action.value };
    case 'SET_NPC_SPRITE_CLASS':
      return { ...state, npcSpriteClass: action.value };
    case 'SET_NPC_ATTACKING':
      return { ...state, npcAttacking: action.value };
    case 'SET_PLAYER_FORCED_FRAME':
      return { ...state, playerForcedFrame: action.value };
    case 'APPLY_DAMAGE_TO_NPC':
      return { ...state, npcHp: Math.max(0, state.npcHp - action.damage) };
    case 'APPLY_DAMAGE_TO_PLAYER':
      return { ...state, playerHp: Math.max(0, state.playerHp - action.damage) };
    case 'ADD_DAMAGE_NUMBER':
      return { ...state, damageNumbers: [...state.damageNumbers, action.entry] };
    case 'REMOVE_DAMAGE_NUMBER':
      return { ...state, damageNumbers: state.damageNumbers.filter((d) => d.id !== action.id) };
    case 'SET_PHASE':
      return { ...state, phase: action.phase };
    case 'SET_VICTORY':
      return { ...state, phase: PHASES.VICTORY, xpGained: action.xpGained, leveledUp: action.leveledUp, newLevel: action.newLevel, scrapsGained: action.scrapsGained || 0, coreDropped: action.coreDropped || null };
    case 'SET_DEFEAT':
      return { ...state, phase: PHASES.DEFEAT };
    case 'RESET_TURN':
      return { ...state, phase: PHASES.PLAYER_TURN, playerSpriteClass: '', npcSpriteClass: '', npcAttacking: false, playerForcedFrame: null, turnCount: state.turnCount + 1 };
    case 'TRACK_DAMAGE':
      return { ...state, maxDamageDealt: Math.max(state.maxDamageDealt, action.damage) };
    case 'SET_PLAYER_STATUS':
      return { ...state, playerStatus: action.value };
    case 'SET_NPC_STATUS':
      return { ...state, npcStatus: action.value };
    case 'SET_VFX':
      return { ...state, vfxActive: action.value };
    case 'CLEAR_VFX':
      return { ...state, vfxActive: null };
    case 'SET_BATTLE_CALLOUT':
      return { ...state, battleCallout: action.value };
    case 'CLEAR_BATTLE_CALLOUT':
      return { ...state, battleCallout: null };
    case 'ADD_LOG':
      return { ...state, battleLog: [...state.battleLog, action.text] };
    case 'PHASE_SHIFT':
      return {
        ...state,
        npc: { ...state.npc, ...action.npcUpdate },
        npcHp: action.npcUpdate.stats.hp,
        npcMaxHp: action.npcUpdate.stats.hp,
        npcStatus: null,
        npcSpriteClass: '',
        npcAttacking: false,
        phase: PHASES.PLAYER_TURN,
        currentPhase: (state.currentPhase || 0) + 1,
      };
    case 'SET_EPILOGUE':
      return { ...state, phase: PHASES.EPILOGUE, xpGained: action.xpGained, scrapsGained: action.scrapsGained };
    default:
      return state;
  }
}

export default function BattleScreen({ dragonId, npcId, onBattleEnd, save, refreshSave, battleConfig }) {
  const [state, dispatch] = useReducer(battleReducer, null, () => initBattle(dragonId, npcId, save, battleConfig));
  const animatingRef = useRef(false);
  const damageIdRef = useRef(0);
  const [autoBattle, setAutoBattle] = useState(false);
  const [selectedMoveKey, setSelectedMoveKey] = useState(null);
  const [controllerFocusIndex, setControllerFocusIndex] = useState(0);

  const battleContainerRef = useRef(null);
  const playerSpriteContainerRef = useRef(null);
  const npcSpriteContainerRef = useRef(null);
  const playerSpriteRef = useRef(null);
  const npcSpriteImgRef = useRef(null);
  const shieldRef = useRef(null);
  const playerAuraRef = useRef(null);
  const npcAuraRef = useRef(null);
  const damageStaggerRef = useRef(0);

  const animateEvent = useCallback(async (event, dispatch) => {
    const isPlayer = event.attacker === 'player';
    const who = isPlayer ? 'You' : event.moveName ? 'Enemy' : 'Status';

    if (event.action === 'defend') {
      dispatch({ type: 'ADD_LOG', text: `${who} defended.` });
      playSound('combatMessage');
      playSound('defend');
      const targetContainer = isPlayer ? playerSpriteContainerRef.current : npcSpriteContainerRef.current;
      if (targetContainer) {
        const shield = shieldUp(targetContainer, isPlayer ? state.dragon.element : state.npc.element);
        if (isPlayer) {
          shieldRef.current = shield;
        }
      }
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
        await wait(400);
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      }
      return;
    }

    if (event.action === 'reflect') {
      dispatch({ type: 'ADD_LOG', text: `${who} used Null Reflect!` });
      playSound('combatMessage');
      playSound('defend');
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
      } else {
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-telegraph' });
      }
      await wait(500);
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      } else {
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      }
      return;
    }

    const move = moves[event.moveKey] || moves.basic_attack;
    const profile = getBattlePresentationProfile(event, move);

    // TELEGRAPH phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: profile.attackerClass });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: profile.attackerClass });
    }
    playSound('attackLaunch');
    await wait(profile.anticipationMs);

    // VFX TRAVEL + IMPACT phase
    const vfxElement = move.element === 'neutral' ? 'neutral' : move.element;
    const vfxDirection = isPlayer ? 'left-to-right' : 'right-to-left';

    // Create a promise that resolves when VfxOverlay calls onComplete
    let vfxResolve;
    const vfxPromise = new Promise((resolve) => { vfxResolve = resolve; });
    dispatch({
      type: 'SET_VFX',
      value: {
        vfxKey: event.vfxKey,
        element: vfxElement,
        direction: vfxDirection,
        targetSide: isPlayer ? 'left' : 'right',
        onComplete: () => {
          dispatch({ type: 'CLEAR_VFX' });
          vfxResolve();
        },
      },
    });
    await vfxPromise;

    // IMPACT phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: 3 });
      const spriteEl = playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current;
      if (spriteEl) playerLunge(spriteEl, 'left');
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_NPC_ATTACKING', value: true });
      const npcEl = npcSpriteImgRef.current;
      if (npcEl) npcLunge(npcEl, state.npc.flipSprite ? 'left' : 'right');
    }
    // Whip/swoosh at the contact frame (matches lunge anticipation -> strike timing)
    setTimeout(() => playSound('lungeContact'), 110);

    if (event.hit) {
      if (event.reflected) {
        if (isPlayer) {
          dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        } else {
          dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        }
      } else {
        if (isPlayer) {
          dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        } else {
          dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        }
      }
      // Hit-sound chosen now, played after hit-stop so it lands at the freeze peak
      const hitSoundName = event.reflected
        ? profile.sound
        : event.isCritical
          ? profile.sound
          : event.effectiveness > 1.0
            ? profile.sound
            : event.effectiveness < 1.0
              ? profile.sound
              : profile.sound;

      const container = battleContainerRef.current;
      const targetContainer = isPlayer
        ? (event.reflected ? playerSpriteContainerRef.current : npcSpriteContainerRef.current)
        : (event.reflected ? npcSpriteContainerRef.current : playerSpriteContainerRef.current);
      const targetSide = isPlayer ? (event.reflected ? 'right' : 'left') : (event.reflected ? 'left' : 'right');

      // Pull the target sprite element (not container) for crunchy NES-style flicker
      const targetSpriteEl = targetContainer === playerSpriteContainerRef.current
        ? (playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current)
        : npcSpriteImgRef.current;

      const targetDefending = isPlayer ? state.npcDefending : state.playerDefending;
      if (targetDefending && shieldRef.current) {
        shieldDeflect(shieldRef.current.element, targetContainer, isPlayer ? 'right' : 'left');
        playSound('shieldDeflectSting');
        if (container) pixelShake(container, 3, 0.12);
      } else if (event.isCritical && container) {
        // Hit-stop before the crit cinematic for that NES "moment of impact" pause
        await hitStop(profile.impactPauseMs / 1000);
        playSound(hitSoundName, { element: move.element });
        await new Promise(resolve => {
          const tl = criticalHit(container, targetContainer, targetSide);
          tl.eventCallback('onComplete', resolve);
          setTimeout(resolve, 800);
        });
        if (targetSpriteEl) hitFlicker(targetSpriteEl, 5);
        if (targetContainer) targetKnockback(targetContainer, isPlayer ? 'left' : 'right', 18);
      } else if (container) {
        const hpRatio = event.damage / (isPlayer ? state.npcMaxHp : state.playerMaxHp);
        const isHeavy = event.effectiveness > 1.0 || hpRatio > 0.25;
        // Universal hit-stop: short on normal, longer on super-effective
        await hitStop(profile.impactPauseMs / 1000);
        playSound(hitSoundName, { element: move.element });
        const intensity = Math.max(profile.shake, Math.min(8, Math.round(4 + hpRatio * 8)));
        pixelShake(container, intensity, 0.18);
        if (targetContainer) {
          const flashColor = event.effectiveness > 1.0
            ? (elementColors[move.element]?.primary || '#ffffff')
            : profile.flashColor;
          hitFlash(targetContainer, flashColor);
        }
        if (targetSpriteEl) hitFlicker(targetSpriteEl, isHeavy ? 4 : 3);
        if (targetContainer) {
          targetKnockback(targetContainer, isPlayer ? 'left' : 'right', isHeavy ? 14 : 9);
        }
      }

      const hitTarget = isPlayer
        ? (event.reflected ? playerSpriteContainerRef.current : npcSpriteContainerRef.current)
        : (event.reflected ? npcSpriteContainerRef.current : playerSpriteContainerRef.current);
      if (hitTarget) hitSquash(hitTarget);
    } else {
      playSound(profile.sound);
      const whiffTarget = isPlayer ? npcSpriteContainerRef.current : playerSpriteContainerRef.current;
      if (whiffTarget) {
        dispatch({
          type: isPlayer ? 'SET_NPC_SPRITE_CLASS' : 'SET_PLAYER_SPRITE_CLASS',
          value: profile.defenderClass,
        });
      }
    }

    const dmgTarget = event.reflected ? (isPlayer ? 'player' : 'npc') : (isPlayer ? 'npc' : 'player');
    const callout = getBattleResultCallout(event);
    if (callout) {
      dispatch({ type: 'SET_BATTLE_CALLOUT', value: callout });
      setTimeout(() => dispatch({ type: 'CLEAR_BATTLE_CALLOUT' }), 620);
    }
    const dmgId = ++damageIdRef.current;
    const staggerIdx = damageStaggerRef.current++;
    dispatch({
      type: 'ADD_DAMAGE_NUMBER',
      entry: {
        id: dmgId,
        damage: event.damage,
        effectiveness: event.effectiveness,
        hit: event.hit,
        target: dmgTarget,
        isCritical: event.isCritical || false,
        variant: profile.damageVariant,
        staggerIndex: staggerIdx,
      },
    });
    if (event.hit && isPlayer && !event.reflected) {
      dispatch({ type: 'TRACK_DAMAGE', damage: event.damage });
    }

    if (event.hit) {
      const critText = event.isCritical ? ' CRITICAL!' : '';
      const effText = event.effectiveness > 1 ? ' Super effective!' : event.effectiveness < 1 ? ' Resisted.' : '';
      const reflectText = event.reflected ? ' REFLECTED!' : '';
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — ${event.damage} dmg.${critText}${effText}${reflectText}` });
      playSound('combatMessage');
    } else {
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — missed!` });
      playSound('combatMessage');
    }
    if (event.appliedStatus) {
      dispatch({ type: 'ADD_LOG', text: `${event.appliedStatus} applied!` });
      playSound('combatMessage');
      playSound('statusApply');
      const statusId = ++damageIdRef.current;
      dispatch({
        type: 'ADD_DAMAGE_NUMBER',
        entry: {
          id: statusId,
          damage: 0,
          effectiveness: 1.0,
          hit: true,
          target: dmgTarget,
          variant: 'status',
          label: event.appliedStatus.toUpperCase(),
          staggerIndex: staggerIdx + 1,
          position: { x: 54, y: -54 },
        },
      });
    }
    await wait(profile.recoveryMs);

    damageStaggerRef.current = 0;

    if (isPlayer) {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: profile.defenderClass || 'sprite-recoil' });
    } else {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: profile.defenderClass || 'sprite-recoil' });
    }
    await wait(200);

    dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_ATTACKING', value: false });
    dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });

    if (shieldRef.current) {
      shieldDismiss(shieldRef.current.element, shieldRef.current.timeline);
      shieldRef.current = null;
    }

    await wait(200);
  }, [state]);

  useEffect(() => {
    if (autoBattle && state.phase === PHASES.PLAYER_TURN && !animatingRef.current) {
      const playerMoveKeys = [...state.dragon.moveKeys, 'basic_attack'];
      const autoMove = pickNpcMove(playerMoveKeys, state.dragon.element, state.npc.element, state.npcStatus);
      setTimeout(() => handleMoveSelect(autoMove), 500);
    }
  }, [autoBattle, state.phase]);

  useEffect(() => {
    return () => {
      if (playerAuraRef.current) playerAuraRef.current.kill();
      if (npcAuraRef.current) npcAuraRef.current.kill();
      stopHeartbeat();
    };
  }, []);

  const handleMoveSelect = useCallback(async (moveKey) => {
    if (animatingRef.current) return;
    playSound('commandSelect', { element: moves[moveKey]?.element });
    setSelectedMoveKey(moveKey);
    animatingRef.current = true;
    dispatch({ type: 'START_ANIMATION' });
    playSound('commandExecute', { element: moves[moveKey]?.element });

    const playerState = {
      name: state.dragon.name,
      element: state.dragon.element,
      stage: state.playerStage,
      hp: state.playerHp,
      maxHp: state.playerMaxHp,
      atk: state.playerStats.atk,
      def: state.playerStats.def,
      spd: state.playerStats.spd,
      defending: false,
      status: state.playerStatus,
    };

    const npcState = {
      name: state.npc.name,
      element: state.npc.element,
      stage: 3,
      hp: state.npcHp,
      maxHp: state.npcMaxHp,
      atk: state.npc.stats.atk,
      def: state.npc.stats.def,
      spd: state.npc.stats.spd,
      defending: false,
      status: state.npcStatus,
    };

    const npcMoveKey = pickNpcMove(state.npc.moveKeys, state.npc.element, state.dragon.element, state.playerStatus);
    const result = resolveTurn(playerState, npcState, moveKey, npcMoveKey, state.dragon.moveKeys, state.npc.moveKeys);

    for (const event of result.events) {
      if (shouldAnimateBattleEvent(event)) {
        await animateEvent(event, dispatch);
      }
    }

    // Sync status from engine
    dispatch({ type: 'SET_PLAYER_STATUS', value: result.player.status || null });
    dispatch({ type: 'SET_NPC_STATUS', value: result.npc.status || null });

    // Apply/remove status auras
    if (result.player.status && !playerAuraRef.current) {
      const spriteEl = playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current;
      if (spriteEl) {
        playerAuraRef.current = statusAuraApply(spriteEl, result.player.status.effect);
      }
    } else if (!result.player.status && playerAuraRef.current) {
      playerAuraRef.current.kill();
      playerAuraRef.current = null;
    }

    if (result.npc.status && !npcAuraRef.current) {
      const npcEl = npcSpriteImgRef.current || npcSpriteContainerRef.current;
      if (npcEl) {
        npcAuraRef.current = statusAuraApply(npcEl, result.npc.status.effect);
      }
    } else if (!result.npc.status && npcAuraRef.current) {
      npcAuraRef.current.kill();
      npcAuraRef.current = null;
    }

    // Process status tick events (DOT, skip)
    for (const event of result.events) {
      if (event.attacker === 'status') {
        if (event.damage > 0) {
          playSound('statusTick');
          const dmgId = ++damageIdRef.current;
          dispatch({
            type: 'ADD_DAMAGE_NUMBER',
            entry: { id: dmgId, damage: event.damage, effectiveness: 1.0, hit: true, target: event.target, isStatusTick: true, statusElement: event.target === 'player' ? state.playerStatus?.effect : state.npcStatus?.effect },
          });
          if (event.target === 'player') {
            dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
          } else {
            dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
          }
          await wait(400);
        }
        if (event.expired) {
          playSound('statusExpire');
        }
      }
      if (event.action === 'statusSkip') {
        const skippedName = event.attacker === 'player' ? 'You' : 'Enemy';
        dispatch({ type: 'ADD_LOG', text: `${skippedName} cannot move — ${event.statusName}!` });
        playSound('combatMessage');
        const dmgId = ++damageIdRef.current;
        dispatch({
          type: 'ADD_DAMAGE_NUMBER',
          entry: { id: dmgId, damage: 0, effectiveness: 1.0, hit: false, target: event.attacker === 'player' ? 'player' : 'npc' },
        });
        await wait(300);
      }
    }

    if (result.npc.hp <= 0) {
      const phases = battleConfig?.phases;
      const currentPhaseIndex = state.currentPhase || 0;

      if (phases && currentPhaseIndex < phases.length - 1) {
        // Phase shift — boss transforms
        const nextPhase = phases[currentPhaseIndex + 1];
        playSound('ko');
        const phaseNpcEl = npcSpriteImgRef.current;
        if (phaseNpcEl) {
          await new Promise(resolve => {
            const tl = shatterKO(phaseNpcEl, state.npc.element);
            tl.eventCallback('onComplete', resolve);
            setTimeout(resolve, 1200);
          });
        } else {
          dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
          await wait(600);
        }

        playSound('terminalGlitch');
        dispatch({
          type: 'PHASE_SHIFT',
          npcUpdate: {
            name: nextPhase.name,
            element: nextPhase.element,
            level: nextPhase.level,
            stats: nextPhase.stats,
            moveKeys: nextPhase.moveKeys,
            spriteFilter: nextPhase.spriteFilter,
          },
        });
        await wait(1000);
      } else {
        // True victory
        let xpGained = calculateXpGain(state.npc.baseXP || 50, state.playerLevel, state.npc.level);
        if (save.inventory?.xpBoostBattles > 0) {
          xpGained *= 2;
          decrementXpBoost();
        }
        const scrapsGained = state.npc.scrapsReward || 0;
        const newXp = state.playerXp + xpGained;
        const xpPerLevel = 100;
        let newLevel = state.playerLevel;
        let remainingXp = newXp;
        while (remainingXp >= xpPerLevel) {
          remainingXp -= xpPerLevel;
          newLevel++;
        }
        const leveledUp = newLevel > state.playerLevel;
        saveDragonProgress(state.dragonId, newLevel, remainingXp);
        if (scrapsGained > 0) addScraps(scrapsGained);

        if (battleConfig?.isSingularity) {
          if (phases) {
            markSingularityComplete();
          } else {
            recordSingularityDefeat(npcId);
          }
        } else {
          recordNpcDefeat(npcId);
          if (battleConfig?.dailyNpc) {
            completeDailyChallenge(battleConfig.dailyNpc.seed);
          }
        }
        refreshSave();

        // Core drops
        let coreDropped = null;
        const npcElement = state.npc.element;
        if (Math.random() < CORE_DROP_CHANCE) {
          const coreCount = Math.random() < CORE_DOUBLE_CHANCE ? 2 : 1;
          addCore(npcElement, coreCount);
          coreDropped = { element: npcElement, count: coreCount };
        }

        playSound('ko');
        const victoryNpcEl = npcSpriteImgRef.current;
        if (victoryNpcEl) {
          await new Promise(resolve => {
            const tl = shatterKO(victoryNpcEl, state.npc.element);
            tl.eventCallback('onComplete', resolve);
            setTimeout(resolve, 1200);
          });
        } else {
          dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
          await wait(600);
        }

        if (battleConfig?.isSingularity && phases && !save.singularityComplete) {
          trackStat('battlesWon');
          if (scrapsGained > 0) trackStat('totalScrapsEarned', scrapsGained);
          runFragmentUnlockPass();
          dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-celebrate' });
          dispatch({ type: 'SET_EPILOGUE', xpGained, scrapsGained });
          stopMusic();
          stopHeartbeat();
          playSound('victoryFanfare');
        } else {
          trackStat('battlesWon');
          if (scrapsGained > 0) trackStat('totalScrapsEarned', scrapsGained);
          updateRecords({ turns: state.turnCount + 1, maxDamage: state.maxDamageDealt, won: true });
          runFragmentUnlockPass();
          dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-celebrate' });
          dispatch({ type: 'SET_VICTORY', xpGained, leveledUp, newLevel, scrapsGained, coreDropped });
          stopMusic();
          stopHeartbeat();
          playSound('victoryFanfare');
          playSound('xpGain');
          if (scrapsGained > 0) setTimeout(() => playSound('scrapsEarned'), 200);
          if (leveledUp) setTimeout(() => playSound('levelUp'), 400);
        }
      }
    } else if (result.player.hp <= 0) {
      playSound('ko');
      const playerCanvas = playerSpriteRef.current?.getCanvas?.();
      if (playerCanvas) {
        await new Promise(resolve => {
          const tl = shatterKO(playerCanvas, state.dragon.element);
          tl.eventCallback('onComplete', resolve);
          setTimeout(resolve, 1200);
        });
      } else {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-ko' });
        await wait(600);
      }
      trackStat('battlesLost');
      updateRecords({ turns: state.turnCount + 1, maxDamage: state.maxDamageDealt, won: false });
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-defeated' });
      dispatch({ type: 'SET_DEFEAT' });
      stopMusic();
      stopHeartbeat();
      playSound('defeatDrone');
    } else {
      const playerHpPct = result.player.hp / (result.player.maxHp || state.playerMaxHp);
      const npcHpPct = result.npc.hp / (result.npc.maxHp || state.npcMaxHp);
      if (playerHpPct < 0.25 || npcHpPct < 0.25) {
        playMusic('battleIntense');
      } else {
        playMusic('battle');
      }
      // Heartbeat urgency pulse only when the PLAYER is in danger
      if (playerHpPct < 0.25) {
        startHeartbeat(650);
      } else {
        stopHeartbeat();
      }
      dispatch({ type: 'RESET_TURN' });
    }

    animatingRef.current = false;
    setSelectedMoveKey(null);
  }, [state, animateEvent]);

  const dragon = state.dragon;
  const npc = state.npc;
  const playerMoves = [...dragon.moveKeys.map((k) => ({ key: k, ...moves[k] })), { key: 'basic_attack', ...moves.basic_attack }];
  const controllerCommandCount = playerMoves.length + 2;
  const playerColor = elementColors[dragon.element];
  const npcColor = elementColors[npc.element];
  const playerHpState = getHpState(state.playerHp, state.playerMaxHp);
  const npcHpState = getHpState(state.npcHp, state.npcMaxHp);
  const playerHpPercent = Math.max(0, Math.min(100, (state.playerHp / state.playerMaxHp) * 100));
  const npcHpPercent = Math.max(0, Math.min(100, (state.npcHp / state.npcMaxHp) * 100));
  const isResolvingTurn = state.phase !== PHASES.PLAYER_TURN;
  const battleEdge = getBattleEdge(playerHpPercent, npcHpPercent, playerHpState, npcHpState);
  const battleRank = getBattleRank(state.turnCount + 1, state.maxDamageDealt, playerHpPercent);

  useEffect(() => {
    setControllerFocusIndex((index) => Math.min(index, controllerCommandCount - 1));
  }, [controllerCommandCount]);

  useGamepadController({
    onDirectionPress: (direction) => {
      if (isResolvingTurn) return;
      if (direction === 'LEFT' || direction === 'UP') {
        playSound('uiHover');
        setControllerFocusIndex((index) => (index - 1 + controllerCommandCount) % controllerCommandCount);
      }
      if (direction === 'RIGHT' || direction === 'DOWN') {
        playSound('uiHover');
        setControllerFocusIndex((index) => (index + 1) % controllerCommandCount);
      }
    },
    onButtonPress: (button) => {
      if (button === 'Y') {
        playSound('uiConfirm');
        setAutoBattle((enabled) => !enabled);
        setControllerFocusIndex(controllerCommandCount - 1);
        return;
      }
      if (isResolvingTurn) return;
      if (button === 'B') {
        setControllerFocusIndex(playerMoves.length);
        handleMoveSelect('defend');
        return;
      }
      if (button === 'A' || button === 'START') {
        if (controllerFocusIndex < playerMoves.length) {
          handleMoveSelect(playerMoves[controllerFocusIndex].key);
        } else if (controllerFocusIndex === playerMoves.length) {
          handleMoveSelect('defend');
        } else {
          playSound('uiConfirm');
          setAutoBattle((enabled) => !enabled);
        }
      }
    },
  });

  return (
    <div
      ref={battleContainerRef}
      className={`battle-screen ${isResolvingTurn ? 'resolving' : 'awaiting'} player-${playerHpState} npc-${npcHpState}`}
      style={{ position: 'relative', width: '100%', height: '100%', overflow: 'hidden' }}
    >
      {/* Arena background */}
      <div className="arena pixelated" style={{ backgroundImage: `url(${npc.arena})`, filter: state.npc.arenaFilter || 'none' }} />
      <div className="arena-overlay" aria-hidden="true" />
      <div className="battle-telemetry-grid" aria-hidden="true">
        <span className="telemetry-node node-a" />
        <span className="telemetry-node node-b" />
        <span className="telemetry-node node-c" />
      </div>
      <div className="battle-scanline-sweep" aria-hidden="true" />
      <div className="battle-frame-corners" aria-hidden="true">
        <span className="corner tl" />
        <span className="corner tr" />
        <span className="corner bl" />
        <span className="corner br" />
        <span className="target-tick left" />
        <span className="target-tick right" />
      </div>

      {/* Top bar — HP */}
      <div className="panel panel-top">
        <div
          className={`hp-bar-container combatant-card enemy ${npcHpState}`}
          style={{ '--combatant-color': npcColor.primary, '--combatant-glow': npcColor.glow }}
        >
          <div className="hp-bar-label" style={{ color: npcColor.glow }}>
            {npcColor.icon} {npc.name} <span style={{ color: '#888' }}>Lv.{npc.level}</span>
            {state.currentPhase > 0 && battleConfig?.phases && (
              <span className="phase-indicator">
                PHASE {(state.currentPhase || 0) + 1}/{battleConfig.phases.length}
              </span>
            )}
          </div>
          <div className="hp-bar-track">
            <div
              className="hp-bar-fill"
              style={{
                width: `${npcHpPercent}%`,
                background: `linear-gradient(90deg, ${npcColor.primary}, ${npcColor.glow})`,
              }}
            />
          </div>
          <div className="hp-meta">
            <span>HP {state.npcHp}/{state.npcMaxHp}</span>
            <span>{npcHpState.toUpperCase()}</span>
          </div>
          <div className="combat-stat-strip">
            <span>ATK <strong>{npc.stats.atk}</strong></span>
            <span>DEF <strong>{npc.stats.def}</strong></span>
            <span>SPD <strong>{npc.stats.spd}</strong></span>
          </div>
          {state.npcStatus && (
            <div className={`status-indicator ${STATUS_EFFECTS[state.npcStatus.effect]?.name.toLowerCase().replace(' ', '')}`}>
              {STATUS_EFFECTS[state.npcStatus.effect]?.icon} {STATUS_EFFECTS[state.npcStatus.effect]?.name} {state.npcStatus.turnsLeft}t
            </div>
          )}
        </div>

        <div className="turn-chip">
          <span>{isResolvingTurn ? 'RESOLVING' : 'PLAYER TURN'}</span>
          <strong>TURN {state.turnCount + 1}</strong>
          <small>ENEMY: {getMoveProfileText(npc.moveKeys)}</small>
        </div>

        <div
          className={`hp-bar-container combatant-card player ${playerHpState}`}
          style={{ '--combatant-color': playerColor.primary, '--combatant-glow': playerColor.glow }}
        >
          <div className="hp-bar-label" style={{ color: playerColor.glow }}>
            <span style={{ color: '#888' }}>Lv.{state.playerLevel}</span> {playerColor.icon} {save.dragons[dragonId]?.nickname || dragon.name}
          </div>
          <div className="hp-bar-track">
            <div
              className="hp-bar-fill"
              style={{
                width: `${playerHpPercent}%`,
                background: `linear-gradient(90deg, ${playerColor.primary}, ${playerColor.glow})`,
                marginLeft: 'auto',
              }}
            />
          </div>
          <div className="hp-meta">
            <span>{playerHpState.toUpperCase()}</span>
            <span>HP {state.playerHp}/{state.playerMaxHp}</span>
          </div>
          <div className="combat-stat-strip player">
            <span>ATK <strong>{state.playerStats.atk}</strong></span>
            <span>DEF <strong>{state.playerStats.def}</strong></span>
            <span>SPD <strong>{state.playerStats.spd}</strong></span>
          </div>
          {state.playerStatus && (
            <div className={`status-indicator ${STATUS_EFFECTS[state.playerStatus.effect]?.name.toLowerCase().replace(' ', '')}`}>
              {STATUS_EFFECTS[state.playerStatus.effect]?.icon} {STATUS_EFFECTS[state.playerStatus.effect]?.name} {state.playerStatus.turnsLeft}t
            </div>
          )}
        </div>
      </div>

      {/* Arena sprites */}
      <div className="arena-sprites">
        <div
          ref={npcSpriteContainerRef}
          className={`combatant-anchor enemy ${npcHpState}`}
          style={{ '--anchor-color': npcColor.primary, '--anchor-glow': npcColor.glow }}
        >
          <span className="combatant-scan-pad enemy" aria-hidden="true" />
          <div className="combatant-nameplate enemy">
            <span>HOSTILE</span>
            <strong>{npc.name}</strong>
          </div>
          <NpcSprite
            ref={npcSpriteImgRef}
            idleSprite={npc.idleSprite}
            attackSprite={npc.attackSprite}
            isAttacking={state.npcAttacking}
            className={state.npcSpriteClass}
            flipX={npc.flipSprite}
            style={{ filter: state.npc.spriteFilter || 'none' }}
          />
          {state.damageNumbers
            .filter((d) => d.target === 'npc')
            .map((d) => (
              <DamageNumber
                key={d.id}
                damage={d.damage}
                effectiveness={d.effectiveness}
                hit={d.hit}
                isCritical={d.isCritical || false}
                isStatusTick={d.isStatusTick || false}
                statusElement={d.statusElement}
                variant={d.variant}
                label={d.label}
                staggerIndex={d.staggerIndex || 0}
                position={d.position || { x: 40, y: -20 }}
                onComplete={() => dispatch({ type: 'REMOVE_DAMAGE_NUMBER', id: d.id })}
              />
            ))}
        </div>

        <div
          ref={playerSpriteContainerRef}
          className={`combatant-anchor player ${playerHpState}`}
          style={{ '--anchor-color': playerColor.primary, '--anchor-glow': playerColor.glow }}
        >
          <span className="combatant-scan-pad player" aria-hidden="true" />
          <div className="combatant-nameplate player">
            <span>GUARDIAN</span>
            <strong>{save.dragons[dragonId]?.nickname || dragon.name}</strong>
          </div>
          <DragonSprite
            ref={playerSpriteRef}
            spriteSheet={dragon.stageSprites?.[state.playerStage] || dragon.spriteSheet}
            stage={state.playerStage}
            flipX={!dragon.facesLeft}
            forcedFrame={state.playerForcedFrame}
            className={state.playerSpriteClass}
            element={dragon.element}
          />
          {state.damageNumbers
            .filter((d) => d.target === 'player')
            .map((d) => (
              <DamageNumber
                key={d.id}
                damage={d.damage}
                effectiveness={d.effectiveness}
                hit={d.hit}
                isCritical={d.isCritical || false}
                isStatusTick={d.isStatusTick || false}
                statusElement={d.statusElement}
                variant={d.variant}
                label={d.label}
                staggerIndex={d.staggerIndex || 0}
                position={d.position || { x: 40, y: -20 }}
                onComplete={() => dispatch({ type: 'REMOVE_DAMAGE_NUMBER', id: d.id })}
              />
            ))}
        </div>

        {/* VFX overlay */}
        {state.vfxActive && (
          <VfxOverlay
            vfxKey={state.vfxActive.vfxKey}
            element={state.vfxActive.element}
            direction={state.vfxActive.direction}
            targetSide={state.vfxActive.targetSide}
            onComplete={state.vfxActive.onComplete}
          />
        )}
      </div>

      <div className={`battle-edge-chip ${battleEdge.tone} ${state.battleLog.length > 0 ? 'log-open' : ''}`}>
        <span>{battleEdge.label}</span>
        <strong>{battleEdge.detail}</strong>
      </div>

      {state.battleCallout && (
        <div className={`battle-callout ${state.battleCallout.variant}`}>
          {state.battleCallout.text}
        </div>
      )}

      {/* Battle log */}
      {state.battleLog.length > 0 && (
        <div className={`battle-log ${state.phase === PHASES.ANIMATING ? 'resolving' : ''}`}>
          <div className="battle-log-title">
            <span><i aria-hidden="true" /> COMBAT FEED</span>
            <strong>{state.phase === PHASES.ANIMATING ? 'LIVE' : 'READY'}</strong>
          </div>
          {state.battleLog.slice(-3).map((text, i) => (
            <div key={`${text}-${i}`} className={`battle-log-entry ${i === Math.min(2, state.battleLog.length - 1) ? 'latest' : ''}`}>
              <span aria-hidden="true">▸</span>
              <p>{text}</p>
            </div>
          ))}
        </div>
      )}

      {/* Bottom panel — moves */}
      <div className="panel panel-bottom">
        <div className="move-panel-header">
          <span>{isResolvingTurn ? 'EXECUTING COMMAND' : 'SELECT TECHNIQUE'}</span>
          <strong>{selectedMoveKey ? (moves[selectedMoveKey]?.name || selectedMoveKey).toUpperCase() : 'READY'}</strong>
        </div>
        <div className={`command-readout ${isResolvingTurn ? 'resolving' : 'ready'}`} aria-hidden="true">
          <span />
          <span />
          <span />
          <i />
        </div>
        <div className="move-panel">
          {playerMoves.map((move, index) => {
            const moveColor = elementColors[move.element] || elementColors.neutral;
            const isResolving = isResolvingTurn;
            const isSelected = selectedMoveKey === move.key;
            const matchup = getMoveEffectivenessLabel(move.element, npc.element);
            return (
              <button
                key={move.key}
                className={`move-btn ${isSelected ? 'selected' : ''} ${controllerFocusIndex === index ? 'controller-focus' : ''} ${isResolving && !isSelected ? 'dimmed' : ''} ${matchup.toLowerCase()}`}
                style={{ '--move-color': moveColor.primary, '--move-glow': moveColor.glow, borderColor: moveColor.primary, color: moveColor.glow }}
                disabled={isResolving}
                onClick={() => handleMoveSelect(move.key)}
              >
                <span className="tooltip">PWR:{move.power} ACC:{move.accuracy}%</span>
                <strong>{move.name.toUpperCase()}</strong>
                <span className="move-meta">
                  <i>{moveColor.icon} {move.element.toUpperCase()}</i>
                  <i>PWR {move.power}</i>
                  <i>{matchup}</i>
                </span>
              </button>
            );
          })}
          <button
            className={`move-btn ${selectedMoveKey === 'defend' ? 'selected' : ''} ${controllerFocusIndex === playerMoves.length ? 'controller-focus' : ''} ${state.phase !== PHASES.PLAYER_TURN && selectedMoveKey !== 'defend' ? 'dimmed' : ''}`}
            style={{ '--move-color': '#44aa44', '--move-glow': '#66cc66', borderColor: '#44aa44', color: '#66cc66' }}
            disabled={state.phase !== PHASES.PLAYER_TURN}
            onClick={() => handleMoveSelect('defend')}
          >
            <span className="tooltip">Halves damage this turn</span>
            <strong>DEFEND</strong>
            <span className="move-meta">
              <i>SHIELD</i>
              <i>DMG -50%</i>
              <i>GUARD</i>
            </span>
          </button>
          <button
            className={`move-btn auto ${autoBattle ? 'selected' : ''} ${controllerFocusIndex === playerMoves.length + 1 ? 'controller-focus' : ''}`}
            style={{ '--move-color': autoBattle ? '#44cc44' : '#666', '--move-glow': autoBattle ? '#44cc44' : '#888', borderColor: autoBattle ? '#44cc44' : '#666', color: autoBattle ? '#44cc44' : '#888' }}
            onClick={() => setAutoBattle(!autoBattle)}
          >
            <strong>{autoBattle ? 'AUTO: ON' : 'AUTO: OFF'}</strong>
            <span className="move-meta">
              <i>AI LOOP</i>
              <i>{autoBattle ? 'ARMED' : 'MANUAL'}</i>
            </span>
          </button>
        </div>
      </div>

      {/* Victory overlay */}
      {state.phase === PHASES.VICTORY && (
        <div className="result-overlay victory">
          <div className="result-card">
            <span className="result-kicker">COMBAT COMPLETE</span>
            <h2>VICTORY!</h2>
            <div className={`battle-rank rank-${battleRank.toLowerCase()}`}>
              <span>BATTLE RANK</span>
              <strong>{battleRank}</strong>
            </div>
            <div className="result-summary-grid">
              <div>
                <span>XP</span>
                <strong>+{state.xpGained}</strong>
              </div>
              <div>
                <span>SCRAPS</span>
                <strong>{state.scrapsGained > 0 ? `+${state.scrapsGained}` : '0'}</strong>
              </div>
              <div>
                <span>TURNS</span>
                <strong>{state.turnCount + 1}</strong>
              </div>
              <div>
                <span>MAX HIT</span>
                <strong>{state.maxDamageDealt}</strong>
              </div>
            </div>
          {state.leveledUp && (
            <div className="level-up-display">LEVEL UP! Now Lv.{state.newLevel}</div>
          )}
          {state.coreDropped && (
            <div className="core-drop-display" style={{ color: elementColors[state.coreDropped.element]?.glow || '#44aaff' }}>
              +{state.coreDropped.count} {state.coreDropped.element.toUpperCase()} CORE{state.coreDropped.count > 1 ? 'S' : ''}
            </div>
          )}
            <button className="result-btn" onClick={onBattleEnd}>CONTINUE</button>
          </div>
        </div>
      )}

      {/* Defeat overlay */}
      {state.phase === PHASES.DEFEAT && (
        <div className="result-overlay defeat">
          <div className="result-card">
            <span className="result-kicker">SIGNAL LOST</span>
            <h2>DEFEATED</h2>
            <div className="battle-rank rank-retry">
              <span>ASSESSMENT</span>
              <strong>RETRY</strong>
            </div>
            <div className="result-summary-grid">
              <div>
                <span>TURNS</span>
                <strong>{state.turnCount + 1}</strong>
              </div>
              <div>
                <span>MAX HIT</span>
                <strong>{state.maxDamageDealt}</strong>
              </div>
              <div>
                <span>ENEMY HP</span>
                <strong>{state.npcHp}/{state.npcMaxHp}</strong>
              </div>
              <div>
                <span>STATUS</span>
                <strong>RETRY</strong>
              </div>
            </div>
            <p>
              "Hmm, a setback! But every great Dragon Forger learns from defeat. Recalibrate and try again!"
              <br />— Professor Felix
            </p>
            <button className="result-btn" onClick={onBattleEnd}>TRY AGAIN</button>
          </div>
        </div>
      )}

      {/* Epilogue overlay */}
      {state.phase === PHASES.EPILOGUE && (
        <div className="epilogue-overlay">
          <div className="epilogue-portrait">
            <img src={`${import.meta.env.BASE_URL}assets/felix_pixel.jpg`} alt="Professor Felix" className="pixelated" />
          </div>
          <div className="epilogue-text">
            {EPILOGUE_LINES.map((line, i) => (
              <div key={i}>"{line}"</div>
            ))}
          </div>
          <div className="epilogue-rewards">
            <div style={{ color: '#44aaff' }}>+{state.xpGained} XP</div>
            {state.scrapsGained > 0 && <div style={{ color: '#ffcc00' }}>+{state.scrapsGained} ◆</div>}
          </div>
          <button className="epilogue-btn" onClick={onBattleEnd}>
            RETURN TO THE FORGE
          </button>
        </div>
      )}
    </div>
  );
}
