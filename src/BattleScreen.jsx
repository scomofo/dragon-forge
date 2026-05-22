import { useState, useReducer, useCallback, useEffect, useRef } from 'react';
import { wait } from './utils';
import { playSound, playMusic, stopMusic, startHeartbeat, stopHeartbeat } from './soundEngine';
import { dragons, npcs, moves, elementColors, STATUS_EFFECTS } from './gameData';
import {
  resolveTurn, pickNpcMove, calculateStatsForLevel,
  getStageForLevel, calculateXpGain, getTypeEffectivenessLabel,
} from './battleEngine';
import { loadSave, saveDragonProgress, addScraps, recordNpcDefeat, recordSingularityDefeat, markSingularityComplete, addCore, decrementXpBoost, trackStat, completeDailyChallenge, updateRecords, unlockFragment } from './persistence';
import { FRAGMENT_TRIGGERS } from './forgeData';
import { CORE_DROP_CHANCE, CORE_DOUBLE_CHANCE } from './shopItems';
import { EPILOGUE_LINES } from './singularityBosses';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';
import DamageNumber from './DamageNumber';
import VfxOverlay from './VfxOverlay';
import { getBattlePresentationProfile, getBattleResultCallout, getStatusMoveSummary, shouldAnimateBattleEvent } from './battlePresentation';
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
  if (playerLevel <= baseLevel) return { stats: baseStats, level: baseLevel };
  const scale = 1 + (playerLevel - baseLevel) * 0.04;
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
  if (playerHpState === 'danger') return { tone: 'danger', label: 'DANGER', detail: 'HOLD LINE' };
  if (npcHpState === 'danger') return { tone: 'advantage', label: 'PRESSURE', detail: 'FINISH IT' };
  const delta = playerHpPercent - npcHpPercent;
  if (delta >= 18) return { tone: 'advantage', label: 'EDGE', detail: 'PLAYER' };
  if (delta <= -18) return { tone: 'warning', label: 'EDGE', detail: 'ENEMY' };
  return { tone: 'neutral', label: 'EDGE', detail: 'EVEN' };
}

function getBattleRank(turnCount, maxDamage, playerHpPercent) {
  let score = 0;
  if (turnCount <= 3) score += 2; else if (turnCount <= 5) score += 1;
  if (maxDamage >= 24) score += 2; else if (maxDamage >= 14) score += 1;
  if (playerHpPercent >= 70) score += 2; else if (playerHpPercent >= 40) score += 1;
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
  const stats = calculateStatsForLevel(progress.fusePower || 0, progress.level, (progress.shiny || false));
  return {
    phase: PHASES.PLAYER_TURN,
    dragon: { ...dragon, stats, stage, level: progress.level, shiny: progress.shiny },
    npc,
    playerHp: stats.hp,
    playerMaxHp: stats.hp,
    npcHp: npc.stats.hp,
    npcMaxHp: npc.stats.hp,
    playerStatus: null,
    npcStatus: null,
    turnCount: 0,
    maxDamageDealt: 0,
    battleLog: [],
    vfxActive: null,
    battleCallout: null,
    currentPhase: 1,
  };
}

function battleReducer(state, action) {
  switch (action.type) {
    case 'START_ANIMATION': return { ...state, phase: PHASES.ANIMATING };
    case 'SET_PLAYER_SPRITE_CLASS': return { ...state, playerSpriteClass: action.value };
    case 'SET_PLAYER_FORCED_FRAME': return { ...state, playerForcedFrame: action.value };
    case 'SET_NPC_SPRITE_CLASS': return { ...state, npcSpriteClass: action.value };
    case 'SET_NPC_ATTACKING': return { ...state, npcAttacking: action.value };
    case 'APPLY_DAMAGE_TO_PLAYER': return { ...state, playerHp: Math.max(0, state.playerHp - action.damage) };
    case 'APPLY_DAMAGE_TO_NPC': return { ...state, npcHp: Math.max(0, state.npcHp - action.damage) };
    case 'SET_VFX': return { ...state, vfxActive: action.value };
    case 'CLEAR_VFX': return { ...state, vfxActive: null };
    case 'SET_BATTLE_CALLOUT': return { ...state, battleCallout: action.value };
    case 'CLEAR_BATTLE_CALLOUT': return { ...state, battleCallout: null };
    case 'ADD_LOG': return { ...state, battleLog: [...state.battleLog, action.text] };
    case 'TRACK_DAMAGE': return { ...state, maxDamageDealt: Math.max(state.maxDamageDealt, action.damage) };
    case 'ADD_DAMAGE_NUMBER': return { ...state, damageNumbers: [...(state.damageNumbers || []), action.entry] };
    case 'SET_PLAYER_STATUS': return { ...state, playerStatus: action.value };
    case 'SET_NPC_STATUS': return { ...state, npcStatus: action.value };
    case 'RESET_TURN': return { ...state, phase: PHASES.PLAYER_TURN, npcAttacking: false, playerSpriteClass: '', npcSpriteClass: '', playerForcedFrame: null };
    case 'PHASE_SHIFT': return {
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
    case 'SET_VICTORY': return { ...state, phase: PHASES.VICTORY, xpGained: action.xpGained, leveledUp: action.leveledUp, newLevel: action.newLevel, scrapsGained: action.scrapsGained, coreDropped: action.coreDropped };
    case 'SET_DEFEAT': return { ...state, phase: PHASES.DEFEAT };
    case 'SET_EPILOGUE': return { ...state, phase: PHASES.EPILOGUE, xpGained: action.xpGained, scrapsGained: action.scrapsGained };
    default: return state;
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
        if (isPlayer) shieldRef.current = shield;
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
      if (isPlayer) dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
      else dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-telegraph' });
      await wait(500);
      if (isPlayer) dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      else dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      return;
    }

    const move = moves[event.moveKey] || moves.basic_attack;
    const profile = getBattlePresentationProfile(event, move);

    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: profile.attackerClass });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: profile.attackerClass });
    }
    playSound('attackLaunch');
    await wait(profile.anticipationMs);

    const vfxElement = move.element === 'neutral' ? 'neutral' : move.element;
    const vfxDirection = isPlayer ? 'left-to-right' : 'right-to-left';
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

    await wait(110);
    playSound('lungeContact');

    if (event.hit) {
      if (event.reflected) {
        if (isPlayer) dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        else dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
      } else {
        if (isPlayer) dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        else dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
      }

      const hitSoundName = profile.sound;
      const container = battleContainerRef.current;
      const targetContainer = isPlayer
        ? (event.reflected ? playerSpriteContainerRef.current : npcSpriteContainerRef.current)
        : (event.reflected ? npcSpriteContainerRef.current : playerSpriteContainerRef.current);
      const targetSide = isPlayer ? (event.reflected ? 'right' : 'left') : (event.reflected ? 'left' : 'right');
      const targetSpriteEl = targetContainer === playerSpriteContainerRef.current
        ? (playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current)
        : npcSpriteImgRef.current;
      const targetDefending = isPlayer ? state.npcDefending : state.playerDefending;

      if (targetDefending && shieldRef.current) {
        shieldDeflect(shieldRef.current.element, targetContainer, isPlayer ? 'right' : 'left');
        playSound('shieldDeflectSting');
        if (container) pixelShake(container, 3, 0.12);
      } else if (event.isCritical && container) {
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
        await hitStop(profile.impactPauseMs / 1000);
        playSound(hitSoundName, { element: move.element });
        const intensity = Math.max(profile.shake, Math.min(8, Math.round(4 + hpRatio * 8)));
        pixelShake(container, intensity, 0.18);
        if (targetContainer) {
          const flashColor = event.effectiveness > 1.0
 laT_S_D_N_C_H_S_P_ a l l a t e r a l t e r n a t i v e s .
        }
        if (targetSpriteEl) hitFlicker(targetSpriteEl, isHeavy ? 4 : 3);
        if (targetContainer) la
        }
      }
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
      await wait(profile.recoveryMs);
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
        hit: true,
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
      const effText = event.effectiveness > 1 ? ' Super effective!' : event.effectiveness < 1 ? ' laResisted.' : '';
 la
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
      if (playerAuraRef.current) la
    }
  }, []);

  const handleMoveSelect = useCallback(async (moveKey) => {
    if (animatingRef.current) return;
    playSound('commandSelect', { element: moves[moveKey]?.element });
     la
    }
  }, [state, animateEvent]);

  const dragon = state.dragon;
  const npc = state.npc;
  const playerMoves = [...dragon.moveKeys.map((k) => ({ key: k, ...moves[k] })), { key: 'basic_attack으로 a s t r i n g s a l l y a l t e r a t i v e s .
  const controllerCommandCount = playerMoves.length + 2;
  const playerColor = elementColors[dragon.element];
  const npcColor = elementColors[npc.element];
  const playerHpState = getHpState(state.playerHp, state.playerMaxHp);
  const npcHpState = getHpState(state.npcHp, state.npcMaxHp);
  const playerHpPercent = Math.max(0, Math.min(100, (state.playerHp / state.playerMaxH l a t e r a l t e r n a t i v e s .
  const isResolvingTurn = state.phase !== PHASES.PLAYER_TURN;
  const battleEdge = getBattleEdge(playerHpPercent, npcHpPercent, playerHpState, npcHpState);
  const la
  const battleRank = getBattleRank(turnCount + 1, state.maxDamageDealt, playerHpPercent);
  const isVictory = state.phase === PHASES.VICTORY;
  const isDefeat = state.phase === PHASES.DEFEAT;
  const isEpilogue = state.phase === PHASES.EPILOGUE;
  const isPlayerTurn = state.phase === PHASES.PLAYER_TURN;
}
