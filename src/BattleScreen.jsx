import { useState, useReducer, useCallback, useEffect, useRef } from 'react';
import { battleWait, getBattleSpeed, setBattleSpeed, scaleBattleDuration } from './battleSpeed';
import { playSound, playMusic, stopMusic, startHeartbeat, stopHeartbeat } from './soundEngine';
import { dragons, npcs, moves, elementColors, STATUS_EFFECTS, DUAL_TECHS } from './gameData';
import { resolveDualTech } from './gameData';
import {
  resolveTurn, pickNpcMove, calculateStatsForLevel,
  getStageForLevel, calculateXpGain, getTypeEffectivenessLabel,
  CHARGE_ATK_MULTIPLIER,
} from './battleEngine';
import { loadSave, addDragonXp, addScraps, recordNpcDefeat, recordSingularityDefeat, markSingularityComplete, markMirrorAdminDefeated, addCore, decrementXpBoost, grantRelic, incrementBountiesCleared, setLastZone, trackStat, completeDailyChallenge, updateRecords, unlockFragment, getRankBonusScraps, recordBattleRank } from './persistence';
import { getDailyStreakMultiplier } from './dailyChallenge';
import { getExpedition } from './expeditions';
import { FRAGMENT_TRIGGERS, RELIC_DROPS, getRelic, getRelicBattleModifiers } from './forgeData';
import { CORE_DROP_CHANCE, CORE_DOUBLE_CHANCE } from './shopItems';
import { swapActiveAndBench, faintSwap } from './benchLogic';
import { EPILOGUE_LINES, MIRROR_ADMIN_EPILOGUE_LINES } from './singularityBosses';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';
import DamageNumber from './DamageNumber';
import VfxOverlay from './VfxOverlay';
import { getBattlePresentationProfile, getBattleContactState, hasDamagingImpact, getBattleResultCallout, getStatusMoveSummary, getSignatureSummary, shouldAnimateBattleEvent } from './battlePresentation';
import { resolveBattlePose } from './battleSets';
import { resolveBattleArena } from './arenas';
import BattleCues from './BattleCues';
import { getBattleCues } from './battleCueModel';
import { getBattleCommands, cycleBattleCommand, getBattleKeyboardCommand } from './battleCommands';
import { getDefeatAdvice } from './battleAdvice';
import { advanceHydraHeads, resetsMemoryLeak, HYDRA_HEAD_COUNT, HYDRA_HP_FLOOR } from './bossMechanics';
import useGamepadController from './useGamepadController';
import {
  screenShake, hitFlash, criticalHit, shatterKO,
  shieldUp, shieldDeflect, shieldDismiss,
  statusAuraApply, npcLunge, playerLunge, hitSquash,
  pixelShake, hitStop, targetKnockback, hitFlicker,
} from './animationEngine';
import { isLogicBombDetonationDue, createCorruptionState, getCorruptedMoveKey } from './bossMechanics';

const PHASES = {
  PLAYER_TURN: 'playerTurn',
  ANIMATING: 'animating',
  VICTORY: 'victory',
  DEFEAT: 'defeat',
  PHASE_SHIFT: 'phaseShift',
  EPILOGUE: 'epilogue',
};

function getScaledNpcStats(baseStats, baseLevel, playerLevel, ngPlus = 0) {
  // Scale NPC stats by how far the player out-levels them, plus +25% per New
  // Game+ tier so re-runs stay a real fight against a maxed roster.
  const levelScale = 1 + Math.max(0, playerLevel - baseLevel) * 0.04; // +4% per level above NPC
  const scale = levelScale * (1 + ngPlus * 0.25);
  if (scale === 1) return { stats: baseStats, level: baseLevel };
  const scaledStats = {};
  for (const key of Object.keys(baseStats)) {
    scaledStats[key] = Math.floor(baseStats[key] * scale);
  }
  return { stats: scaledStats, level: Math.max(baseLevel, Math.floor(baseLevel + Math.max(0, playerLevel - baseLevel) * 0.5)) };
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
      idleSprite: phase?.idleSprite || boss.idleSprite,
      attackSprite: phase?.attackSprite || boss.attackSprite,
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
    const scaled = getScaledNpcStats(baseNpc.stats, baseNpc.level, progress.level, save.ngPlus || 0);
    npc = { ...baseNpc, stats: scaled.stats, level: scaled.level };
  }
  const progress = save.dragons[dragonId] || { level: 1, xp: 0 };
  const stage = getStageForLevel(progress.level);
  const stats = calculateStatsForLevel(progress.fusedBaseStats || dragon.baseStats, progress.level, progress.shiny);

  // Optional reserve dragon (the "bench"): a second life + a tactical mid-fight
  // swap. Wired for free battles (B7) and campaign nodes; bosses/Singularity
  // stay single-dragon so their fixed-TTK balance holds.
  let bench = null;
  const benchId = battleConfig?.benchDragonId;
  if (benchId && benchId !== dragonId && save.dragons[benchId]?.owned && dragons[benchId]) {
    const bDragon = dragons[benchId];
    const bProg = save.dragons[benchId] || { level: 1, xp: 0 };
    const bStats = calculateStatsForLevel(bProg.fusedBaseStats || bDragon.baseStats, bProg.level, bProg.shiny);
    bench = {
      dragon: bDragon,
      dragonId: benchId,
      playerLevel: bProg.level,
      playerXp: bProg.xp,
      playerStage: getStageForLevel(bProg.level),
      playerStats: bStats,
      playerHp: bStats.hp,
      playerMaxHp: bStats.hp,
      playerStatus: null,
      playerAtkBuff: null,
      playerDefBuff: null,
    };
  }

  // Per-boss pattern state init is per-pattern (only the fields a given boss needs).
  const bossPatternId = npc.id;
  const bossState = {
    heatStacks: 0,                       // buffer_overflow
    pierceNext: false,                   // bit_wraith
    prevElement: null, decrypted: false, // crypto_crab
    headsBroken: 0,                      // glitch_hydra
    fuseTurns: 6, fuseDetonated: false,   // logic_bomb
    hardenStacks: 0,                     // recursive_golem
    perchUsed: false,                    // protocol_vulture
    garbledMoveKey: null, garbledTurnsLeft: 0, garbledDragonId: null, // data_corruption (uses)
    leakPips: 0,                         // memory_leak
    spdDoubleTurnsLeft: 0, surgeUsed: false, crashTurnsLeft: 0, // stack_overflow
    // mirror_admin_reset (deferred-boss pattern — the Great Reset punishes a
    // no-heal Phase 3: if the player faints without spending Restoration/
    // Recompile THIS PHASE, Mirror Admin heals 25% max HP).
    mirrorHealPunished: false,
  };
  // Telegraph the affected slot before the first command can be selected.
  if (bossPatternId === 'data_corruption') Object.assign(bossState, createCorruptionState(dragonId, dragon.moveKeys));

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
    bench,
    npcAtkBuff: null,
    npcDefBuff: null,
    npcChargedMove: null,
    signatureMoveUsed: false,
    playerSignatureUsed: {},
    dualTechUsed: false,
    playerAtkBuff: null,
    playerDefBuff: null,
    playerMoveHistory: [],
    phaseMoveHistory: [],
    bossPatternId,
    bossState,
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
    case 'SET_CONTACT_POSES':
      return { ...state, ...action.value };
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
      return { ...state, phase: PHASES.VICTORY, xpGained: action.xpGained, leveledUp: action.leveledUp, newLevel: action.newLevel, scrapsGained: action.scrapsGained || 0, coreDropped: action.coreDropped || null, streakMultiplier: action.streakMultiplier || 1, relicDropped: action.relicDropped || null, wasRepeat: action.wasRepeat || false, rankBonus: action.rankBonus || 0, stageEvolved: action.stageEvolved || null };
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
      if (action.id != null && state.vfxActive?.id !== action.id) return state;
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
        turnCount: state.turnCount + 1,
        // mirror_admin_reset per-phase constraint resets on phase shift.
        phaseMoveHistory: [],
      };
    case 'SET_EPILOGUE':
      return { ...state, phase: PHASES.EPILOGUE, xpGained: action.xpGained, scrapsGained: action.scrapsGained, isMirrorAdmin: action.isMirrorAdmin || false };
    case 'SET_NPC_ATK_BUFF':
      return { ...state, npcAtkBuff: action.value };
    case 'SET_NPC_DEF_BUFF':
      return { ...state, npcDefBuff: action.value };
    case 'SET_PLAYER_ATK_BUFF':
      return { ...state, playerAtkBuff: action.value };
    case 'SET_PLAYER_DEF_BUFF':
      return { ...state, playerDefBuff: action.value };
    case 'SET_PLAYER_SIGNATURE_USED':
      return { ...state, playerSignatureUsed: { ...(state.playerSignatureUsed || {}), [action.dragonId]: true } };
    case 'SET_DUAL_TECH_USED':
      return { ...state, dualTechUsed: true };
    case 'APPLY_HEAL_TO_PLAYER':
      return { ...state, playerHp: Math.min(state.playerMaxHp, state.playerHp + action.amount) };
    case 'APPLY_HEAL_TO_NPC':
      return { ...state, npcHp: Math.min(state.npcMaxHp, state.npcHp + action.amount) };
    case 'SYNC_BATTLE_RESULT':
      // Animations show each contact; the resolved turn owns the settled state.
      return {
        ...state,
        playerHp: Math.max(0, Math.min(state.playerMaxHp, action.result.player.hp)),
        npcHp: Math.max(0, Math.min(state.npcMaxHp, action.result.npc.hp)),
        playerStatus: action.result.player.status || null,
        npcStatus: action.result.npc.status || null,
        playerAtkBuff: action.result.player.atkBuff || null,
        playerDefBuff: action.result.player.defBuff || null,
        npcAtkBuff: action.result.npc.atkBuff || null,
        npcDefBuff: action.result.npc.defBuff || null,
      };
    case 'SET_NPC_CHARGED_MOVE':
      return { ...state, npcChargedMove: action.value };
    case 'CLEAR_NPC_CHARGED_MOVE':
      return { ...state, npcChargedMove: null };
    case 'SET_SIGNATURE_USED':
      return { ...state, signatureMoveUsed: true };
    case 'APPEND_PLAYER_MOVE_HISTORY':
      return {
        ...state,
        playerMoveHistory: [...(state.playerMoveHistory || []), action.moveKey],
        // Per-phase history for the mirror_admin_reset constraint (reset on
        // phase shift, not a rolling window).
        phaseMoveHistory: [...(state.phaseMoveHistory || []), action.moveKey],
      };
    case 'SET_BOSS_STATE':
      return { ...state, bossState: { ...state.bossState, ...action.value } };
    case 'SWAP_DRAGON':
      // Manual tactical swap: exchange the active dragon with the reserve.
      return swapActiveAndBench(state);
    case 'FAINT_SWAP':
      // The active fell; the reserve steps in (its remaining HP) — the second life.
      return faintSwap(state, PHASES.PLAYER_TURN, action.advanceTurn !== false);
    default:
      return state;
  }
}

export default function BattleScreen({ dragonId, npcId, onBattleEnd, onRetryBattle, save, refreshSave, battleConfig }) {
  const [state, dispatch] = useReducer(battleReducer, null, () => initBattle(dragonId, npcId, save, battleConfig));
  const animatingRef = useRef(false);
  const damageIdRef = useRef(0);
  const [autoBattle, setAutoBattle] = useState(false);
  // C4: 1x/2x battle speed — retimes waits, presentation tables, and GSAP.
  const [speed, setSpeed] = useState(() => getBattleSpeed());
  const toggleSpeed = useCallback(() => {
    playSound('uiConfirm');
    setSpeed(setBattleSpeed(getBattleSpeed() === 1 ? 2 : 1));
  }, []);
  // AUTO-battle is a farm convenience; it must never trivialize high-stakes fights.
  // Disabled for bosses, the Singularity arc, the Mirror Admin, Corruption Remnants, and the Daily Challenge.
  const autoBattleAllowed = !(
    battleConfig?.boss ||
    battleConfig?.isSingularity ||
    battleConfig?.isMirrorAdmin ||
    battleConfig?.isRemnant ||
    battleConfig?.dailyNpc
  );
  // P2: each fight class owns its calm track. Gatekeepers/remnants are 'boss';
  // only the Singularity itself plays the dread commission; Mirror Admin has
  // its own. Used when the fight re-opens after a bench swap.
  const baseTrack = battleConfig?.isMirrorAdmin
    ? 'mirrorAdmin'
    : battleConfig?.npcId === 'singularity'
      ? 'singularity'
      : (battleConfig?.isSingularity || battleConfig?.isRemnant || battleConfig?.boss)
        ? 'boss'
        : 'battle';
  const [selectedMoveKey, setSelectedMoveKey] = useState(null);
  const [controllerFocusId, setControllerFocusId] = useState(() => dragons[dragonId].moveKeys[0]);
  const [signatureFocus, setSignatureFocus] = useState(false);
  // P4: firewall_sentinel's authored pattern — the shield holds unless the
  // player Defended last turn (waited out the cycle) or pierces (Phase Strike).
  const playerDefendedLastTurn = useRef(false);
  // T8: every bare setTimeout gets tracked here so unmount can cancel pending
  // sound/dispatch callbacks instead of them firing into a dead tree.
  const pendingTimersRef = useRef(new Set());
  const trackedTimeout = useCallback((fn, ms) => {
    const id = setTimeout(() => {
      pendingTimersRef.current.delete(id);
      fn();
    }, ms);
    pendingTimersRef.current.add(id);
    return id;
  }, []);
  // C5: entrance overlay — stamps both combatants in before input unlocks.
  const [introDone, setIntroDone] = useState(false);
  const retryStartedRef = useRef(false);
  useEffect(() => {
    playSound('attackLaunch', { element: state.npc.element });
    trackedTimeout(() => setIntroDone(true), Math.round(850 / getBattleSpeed()));
  }, []);

  const battleContainerRef = useRef(null);
  const playerSpriteContainerRef = useRef(null);
  const npcSpriteContainerRef = useRef(null);
  const playerSpriteRef = useRef(null);
  const npcSpriteImgRef = useRef(null);
  const shieldRef = useRef(null);
  const playerAuraRef = useRef(null);
  const npcAuraRef = useRef(null);
  const damageStaggerRef = useRef(0);

  useEffect(() => {
    return () => {
      for (const id of pendingTimersRef.current) clearTimeout(id);
      pendingTimersRef.current.clear();
      if (playerAuraRef.current) playerAuraRef.current.kill();
      if (npcAuraRef.current) npcAuraRef.current.kill();
      stopHeartbeat();
    };
  }, []);

  const animateEvent = useCallback(async (event, dispatch, battleState = state) => {
    const isPlayer = event.attacker === 'player';
    const who = isPlayer ? 'You' : event.moveName ? 'Enemy' : 'Status';

    if (event.action === 'defend') {
      dispatch({ type: 'ADD_LOG', text: `${who} defended.` });
      playSound('combatMessage');
      playSound('defend');
      const targetContainer = isPlayer ? playerSpriteContainerRef.current : npcSpriteContainerRef.current;
      if (targetContainer) {
        const shield = shieldUp(targetContainer, isPlayer ? battleState.dragon.element : battleState.npc.element);
        if (isPlayer) {
          shieldRef.current = shield;
        }
      }
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
        await battleWait(400);
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
      await battleWait(500);
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      } else {
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      }
      return;
    }

    if (event.action === 'buff') {
      const statLabel = event.buffStat === 'atk' ? 'ATTACK' : 'DEFENSE';
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — ${statLabel} raised!` });
      playSound('combatMessage');
      playSound('statusApply', { element: isPlayer ? battleState.dragon.element : battleState.npc.element });
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
      } else {
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-telegraph' });
      }
      dispatch({ type: 'SET_BATTLE_CALLOUT', value: { text: 'FORTIFY', variant: 'buff' } });
      trackedTimeout(() => dispatch({ type: 'CLEAR_BATTLE_CALLOUT' }), 700);
      const dmgId = ++damageIdRef.current;
      dispatch({
        type: 'ADD_DAMAGE_NUMBER',
        entry: {
          id: dmgId, damage: 0, effectiveness: 1.0, hit: true,
          target: isPlayer ? 'player' : 'npc',
          variant: 'buff',
          label: `${statLabel} UP`,
          staggerIndex: 0,
          position: { x: 30, y: -40 },
        },
      });
      await battleWait(600);
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      await battleWait(200);
      return;
    }

    if (event.action === 'heal') {
      const healed = event.healAmount || 0;
      dispatch({ type: isPlayer ? 'APPLY_HEAL_TO_PLAYER' : 'APPLY_HEAL_TO_NPC', amount: healed });
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — restored ${healed} HP.` });
      playSound('combatMessage');
      playSound('statusApply', { element: isPlayer ? battleState.dragon.element : battleState.npc.element });
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
      } else {
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-telegraph' });
      }
      dispatch({ type: 'SET_BATTLE_CALLOUT', value: { text: 'RESTORE', variant: 'heal' } });
      trackedTimeout(() => dispatch({ type: 'CLEAR_BATTLE_CALLOUT' }), 700);
      const healId = ++damageIdRef.current;
      dispatch({
        type: 'ADD_DAMAGE_NUMBER',
        entry: {
          id: healId, damage: healed, effectiveness: 1.0, hit: true,
          target: isPlayer ? 'player' : 'npc',
          variant: 'heal',
          label: `+${healed}`,
          staggerIndex: 0,
          position: { x: 30, y: -40 },
        },
      });
      await battleWait(600);
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      await battleWait(200);
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
    playSound('attackLaunch', { element: move.element });
    await battleWait(profile.anticipationMs);

    // VFX TRAVEL + IMPACT phase
    const vfxElement = move.element === 'neutral' ? 'neutral' : move.element;
    const vfxDirection = isPlayer ? 'left-to-right' : 'right-to-left';

    // Start damage feedback when the projectile arrives; let its burst finish
    // alongside hit-stop/recovery instead of waiting until it has disappeared.
    const vfxId = ++damageIdRef.current;
    let vfxResolve;
    const vfxPromise = new Promise((resolve) => { vfxResolve = resolve; });
    dispatch({
      type: 'SET_VFX',
      value: {
        id: vfxId,
        vfxKey: event.vfxKey,
        element: vfxElement,
        direction: vfxDirection,
        targetSide: isPlayer ? 'left' : 'right',
        travelMs: scaleBattleDuration(profile.vfxTravelMs),
        impactMs: scaleBattleDuration(profile.vfxImpactMs),
        onImpact: vfxResolve,
        onComplete: () => {
          dispatch({ type: 'CLEAR_VFX', id: vfxId });
          vfxResolve();
        },
      },
    });
    await Promise.race([vfxPromise, battleWait(1400)]);

    // IMPACT phase
    dispatch({ type: 'SET_CONTACT_POSES', value: getBattleContactState(event, profile) });
    if (isPlayer) {
      const spriteEl = playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current;
      if (spriteEl) playerLunge(spriteEl, 'left');
    } else {
      const npcEl = npcSpriteImgRef.current;
      if (npcEl) npcLunge(npcEl, battleState.npc.flipSprite ? 'left' : 'right');
    }
    // Whip/swoosh at the contact frame (matches lunge anticipation -> strike timing)
    trackedTimeout(() => playSound('lungeContact'), scaleBattleDuration(110));

    if (hasDamagingImpact(event)) {
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
      const incomingSide = targetSide === 'left' ? 'right' : 'left';

      // Pull the target sprite element (not container) for crunchy NES-style flicker
      const targetSpriteEl = targetContainer === playerSpriteContainerRef.current
        ? (playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current)
        : npcSpriteImgRef.current;

      const targetDefending = isPlayer ? battleState.npcDefending : battleState.playerDefending;
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
        if (targetContainer) targetKnockback(targetContainer, incomingSide, 18);
      } else if (container) {
        const hpRatio = event.damage / (isPlayer ? battleState.npcMaxHp : battleState.playerMaxHp);
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
          targetKnockback(targetContainer, incomingSide, isHeavy ? 14 : 9);
        }
      }

      const hitTarget = isPlayer
        ? (event.reflected ? playerSpriteContainerRef.current : npcSpriteContainerRef.current)
        : (event.reflected ? npcSpriteContainerRef.current : playerSpriteContainerRef.current);
      if (hitTarget) hitSquash(hitTarget);
    } else if (!event.hit) {
      playSound(profile.sound);
    } else {
      playSound('shieldDeflectSting');
    }

    if (event.lifesteal > 0) {
      dispatch({ type: isPlayer ? 'APPLY_HEAL_TO_PLAYER' : 'APPLY_HEAL_TO_NPC', amount: event.lifesteal });
      dispatch({ type: 'ADD_DAMAGE_NUMBER', entry: {
        id: ++damageIdRef.current, damage: event.lifesteal, effectiveness: 1, hit: true,
        target: isPlayer ? 'player' : 'npc', variant: 'heal', label: `+${event.lifesteal}`,
      } });
      dispatch({ type: 'ADD_LOG', text: `${who} drains ${event.lifesteal} HP.` });
    }

    const dmgTarget = event.reflected ? (isPlayer ? 'player' : 'npc') : (isPlayer ? 'npc' : 'player');
    const callout = getBattleResultCallout(event);
    if (callout) {
      dispatch({ type: 'SET_BATTLE_CALLOUT', value: callout });
      trackedTimeout(() => dispatch({ type: 'CLEAR_BATTLE_CALLOUT' }), 620);
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
      const blockedText = event.blocked ? ' BLOCKED — sentinel shield holds' : '';
      const effText = event.blocked ? '' : event.effectiveness > 1 ? ' Super effective!' : event.effectiveness < 1 ? ' Resisted.' : '';
      const reflectText = event.reflected ? ' REFLECTED!' : '';
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — ${event.damage} dmg.${critText}${effText}${blockedText}${reflectText}` });
      playSound('combatMessage');
    } else {
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — missed!` });
      playSound('combatMessage');
    }
    if (event.appliedStatus) {
      dispatch({ type: 'ADD_LOG', text: `${event.appliedStatus} applied!` });
      playSound('combatMessage');
      playSound('statusApply', { element: isPlayer ? battleState.dragon.element : battleState.npc.element });
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
    await battleWait(profile.recoveryMs);

    damageStaggerRef.current = 0;

    // Contact poses have already played through hit-stop and recovery. Let
    // them settle before cleanup; do not restart recoil after the hit is over.
    await battleWait(140);

    dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_ATTACKING', value: false });
    dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });

    if (shieldRef.current) {
      shieldDismiss(shieldRef.current.element, shieldRef.current.timeline);
      shieldRef.current = null;
    }
  }, [state]);

  useEffect(() => {
    if (autoBattle && autoBattleAllowed && introDone && state.phase === PHASES.PLAYER_TURN && !animatingRef.current) {
      const playerMoveKeys = [...state.dragon.moveKeys.filter((k) => !moves[k]?.isSignature || !state.playerSignatureUsed?.[state.dragonId]), 'basic_attack'];
      const autoBattleContext = {
        playerMoveHistory: state.playerMoveHistory,
        turnCount: state.turnCount,
        playerHpRatio: state.playerHp / state.playerMaxHp,
        enemyHpRatio: state.npcHp / state.npcMaxHp,
      };
      const autoMove = pickNpcMove(playerMoveKeys, state.dragon.element, state.npc.element, state.npcStatus, autoBattleContext);
      trackedTimeout(() => handleMoveSelect(autoMove), 500);
    }
  }, [autoBattle, state.phase, introDone]);

  // A multi-phase boss with phaseLines speaks its opening line into the combat
  // log on mount (review #8 — voice the villain). Phase-transition lines fire in
  // the phase-shift handler below. Ref-guarded so StrictMode's double-invoke (or a
  // remount) can't log the opening line twice.
  const bossOpeningLoggedRef = useRef(false);
  useEffect(() => {
    if (bossOpeningLoggedRef.current) return;
    const boss = battleConfig?.boss;
    if (boss?.phaseLines?.[0]) {
      bossOpeningLoggedRef.current = true;
      dispatch({ type: 'ADD_LOG', text: `${boss.name}: ${boss.phaseLines[0]}` });
    }
  }, []); // once on mount

  const runFragmentUnlockPass = () => {
    const s = loadSave();
    Object.entries(FRAGMENT_TRIGGERS).forEach(([id, trigger]) => {
      if (trigger(s)) unlockFragment(id);
    });
  };

  const handleMoveSelect = useCallback(async (moveKey, { swap = false } = {}) => {
    if (!introDone || state.phase !== PHASES.PLAYER_TURN || animatingRef.current) return;
    if (swap && !(state.bench?.playerHp > 0)) return;
    let turnState = state;
    const currentTurn = turnState.turnCount + 1;
    const forcedSwap = turnState.bossPatternId === 'phishing_siren' &&
      [2, 5].includes(currentTurn) && turnState.bench?.playerHp > 0;
    const guardOnEntry = swap || forcedSwap;
    if (!guardOnEntry && moves[moveKey]?.isSignature && turnState.playerSignatureUsed?.[turnState.dragonId]) return;
    animatingRef.current = true;
    dispatch({ type: 'START_ANIMATION' });

    if (guardOnEntry) {
      turnState = swapActiveAndBench(turnState);
      dispatch({ type: 'SWAP_DRAGON' });
      dispatch({ type: 'ADD_LOG', text: forcedSwap
        ? `${turnState.npc.name} lures ${state.dragon.name} out — ${turnState.dragon.name} guards on entry. Command interrupted; Toxic Cloud incoming!`
        : `${state.dragon.name} swaps out — ${turnState.dragon.name} guards on entry!` });
      moveKey = 'defend';
      // Auras belong to the fighter that left, not to the arena slot.
      playerAuraRef.current?.kill();
      playerAuraRef.current = null;
      playSound('uiConfirm');
      await battleWait(500);
    }
    playSound('commandSelect', { element: moves[moveKey]?.element });
    setSelectedMoveKey(moveKey);
    playSound('commandExecute', { element: moves[moveKey]?.element });

    const relicMods = getRelicBattleModifiers(save?.skye?.relicsEquipped || []);

    // resonant_fork: cleanse BEFORE engine so status tick damage is skipped on cleanse turns
    const shouldCleanse = relicMods.autoCleanseTurns > 0 &&
      turnState.playerStatus != null &&
      (turnState.turnCount + 1) % relicMods.autoCleanseTurns === 0;

    const playerState = {
      name: turnState.dragon.name,
      element: turnState.dragon.element,
      stage: turnState.playerStage,
      hp: turnState.playerHp,
      maxHp: turnState.playerMaxHp,
      atk: turnState.playerStats.atk + relicMods.atkBonus,
      def: Math.floor(turnState.playerStats.def * relicMods.defMultiplier),
      spd: turnState.playerStats.spd + relicMods.spdBonus,
      defending: false,
      status: shouldCleanse ? null : turnState.playerStatus,
      atkBuff: turnState.playerAtkBuff,
      defBuff: turnState.playerDefBuff,
    };

    const activeGarble = getCorruptedMoveKey(turnState);

    const npcState = {
      name: turnState.npc.name,
      element: turnState.npc.element,
      stage: 3,
      hp: turnState.npcHp,
      maxHp: turnState.npcMaxHp,
      atk: turnState.npc.stats.atk,
      def: turnState.npc.stats.def,
      spd: turnState.npc.stats.spd,
      defending: false,
      status: turnState.npcStatus,
      atkBuff: turnState.npcAtkBuff,
      defBuff: turnState.npcDefBuff,
    };

    const battleContext = {
      playerMoveHistory: turnState.playerMoveHistory,
      turnCount: turnState.turnCount,
      playerHpRatio: turnState.playerHp / turnState.playerMaxHp,
      enemyHpRatio: turnState.npcHp / turnState.npcMaxHp,
      npcAtkBuff: turnState.npcAtkBuff,
      npcDefBuff: turnState.npcDefBuff,
    };

    // ---- Signature move check ----
    const npcData = npcs[turnState.npc.id] || turnState.npc;
    const sigKey = npcData.signatureMoveKey;
    const sigCondition = npcData.signatureCondition;
    const npcHpRatio = turnState.npcHp / turnState.npcMaxHp;
    const shouldFireSignature = sigKey && sigCondition &&
      !turnState.signatureMoveUsed && !turnState.npcChargedMove &&
      npcHpRatio <= sigCondition.hpThreshold;

    // ---- Charge / fire logic ----
    const desperationMode = (turnState.npcHp / turnState.npcMaxHp) < 0.30;
    let npcMoveKey;
    let previouslyCharged = false;
    let isCharging = false;
    const fuseDetonationDue = isLogicBombDetonationDue(turnState);

    if (fuseDetonationDue) {
      // The six-turn fuse takes priority over a stored charge or HP trigger.
      // Discard the old charge instead of boosting or postponing Detonation.
      npcMoveKey = 'bomb_detonation';
      if (turnState.npcChargedMove) dispatch({ type: 'CLEAR_NPC_CHARGED_MOVE' });
      dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name}'s fuse hits zero — FINAL DETONATION! Defend or finish it before it acts.` });
    } else if (turnState.npcChargedMove) {
      // Fire the stored charged move at 1.4× ATK
      npcMoveKey = turnState.npcChargedMove;
      previouslyCharged = true;
      dispatch({ type: 'CLEAR_NPC_CHARGED_MOVE' });
    } else if (shouldFireSignature) {
      npcMoveKey = sigKey;
      dispatch({ type: 'SET_SIGNATURE_USED' });
    } else {
      npcMoveKey = pickNpcMove(turnState.npc.moveKeys, turnState.npc.element, turnState.dragon.element, turnState.playerStatus, battleContext);

      // === P4 AUTHORED PATTERNS (per-boss scripts; mirror by id) ===
      const patternId = turnState.bossPatternId;
      const bs = turnState.bossState;

      // buffer_overflow: 4 heat stacks → Magma Breath is FORCED and burns the
      // user for 10% max HP. The stack counter ticks in the combat feed.
      if (patternId === 'buffer_overflow' && bs.heatStacks >= 4) {
        npcMoveKey = 'magma_breath';
        const burnDamage = Math.max(1, Math.floor(turnState.npcMaxHp * 0.1));
        npcState.hp = Math.max(0, npcState.hp - burnDamage);
        dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: burnDamage });
        dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} overheats — the heat stack burns it for ${burnDamage}!` });
        dispatch({ type: 'SET_BOSS_STATE', value: { heatStacks: 0 } });
        playSound('statusTick', { element: 'fire' });
      } else if (patternId === 'buffer_overflow') {
        const stacks = bs.heatStacks + 1;
        dispatch({ type: 'SET_BOSS_STATE', value: { heatStacks: stacks } });
        dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} heat stack ${stacks}/4 — Magma Breath forced at 4.` });
      }

      // protocol_vulture: at half HP it perches and forces Soul Drain (heals
      // 40% of damage dealt, guaranteed Blind on hit).
      if (patternId === 'protocol_vulture' && !bs.perchUsed && turnState.npcHp / turnState.npcMaxHp <= 0.5) {
        npcMoveKey = 'vulture_drain';
        dispatch({ type: 'SET_BOSS_STATE', value: { perchUsed: true } });
        dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} perches — Soul Drain is next!` });
      }

      // recursive_golem: at 3 harden stacks Tectonic Rupture is FORCED and
      // the stacks clear.
      if (patternId === 'recursive_golem' && bs.hardenStacks >= 3) {
        npcMoveKey = npcData.signatureMoveKey || 'golem_rupture';
        dispatch({ type: 'SET_BOSS_STATE', value: { hardenStacks: 0 } });
        dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name}'s harden loop ruptures!` });
      }

      // stack_overflow: after the doublers run out it crashes — skip this turn.
      if (patternId === 'stack_overflow' && bs.spdDoubleTurnsLeft === 0 && bs.crashTurnsLeft > 0) {
        npcMoveKey = 'defend';
        dispatch({ type: 'SET_BOSS_STATE', value: { crashTurnsLeft: bs.crashTurnsLeft - 1 } });
        dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} crashes — it skips the turn recovering.` });
      }

      const npcMoveData = moves[npcMoveKey];
      if (npcMoveData?.canCharge && !desperationMode && Math.random() < (npcMoveData.chargeChance ?? 0.4)) {
        isCharging = true;
        dispatch({ type: 'SET_NPC_CHARGED_MOVE', value: npcMoveKey });
      }
    }

    // Boost NPC ATK if firing a charged move. Pass the multiplier through (rather than
    // pre-multiplying atk) so the engine combines it with any active atkBuff under one
    // ceiling — otherwise charge × focus would stack multiplicatively (see effectiveAttack).
    let finalNpcState = previouslyCharged
      ? { ...npcState, chargeMultiplier: CHARGE_ATK_MULTIPLIER }
      : npcState;

    // P4 pattern-side npcState mutations:
    // stack_overflow: ×2 SPD expires at end of this turn (option-decremented).
    if (turnState.bossPatternId === 'stack_overflow' && turnState.bossState.spdDoubleTurnsLeft > 0) {
      finalNpcState = { ...finalNpcState, spd: turnState.npc.stats.spd * 2 };
    }
    // recursive_golem harden pip + bit_wraith pierce + memory_leak pips +
    // logic_bomb fuse tick read via options below.
    const bs = turnState.bossState;
    // Dual techs resolve via a move override (constructed from the pairing —
    // the moves table never sees the combo keys).
    const dualTechKey = moveKey.startsWith('dual_') ? moveKey.slice(5) : null;
    const dualTechMove = dualTechKey
      ? Object.values(DUAL_TECHS).find(t => t.key === dualTechKey)
      : null;
    const engineOptions = {
      playerGuardOnEntry: guardOnEntry,
      npcOpeningMoveKey: forcedSwap ? 'toxic_cloud' : undefined,
      playerAccuracyFloor: (turnState.npc.difficulty === 'Easy' && !(save.defeatedNpcs || []).length) ? 95 : 0,
      playerMoveOverride: dualTechMove || undefined,
      playerCorruptedMoveKey: activeGarble || undefined,
      logicBombDetonation: fuseDetonationDue,

      // firewall_sentinel packet-shield (pilot)
      packetShield: turnState.bossPatternId === 'firewall_sentinel' && moveKey !== 'defend',
      playerDefendedLastTurn: playerDefendedLastTurn.current,

      // crypto_crab: encrypted until you repeat your last element
      cryptoEncrypted: turnState.bossPatternId === 'crypto_crab' && !bs.decrypted,

      // bit_wraith: miss primes pierce → next hit ignores Defend
      bitWraithPierce: turnState.bossPatternId === 'bit_wraith' && bs.pierceNext,

      // Three successful super-effective strikes break the head lock.
      hydraFloor: turnState.bossPatternId === 'glitch_hydra' && bs.headsBroken < HYDRA_HEAD_COUNT ? HYDRA_HP_FLOOR : 0,
    };
    // memory_leak: DEF climbs one pip per turn until an ice hit resets it.
    if (turnState.bossPatternId === 'memory_leak') {
      const pips = Math.min(5, (bs.leakPips || 0) + 1);
      finalNpcState = { ...finalNpcState, def: Math.floor(finalNpcState.def * (1 + pips * 0.1)) };
      dispatch({ type: 'SET_BOSS_STATE', value: { leakPips: pips } });
      dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} leak pip ${pips}/5 — DEF +${pips * 10}%.` });
    }

    // On charge turn: NPC defends (takes the player hit while winding up)
    const effectiveNpcMoveKey = isCharging ? 'defend' : npcMoveKey;

    const availablePlayerMoves = turnState.dragon.moveKeys.filter(key =>
      !moves[key]?.isSignature || !turnState.playerSignatureUsed?.[turnState.dragonId]);
    let result = resolveTurn(playerState, finalNpcState, moveKey, effectiveNpcMoveKey,
      guardOnEntry ? ['defend'] : availablePlayerMoves, turnState.npc.moveKeys, engineOptions);
    // Spend techniques only when the actor actually executes them. A KO,
    // status skip, or forced swap cannot consume the outgoing dragon's move.
    const playerAction = result.events.find(e => e.attacker === 'player' && shouldAnimateBattleEvent(e));
    const executedMoveKey = playerAction?.moveKey || (playerAction?.action === 'defend' ? 'defend' : null);
    if (executedMoveKey) {
      dispatch({ type: 'APPEND_PLAYER_MOVE_HISTORY', moveKey: executedMoveKey });
      turnState = {
        ...turnState,
        phaseMoveHistory: [...(turnState.phaseMoveHistory || []), executedMoveKey],
      };
      if (moves[executedMoveKey]?.isSignature) dispatch({ type: 'SET_PLAYER_SIGNATURE_USED', dragonId: turnState.dragonId });
      if (executedMoveKey.startsWith('dual_')) dispatch({ type: 'SET_DUAL_TECH_USED' });
    }
    playerDefendedLastTurn.current = playerAction?.action === 'defend';

    // === Post-resolve pattern hooks ===
    const playerAttackEvent = result.events.find(e => e.attacker === 'player' && e.action === 'attack');

    if (turnState.bossPatternId === 'data_corruption') {
      if (playerAttackEvent?.corruptedMoveKey === activeGarble && activeGarble) {
        const usesLeft = Math.max(0, bs.garbledTurnsLeft - 1);
        dispatch({ type: 'SET_BOSS_STATE', value: {
          garbledTurnsLeft: usesLeft,
          garbledMoveKey: usesLeft ? activeGarble : null,
          garbledDragonId: usesLeft ? turnState.dragonId : null,
        } });
        dispatch({ type: 'ADD_LOG', text: `${moves[activeGarble].name} fires as BASIC — ${usesLeft ? `${usesLeft} corrupted use remains.` : 'the slot is clear.'}` });
      }
      // New applications and refreshes both emit Burn. DOT alone does not.
      // Rearm after resolution so the next command matches its visible signal,
      // even if a faster enemy applied Burn before this turn's player action.
      if (result.player.hp > 0 && result.npc.hp > 0 && result.events.some(event =>
        event.attacker === 'npc' && event.action === 'attack' && event.hit && !event.reflected && event.appliedStatus === 'Burn')) {
        const corruption = createCorruptionState(turnState.dragonId, turnState.dragon.moveKeys);
        dispatch({ type: 'SET_BOSS_STATE', value: corruption });
        if (corruption.garbledMoveKey) dispatch({ type: 'ADD_LOG', text: `Burn corrupts ${turnState.dragon.name}'s ${moves[corruption.garbledMoveKey].name} — BASIC for its next 2 uses.` });
      }
    }

    // crypto_crab encryption: hide type until you repeat the previous element
    // (same-element back-to-back → reveal → damage gates open).
    if (turnState.bossPatternId === 'crypto_crab' && playerAttackEvent?.hit) {
      const el = moves[playerAttackEvent.moveKey]?.element;
      if (el === bs.prevElement && !bs.decrypted) {
        dispatch({ type: 'SET_BOSS_STATE', value: { decrypted: true, prevElement: el } });
        dispatch({ type: 'ADD_LOG', text: `Encryption cracked — ${turnState.npc.name}'s type is exposed!` });
      } else if (!bs.decrypted) {
        dispatch({ type: 'SET_BOSS_STATE', value: { prevElement: el } });
        dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} reads ENCRYPTED — repeat your last element to crack it.` });
      }
    }

    // bit_wraith: any NPC miss primes a one-turn pierce (next hit ignores Defend).
    const npcAttackEvent = result.events.find(e => e.attacker === 'npc' && e.action === 'attack');
    if (turnState.bossPatternId === 'bit_wraith') {
      if (npcAttackEvent && !npcAttackEvent.hit) {
        dispatch({ type: 'SET_BOSS_STATE', value: { pierceNext: true } });
        dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} phases — its next hit ignores Defend!` });
      } else if (npcAttackEvent?.hit) {
        dispatch({ type: 'SET_BOSS_STATE', value: { pierceNext: false } });
      }
    }

    if (turnState.bossPatternId === 'glitch_hydra') {
      const headsBroken = advanceHydraHeads(bs.headsBroken, playerAttackEvent);
      if (headsBroken > bs.headsBroken) {
        dispatch({ type: 'SET_BOSS_STATE', value: { headsBroken } });
        dispatch({ type: 'ADD_LOG', text: `Head down (${headsBroken}/${HYDRA_HEAD_COUNT})${headsBroken === HYDRA_HEAD_COUNT ? ' — HP lock broken!' : ' — keep hitting its weakness.'}` });
      }
    }

    // Early HP signatures still spend a turn of the fuse. Its one guaranteed
    // detonation is consumed only by the actual action, not by selecting it.
    if (turnState.bossPatternId === 'logic_bomb') {
      if (bs.fuseTurns > 0) {
        dispatch({ type: 'SET_BOSS_STATE', value: { fuseTurns: bs.fuseTurns - 1 } });
        dispatch({ type: 'ADD_LOG', text: `Fuse ${Math.max(0, bs.fuseTurns - 1)} — Final Detonation at zero.` });
      }
      if (fuseDetonationDue && npcAttackEvent?.moveKey === 'bomb_detonation') {
        dispatch({ type: 'SET_BOSS_STATE', value: { fuseDetonated: true } });
        dispatch({ type: 'SET_SIGNATURE_USED' });
      }
    }

    // Ice clears the leak even though the boss resists ice damage.
    if (turnState.bossPatternId === 'memory_leak' && resetsMemoryLeak(playerAttackEvent)) {
      dispatch({ type: 'SET_BOSS_STATE', value: { leakPips: 0 } });
      dispatch({ type: 'ADD_LOG', text: `Ice strike resets the ${turnState.npc.name} leak — DEF climb cleared.` });
    }

    // recursive_golem: every harden move builds a stack (the forced rupture
    // at 3 is handled pre-pick). Buff actions don't produce attack events, so
    // count by NPC action type.
    if (turnState.bossPatternId === 'recursive_golem') {
      const hardenUsed = result.events.some(e => e.attacker === 'npc' && (e.action === 'buff' || e.action === 'defend'));
      if (hardenUsed && bs.hardenStacks < 3) {
        dispatch({ type: 'SET_BOSS_STATE', value: { hardenStacks: bs.hardenStacks + 1 } });
        dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} harden stack ${bs.hardenStacks + 1}/3 — rupture at 3.` });
      }
    }

    // stack_overflow: once per battle, a Thunder Clap hit arms ×2 SPD for 2t,
    // then the crash lands (skip turn).
    if (turnState.bossPatternId === 'stack_overflow' && npcAttackEvent?.hit && npcAttackEvent.moveKey === 'thunder_clap' && !bs.surgeUsed) {
      dispatch({ type: 'SET_BOSS_STATE', value: { spdDoubleTurnsLeft: 2, surgeUsed: true, crashTurnsLeft: 2 } });
      dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} surges — its speed doubles for two turns!` });
    } else if (turnState.bossPatternId === 'stack_overflow' && bs.spdDoubleTurnsLeft > 0) {
      dispatch({ type: 'SET_BOSS_STATE', value: { spdDoubleTurnsLeft: bs.spdDoubleTurnsLeft - 1 } });
    }

    // Tag signature events for presentation
    const isSignature = fuseDetonationDue || (shouldFireSignature && !previouslyCharged);
    if (isSignature) {
      result = {
        ...result,
        events: result.events.map(e =>
          e.attacker === 'npc' && e.action === 'attack' ? { ...e, isSignature: true } : e
        ),
      };
    }

    // C6: a signature firing dims the arena so the once-per-battle climax
    // reads as an event (player or NPC). Cleared when the turn settles.
    const signatureInFlight = isSignature || !!moves[moveKey]?.isSignature;
    if (signatureInFlight) setSignatureFocus(true);

    // hydra_cog: 20% chance for a follow-up hit after a successful player attack
    let chainDamage = 0;
    if (relicMods.chainHitChance > 0 && result.npc.hp > 0 && result.player.hp > 0) {
      const playerHit = result.events.find(e => e.attacker === 'player' && e.action === 'attack' && e.hit && !e.reflected && !e.blocked && e.damage > 0);
      if (playerHit && Math.random() < relicMods.chainHitChance) {
        const floorHp = Math.ceil(turnState.npcMaxHp * (engineOptions.hydraFloor || 0));
        chainDamage = Math.min(Math.max(1, Math.floor(playerHit.damage * 0.4)), Math.max(0, result.npc.hp - floorHp));
        result = { ...result, npc: { ...result.npc, hp: Math.max(0, result.npc.hp - chainDamage) } };
      }
    }

    for (const event of result.events) {
      if (shouldAnimateBattleEvent(event)) {
        await animateEvent(event, dispatch, { ...turnState, playerDefending: guardOnEntry });
      }
    }

    // Show chain hit damage number after main animation
    if (chainDamage > 0) {
      const chainId = ++damageIdRef.current;
      dispatch({ type: 'ADD_DAMAGE_NUMBER', entry: { id: chainId, damage: chainDamage, effectiveness: 1.0, hit: true, target: 'npc', isCritical: false } });
      dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: chainDamage });
      await battleWait(200);
    }

    // Charge warning log — appears after the player's attack resolves this turn
    if (isCharging) {
      const chargeMoveName = moves[npcMoveKey]?.name || 'a powerful move';
      dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} is winding up ${chargeMoveName}!` });
      playSound('combatMessage');
    }

    // Signature callout (player or NPC)
    if (isSignature || moves[moveKey]?.isSignature) {
      dispatch({ type: 'SET_BATTLE_CALLOUT', value: { text: 'SIGNATURE', variant: 'signature' } });
      trackedTimeout(() => dispatch({ type: 'CLEAR_BATTLE_CALLOUT' }), 900);
    }

    // Charged strike callout
    if (previouslyCharged) {
      dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} unleashes a CHARGED STRIKE!` });
    }

    // coolant_core: extend status duration when player applies a NEW status to the NPC
    let finalNpcStatus = result.npc.status;
    if (relicMods.statusDurationBonus > 0 && result.npc.status &&
        result.npc.status.effect !== npcState.status?.effect) {
      finalNpcStatus = { ...result.npc.status, turnsLeft: result.npc.status.turnsLeft + relicMods.statusDurationBonus };
    }

    // resonant_fork: status was cleared pre-turn via shouldCleanse; normalise to null
    const finalPlayerStatus = result.player.status || null;
    if (shouldCleanse) playSound('statusExpire', { element: turnState.dragon.element });

    result = { ...result, npc: { ...result.npc, status: finalNpcStatus }, player: { ...result.player, status: finalPlayerStatus } };

    // Sync status from engine
    dispatch({ type: 'SET_PLAYER_STATUS', value: finalPlayerStatus || null });
    dispatch({ type: 'SET_NPC_STATUS', value: finalNpcStatus || null });

    // Apply/remove status auras
    if (finalPlayerStatus && !playerAuraRef.current) {
      const spriteEl = playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current;
      if (spriteEl) {
        playerAuraRef.current = statusAuraApply(spriteEl, finalPlayerStatus.effect);
      }
    } else if (!finalPlayerStatus && playerAuraRef.current) {
      playerAuraRef.current.kill();
      playerAuraRef.current = null;
    }

    if (finalNpcStatus && !npcAuraRef.current) {
      const npcEl = npcSpriteImgRef.current || npcSpriteContainerRef.current;
      if (npcEl) {
        npcAuraRef.current = statusAuraApply(npcEl, finalNpcStatus.effect);
      }
    } else if (!finalNpcStatus && npcAuraRef.current) {
      npcAuraRef.current.kill();
      npcAuraRef.current = null;
    }

    // Process status tick events (DOT, skip)
    for (const event of result.events) {
      if (event.attacker === 'status') {
        if (event.damage > 0) {
          playSound('statusTick', { element: event.target === 'player' ? turnState.dragon.element : turnState.npc.element });
          const dmgId = ++damageIdRef.current;
          dispatch({
            type: 'ADD_DAMAGE_NUMBER',
            entry: { id: dmgId, damage: event.damage, effectiveness: 1.0, hit: true, target: event.target, isStatusTick: true, statusElement: event.target === 'player' ? turnState.playerStatus?.effect : turnState.npcStatus?.effect },
          });
          if (event.target === 'player') {
            dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
          } else {
            dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
          }
          await battleWait(400);
        }
        if (event.expired) {
          playSound('statusExpire', { element: event.target === 'player' ? turnState.dragon.element : turnState.npc.element });
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
        await battleWait(300);
      }
    }

    dispatch({ type: 'SYNC_BATTLE_RESULT', result });
    const finalPlayerHpPercent = result.player.hp / turnState.playerMaxHp * 100;
    turnState = {
      ...turnState,
      maxDamageDealt: Math.max(turnState.maxDamageDealt, ...result.events
        .filter(e => e.attacker === 'player' && e.action === 'attack' && e.hit && !e.reflected)
        .map(e => e.damage)),
    };

    const settlePlayerFaint = async (advanceTurn = true) => {
      playSound('ko');

      // mirror_admin_reset (Great Reset): if the player faints in Phase 3
      // without having spent Restoration or Recompile THIS PHASE, Mirror
      // Admin heals 25% max HP. Checked before the bench swap so the punish
      // lands on the phase where the dragon actually fell.
      if (result.npc.hp > 0 && battleConfig?.isMirrorAdmin && (turnState.currentPhase || 0) === 2) {
        const healMovesThisPhase = (turnState.phaseMoveHistory || []).filter(k => ['restoration', 'recompile'].includes(k));
        if (healMovesThisPhase.length === 0 && !turnState.bossState.mirrorHealPunished) {
          const healAmount = Math.min(turnState.npcMaxHp - result.npc.hp, Math.max(1, Math.floor(turnState.npcMaxHp * 0.25)));
          result = { ...result, npc: { ...result.npc, hp: Math.min(turnState.npcMaxHp, result.npc.hp + healAmount) } };
          dispatch({ type: 'SYNC_BATTLE_RESULT', result });
          dispatch({ type: 'SET_BOSS_STATE', value: { mirrorHealPunished: true } });
          dispatch({ type: 'ADD_LOG', text: `${turnState.npc.name} triggers the Great Reset — heals ${healAmount} HP!` });
          playSound('statusTick', { element: 'shadow' });
        }
      }

      const playerCanvas = playerSpriteRef.current?.getCanvas?.();
      if (playerCanvas) {
        await new Promise(resolve => {
          const tl = shatterKO(playerCanvas, turnState.dragon.element);
          tl.eventCallback('onComplete', resolve);
          setTimeout(resolve, 1200);
        });
      } else {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-ko' });
        await battleWait(600);
      }
      if (turnState.bench && turnState.bench.playerHp > 0) {
        // Reserve dragon steps in — the bench is a second life; fight continues.
        dispatch({ type: 'ADD_LOG', text: `${turnState.dragon.name} fell — ${turnState.bench.dragon.name} steps in!` });
        dispatch({ type: 'FAINT_SWAP', advanceTurn });
        playSound('uiConfirm');
        // Every fight re-opens on its own calm track (remnants included —
        // previously their theme was stomped by the generic battle loop).
        playMusic(baseTrack);
      } else {
        trackStat('battlesLost');
        updateRecords({ turns: turnState.turnCount + 1, maxDamage: turnState.maxDamageDealt, won: false });
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-defeated' });
        dispatch({ type: 'SET_DEFEAT' });
        stopMusic();
        stopHeartbeat();
        playSound('defeatDrone');
      }
    };

    if (result.npc.hp <= 0) {
      const phases = battleConfig?.phases;
      const currentPhaseIndex = turnState.currentPhase || 0;

      if (phases && currentPhaseIndex < phases.length - 1) {
        // Phase shift — boss transforms
        const nextPhase = phases[currentPhaseIndex + 1];
        playSound('ko');
        const phaseNpcEl = npcSpriteImgRef.current;
        if (phaseNpcEl) {
          await new Promise(resolve => {
            const tl = shatterKO(phaseNpcEl, turnState.npc.element);
            tl.eventCallback('onComplete', resolve);
            setTimeout(resolve, 1200);
          });
        } else {
          dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
          await battleWait(600);
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
            // Bespoke per-phase art (e.g. The Singularity ignition->surge->void); fall back to the current sprite.
            ...(nextPhase.idleSprite ? { idleSprite: nextPhase.idleSprite, attackSprite: nextPhase.attackSprite || nextPhase.idleSprite } : {}),
          },
        });
        const nextLine = battleConfig?.boss?.phaseLines?.[currentPhaseIndex + 1];
        if (nextLine) {
          dispatch({ type: 'ADD_LOG', text: `${battleConfig.boss.name}: ${nextLine}` });
        }
        await battleWait(1000);
        // A double KO advances the boss, then brings in the reserve (or ends
        // the battle). The phase shift already counted this turn.
        if (result.player.hp <= 0) await settlePlayerFaint(false);
      } else {
        // True victory
        let xpGained = calculateXpGain(turnState.npc.baseXP || 50, turnState.playerLevel, turnState.npc.level);
        if (save.inventory?.xpBoostBattles > 0) {
          xpGained *= 3;
          decrementXpBoost();
        }
        // astraeus_engine: +15% XP from all battles
        if (relicMods.xpMultiplier !== 1.0) {
          xpGained = Math.floor(xpGained * relicMods.xpMultiplier);
        }
        const isRepeatDefeat = !battleConfig?.isSingularity && !battleConfig?.dailyNpc &&
          (save.defeatedNpcs || []).includes(npcId);
        // Singularity/remnant/boss repeat penalty: first clear pays full, every
        // subsequent clear pays ×0.25 — matching the normal-NPC repeat penalty.
        // `save` is the pre-battle snapshot, so a true first clear reads as not-yet-defeated.
        const sp = save.singularityProgress || {};
        const isSingularityRepeat = battleConfig?.isSingularity && (
          battleConfig?.isRemnant
            ? (save.remnantDefeated || []).includes(battleConfig.remnantId)
            : battleConfig?.isMirrorAdmin
              ? save.mirrorAdminDefeated === true
              : npcId === 'the_singularity'
                ? (save.singularityComplete === true || (sp.replayCounts?.[npcId] || 0) > 0)
                : ((sp.defeated || []).includes(npcId) || (sp.replayCounts?.[npcId] || 0) > 0)
        );
        const rawScraps = turnState.npc.scrapsReward || 0;
        const isSharedSeed = !!battleConfig?.dailyNpc?.shared;
        let scrapsGained;
        // Captured before completeDailyChallenge mutates the streak — the
        // overlay must show the multiplier that was actually applied.
        let streakMultiplier = 1.0;
        if (isRepeatDefeat || isSingularityRepeat) {
          scrapsGained = Math.max(12, Math.floor(rawScraps * 0.45));
        } else if (battleConfig?.dailyNpc && !isSharedSeed) {
          streakMultiplier = getDailyStreakMultiplier(save);
          scrapsGained = Math.floor(rawScraps * streakMultiplier);
        } else {
          scrapsGained = rawScraps;
        }
        // New Game+ reward bonus: +25% XP & scraps per tier so re-runs pay off.
        if (save.ngPlus) {
          xpGained = Math.floor(xpGained * (1 + save.ngPlus * 0.25));
          scrapsGained = Math.floor(scrapsGained * (1 + save.ngPlus * 0.25));
        }
        addDragonXp(turnState.dragonId, xpGained); // canonical XP curve (persistence.js) — no source-specific leveling
        if (turnState.bench?.dragonId) addDragonXp(turnState.bench.dragonId, Math.max(1, Math.floor(xpGained / 2))); // reserve trains at half rate
        const newLevel = loadSave().dragons[turnState.dragonId].level;
        const leveledUp = newLevel > turnState.playerLevel;
        if (scrapsGained > 0) addScraps(scrapsGained);

        if (battleConfig?.isMirrorAdmin) {
          markMirrorAdminDefeated();
        } else if (battleConfig?.isSingularity) {
          const fragIds = battleConfig.boss?.fragmentIds || [];
          if (phases) {
            markSingularityComplete();
            fragIds.forEach(id => unlockFragment(id));
          } else {
            recordSingularityDefeat(npcId);
            fragIds.forEach(id => unlockFragment(id));
          }
        } else {
          recordNpcDefeat(npcId);
          if (battleConfig?.dailyNpc && !isSharedSeed) {
            completeDailyChallenge(battleConfig.dailyNpc.seed);
          }
        }
        refreshSave();

        // Core drops
        let coreDropped = null;
        const npcElement = turnState.npc.element;
        if (Math.random() < CORE_DROP_CHANCE) {
          const coreCount = Math.random() < CORE_DOUBLE_CHANCE ? 2 : 1;
          addCore(npcElement, coreCount);
          coreDropped = { element: npcElement, count: coreCount };
        }

        // Relic drops — first defeat of specific NPCs only
        const relicDropId = RELIC_DROPS[npcId];
        let relicDropped = null;
        if (relicDropId) {
          const alreadyOwned = (loadSave()?.skye?.relicsOwned || []).includes(relicDropId);
          if (!alreadyOwned) {
            grantRelic(relicDropId);
            incrementBountiesCleared();
            relicDropped = relicDropId;
          }
        }

        playSound('ko');
        const victoryNpcEl = npcSpriteImgRef.current;
        if (victoryNpcEl) {
          await new Promise(resolve => {
            const tl = shatterKO(victoryNpcEl, turnState.npc.element);
            tl.eventCallback('onComplete', resolve);
            setTimeout(resolve, 1200);
          });
        } else {
          dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
          await battleWait(600);
        }

        if (battleConfig?.isMirrorAdmin && phases) {
          trackStat('battlesWon');
          if (scrapsGained > 0) trackStat('totalScrapsEarned', scrapsGained);
          updateRecords({ turns: turnState.turnCount + 1, maxDamage: turnState.maxDamageDealt, won: true });
          runFragmentUnlockPass();
          dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-celebrate' });
          dispatch({ type: 'SET_EPILOGUE', xpGained, scrapsGained, isMirrorAdmin: true });
          stopMusic();
          stopHeartbeat();
          playSound('victoryFanfare');
        } else if (battleConfig?.isSingularity && phases && !save.singularityComplete) {
          trackStat('battlesWon');
          if (scrapsGained > 0) trackStat('totalScrapsEarned', scrapsGained);
          updateRecords({ turns: turnState.turnCount + 1, maxDamage: turnState.maxDamageDealt, won: true });
          runFragmentUnlockPass();
          dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-celebrate' });
          dispatch({ type: 'SET_EPILOGUE', xpGained, scrapsGained });
          stopMusic();
          stopHeartbeat();
          playSound('victoryFanfare');
        } else {
          trackStat('battlesWon');
          if (scrapsGained > 0) trackStat('totalScrapsEarned', scrapsGained);
          updateRecords({ turns: turnState.turnCount + 1, maxDamage: turnState.maxDamageDealt, won: true });
          runFragmentUnlockPass();
          setLastZone(turnState.npc.zone ?? null);
          dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-celebrate' });
          // Skill pay: S/A/B ranks pay a flat bonus on top of the battle payout.
          const finalRank = getBattleRank(turnState.turnCount + 1, turnState.maxDamageDealt, finalPlayerHpPercent);
          const rankBonus = getRankBonusScraps(finalRank);
          if (rankBonus > 0) addScraps(rankBonus);
          // B8: persist the best rank per opponent — drives S-rank ribbons on
          // the campaign map and the rank-perfect endgame milestone.
          recordBattleRank(npcId, finalRank);
          // Stage-up detection: did this battle's XP push the dragon across a
          // stage threshold (II@8 / III@20 / IV@38)? That's a visual evolution —
          // it deserves a callout, not silence.
          const preBattleStage = getStageForLevel(turnState.playerLevel);
          const postBattleStage = getStageForLevel(newLevel);
          const stageEvolved = postBattleStage > preBattleStage ? postBattleStage : null;
          dispatch({ type: 'SET_VICTORY', xpGained, leveledUp, newLevel, scrapsGained, coreDropped, streakMultiplier, relicDropped, wasRepeat: isRepeatDefeat || isSingularityRepeat, rankBonus, stageEvolved });
          stopMusic();
          stopHeartbeat();
          playSound('victoryFanfare');
          playSound('xpGain');
          if (scrapsGained > 0) trackedTimeout(() => playSound('scrapsEarned'), 200);
          if (leveledUp) trackedTimeout(() => playSound('levelUp'), 400);
          if (stageEvolved) trackedTimeout(() => playSound('levelUp'), 800);
        }
      }
    } else if (result.player.hp <= 0) {
      await settlePlayerFaint();
    } else {
      const playerHpPct = result.player.hp / (result.player.maxHp || turnState.playerMaxHp);
      const npcHpPct = result.npc.hp / (result.npc.maxHp || turnState.npcMaxHp);
      // Intensity ramp: standard fights open calm, tense below 50%, critical
      // below 25% (battleA -> battleB -> battleElite, the P2 battleB split).
      // Boss/Singularity/Remnant/Mirror fights keep their own entry track —
      // the generic battle loops must not stomp them.
      if (!battleConfig?.isSingularity && !battleConfig?.isMirrorAdmin && !battleConfig?.isRemnant && !battleConfig?.boss) {
        if (playerHpPct < 0.25 || npcHpPct < 0.25) {
          playMusic('battleIntense');
        } else if (playerHpPct < 0.5 || npcHpPct < 0.5) {
          playMusic('battleTense');
        } else {
          playMusic('battle');
        }
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
    setSignatureFocus(false);
  }, [state, animateEvent, save, introDone]);

  // Entry guards, enemy scripts, damage, and KO/rewards all use the same turn.
  const handleSwap = useCallback(() => handleMoveSelect('defend', { swap: true }), [handleMoveSelect]);

  const dragon = state.dragon;
  const npc = state.npc;
  // Dual techs: when the bench element pairs with the active's, the once-per-
  // battle combo move unlocks (sorted key so order doesn't matter).
  const dualTech = state.bench?.playerHp > 0
    ? resolveDualTech(dragon.element, state.bench.dragon.element)
    : null;
  const dualTechUsedUp = !!state.dualTechUsed;
  const corruptedMoveKey = getCorruptedMoveKey(state);
  const playerMoves = [
    ...dragon.moveKeys.map((k) => k === corruptedMoveKey
      ? { key: k, ...moves.basic_attack, name: moves[k].name, corrupted: true }
      : { key: k, ...moves[k] }),
    { key: 'basic_attack', ...moves.basic_attack },
  ];
  if (dualTech && !dualTechUsedUp) {
    playerMoves.push({
      key: `dual_${dualTech.key}`,
      name: dualTech.name,
      element: dualTech.element,
      power: dualTech.power,
      accuracy: dualTech.accuracy,
      vfxKey: dualTech.vfxKey,
      isDualTech: true,
    });
  }
  const playerColor = elementColors[dragon.element];
  const npcColor = elementColors[npc.element];
  const playerHpState = getHpState(state.playerHp, state.playerMaxHp);
  const npcHpState = getHpState(state.npcHp, state.npcMaxHp);
  const playerHpPercent = Math.max(0, Math.min(100, (state.playerHp / state.playerMaxHp) * 100));
  const npcHpPercent = Math.max(0, Math.min(100, (state.npcHp / state.npcMaxHp) * 100));
  const isResolvingTurn = state.phase !== PHASES.PLAYER_TURN || !introDone;
  const commands = getBattleCommands({
    moves: playerMoves,
    signatureUsed: state.playerSignatureUsed?.[state.dragonId],
    hasBench: Boolean(state.bench), benchHp: state.bench?.playerHp,
    isResolving: isResolvingTurn, autoBattleAllowed,
  });
  const commandDisabled = id => commands.find(command => command.id === id)?.disabled ?? true;
  const defeatAdvice = state.phase === PHASES.DEFEAT ? getDefeatAdvice(state, battleConfig) : null;
  const battleCues = getBattleCues(state, { playerDefendedLastTurn: playerDefendedLastTurn.current, isMirrorAdmin: battleConfig?.isMirrorAdmin });
  const battleEdge = getBattleEdge(playerHpPercent, npcHpPercent, playerHpState, npcHpState);
  const battleRank = getBattleRank(state.turnCount + 1, state.maxDamageDealt, playerHpPercent);
  // P1 battle-set poses: derived from live sprite classes so shipped sheets
  // animate (idle/attack/hurt/faint) while portraits render unchanged.
  const playerPose = resolveBattlePose({ spriteClass: state.playerSpriteClass, fainted: state.playerHp <= 0 });
  const npcPose = resolveBattlePose({ spriteClass: state.npcSpriteClass, isAttacking: state.npcAttacking, fainted: state.npcHp <= 0 });
  // P1.1 arena registry: identical rendering today; flags expose placeholder
  // and content-filter debt to tests and debug attributes.
  const battleArena = resolveBattleArena({ arena: npc.arena, arenaFilter: state.npc.arenaFilter });

  useEffect(() => {
    if (!isResolvingTurn && commandDisabled(controllerFocusId)) {
      setControllerFocusId(cycleBattleCommand(commands, controllerFocusId, 1));
    }
  }, [commands, controllerFocusId, isResolvingTurn]);

  function focusCommand(id) {
    if (!id) return;
    setControllerFocusId(id);
    // Synchronize the browser focus ring with arrows/gamepad so Enter and Space
    // always activate the command the player actually sees selected.
    const buttons = battleContainerRef.current?.querySelectorAll('[data-battle-command]');
    Array.from(buttons || []).find(button => button.dataset.battleCommand === id)?.focus({ preventScroll: true });
  }

  function cycleCommand(direction) {
    playSound('uiHover');
    focusCommand(cycleBattleCommand(commands, controllerFocusId, direction));
  }

  function retryBattle() {
    if (state.phase !== PHASES.DEFEAT || !onRetryBattle || retryStartedRef.current) return;
    retryStartedRef.current = true;
    onRetryBattle();
  }

  function leaveDefeat() {
    if (retryStartedRef.current) return;
    retryStartedRef.current = true;
    onBattleEnd(false);
  }

  useGamepadController({
    onDirectionPress: (direction) => {
      if (isResolvingTurn) return;
      if (direction === 'LEFT' || direction === 'UP') {
        cycleCommand(-1);
      }
      if (direction === 'RIGHT' || direction === 'DOWN') {
        cycleCommand(1);
      }
    },
    onButtonPress: (button) => {
      if ([PHASES.VICTORY, PHASES.DEFEAT, PHASES.EPILOGUE].includes(state.phase)) {
        if (state.phase === PHASES.DEFEAT && onRetryBattle) {
          if (button === 'A' || button === 'START') retryBattle();
          if (button === 'B') leaveDefeat();
        } else if (button === 'A' || button === 'START') onBattleEnd(state.phase !== PHASES.DEFEAT);
        return;
      }
      if (button === 'Y') {
        activateCommand('auto');
        if (autoBattleAllowed) focusCommand('auto');
        return;
      }
      if (isResolvingTurn) return;
      if (button === 'B') {
        focusCommand('defend');
        activateCommand('defend');
        return;
      }
      if (button === 'A' || button === 'START') {
        activateCommand(controllerFocusId);
      }
    },
  });

  function activateCommand(id) {
    if (commandDisabled(id)) return;
    if (id === 'defend') {
      handleMoveSelect('defend');
    } else if (id === 'swap') {
      handleSwap();
    } else if (id === 'speed') {
      toggleSpeed();
    } else if (id === 'auto') {
      playSound('uiConfirm');
      setAutoBattle((enabled) => !enabled);
    } else {
      handleMoveSelect(id);
    }
  }

  // C6: keyboard parity with the gamepad — arrows cycle the command row,
  // Enter/Space executes, D defends, S toggles speed, A toggles auto.
  useEffect(() => {
    const handler = (e) => {
      if ([PHASES.VICTORY, PHASES.DEFEAT, PHASES.EPILOGUE].includes(state.phase)) return;
      const intent = getBattleKeyboardCommand(e);
      if (!intent) return;
      if (intent.type === 'cycle') {
        if (isResolvingTurn) return;
        e.preventDefault();
        cycleCommand(intent.direction);
      } else {
        const id = intent.id || controllerFocusId;
        if (commandDisabled(id)) return;
        e.preventDefault();
        activateCommand(id);
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [controllerFocusId, isResolvingTurn, commands]);

  return (
    <div
      ref={battleContainerRef}
      className={`battle-screen ${isResolvingTurn ? 'resolving' : 'awaiting'} player-${playerHpState} npc-${npcHpState} ${signatureFocus ? 'signature-focus' : ''}`}
      data-player-pose={playerPose}
      data-npc-pose={npcPose}
      style={{
        position: 'relative', width: '100%', height: '100%', overflow: 'hidden',
        '--arena-npc-glow': npcColor.glow,
        '--arena-npc-primary': npcColor.primary,
        '--arena-player-glow': playerColor.glow,
      }}
    >
      {/* Arena background */}
      <div
        className="arena"
        data-arena-placeholder={battleArena.placeholder}
        data-arena-content-filter={battleArena.contentFilter}
        style={{ backgroundImage: `url(${battleArena.src})`, filter: battleArena.filter }}
      />
      <div className="arena-overlay" aria-hidden="true" />
      <div className="signature-dim" aria-hidden="true" />

      {/* C5: battle entrance — VS sweep, nameplate stamps, READY beat */}
      {!introDone && (
        <div className="battle-intro">
          <div className="battle-intro-nameplate left">
            <strong>{dragon.name}</strong>
          </div>
          <div className="battle-intro-nameplate right">
            <strong>{npc.name}</strong>
          </div>
          <div className="battle-intro-vs">VS</div>
          <div className="battle-intro-ready">READY</div>
        </div>
      )}
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
          {state.npcAtkBuff && (
            <div className="status-indicator buff-atk">
              ⬆ ATK UP {state.npcAtkBuff.turnsLeft}t
            </div>
          )}
          {state.npcDefBuff && (
            <div className="status-indicator buff-def">
              🛡 DEF UP {state.npcDefBuff.turnsLeft}t
            </div>
          )}
        </div>

        <div className="turn-chip">
          <span>{isResolvingTurn ? 'RESOLVING' : 'PLAYER TURN'}</span>
          <strong>TURN {state.turnCount + 1}</strong>
          <small>ENEMY: {getMoveProfileText(npc.moveKeys)}</small>
          <BattleCues cues={battleCues} />
        </div>

        <div
          className={`hp-bar-container combatant-card player ${playerHpState}`}
          style={{ '--combatant-color': playerColor.primary, '--combatant-glow': playerColor.glow }}
        >
          <div className="hp-bar-label" style={{ color: playerColor.glow }}>
            <span style={{ color: '#888' }}>Lv.{state.playerLevel}</span> {playerColor.icon} {save.dragons[state.dragonId]?.nickname || dragon.name}
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
            battlePlayback
            ref={npcSpriteImgRef}
            idleSprite={npc.idleSprite}
            attackSprite={npc.attackSprite}
            isAttacking={state.npcAttacking}
            className={state.npcSpriteClass}
            flipX={npc.flipSprite}
            smooth={battleConfig?.boss?.bespokeArt}
            style={{ filter: state.npc.spriteFilter || 'none' }}
            actorId={npc.id || null}
            pose={npcPose}
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
            <strong>{save.dragons[state.dragonId]?.nickname || dragon.name}</strong>
          </div>
          <DragonSprite
            battlePlayback
            ref={playerSpriteRef}
            spriteSheet={dragon.stageSprites?.[state.playerStage] || dragon.spriteSheet}
            stage={state.playerStage}
            flipX={!dragon.facesLeft}
            forcedFrame={state.playerForcedFrame}
            className={state.playerSpriteClass}
            element={dragon.element}
            actorId={state.dragonId}
            pose={playerPose}
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
            key={state.vfxActive.id}
            vfxKey={state.vfxActive.vfxKey}
            element={state.vfxActive.element}
            direction={state.vfxActive.direction}
            targetSide={state.vfxActive.targetSide}
            travelMs={state.vfxActive.travelMs}
            impactMs={state.vfxActive.impactMs}
            onImpact={state.vfxActive.onImpact}
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
          {playerMoves.map((move) => {
            const moveColor = elementColors[move.element] || elementColors.neutral;
            const isResolving = isResolvingTurn;
            const isSelected = selectedMoveKey === move.key;
            const matchup = getTypeEffectivenessLabel(move.element, npc.element);
            const statusSummary = getStatusMoveSummary(move);
            const signatureSummary = getSignatureSummary(move);
            const signatureSpent = !!(move.isSignature && state.playerSignatureUsed?.[state.dragonId]);
            const isDualTechBtn = !!move.isDualTech;
            return (
              <button
                key={move.key}
                className={`move-btn ${isSelected ? 'selected' : ''} ${controllerFocusId === move.key ? 'controller-focus' : ''} ${isResolving && !isSelected ? 'dimmed' : ''} ${matchup.toLowerCase()} ${move.isSignature ? 'signature' : ''} ${isDualTechBtn ? 'dual-tech' : ''}`}
                data-battle-command={move.key}
                onFocus={() => setControllerFocusId(move.key)}
                style={{ '--move-color': moveColor.primary, '--move-glow': moveColor.glow, borderColor: moveColor.primary, color: moveColor.glow, opacity: signatureSpent ? 0.45 : 1 }}
                disabled={commandDisabled(move.key)}
                title={isDualTechBtn ? `DUAL TECH — ${state.bench.dragon.name} pairs ${dualTech.move1}+${dualTech.move2}` : signatureSpent ? 'Signature already spent this battle' : signatureSummary ? `SIGNATURE — ${signatureSummary.title}` : ''}
                onClick={() => handleMoveSelect(move.key)}
              >
                <span className="tooltip">
                  {move.corrupted ? 'BASIC ATTACK | ' : ''}PWR:{move.power} ACC:{move.accuracy}%{statusSummary ? ` | ${statusSummary.title}: ${statusSummary.summary}, ${statusSummary.duration}` : ''}{signatureSummary ? ` | ${signatureSummary.title}` : ''}
                </span>
                <strong>{move.name.toUpperCase()}</strong>
                <span className="move-meta">
                  {move.corrupted && <i>CORRUPTED · {state.bossState.garbledTurnsLeft} {state.bossState.garbledTurnsLeft === 1 ? 'USE' : 'USES'}</i>}
                  <i>{moveColor.icon} {move.element.toUpperCase()}</i>
                  <i>{move.power > 0 ? `PWR ${move.power} · ACC ${move.accuracy}%` : signatureSummary?.title || 'SUPPORT'}</i>
                  <i>{isDualTechBtn ? 'DUAL' : move.isSignature ? (signatureSpent ? 'SPENT' : (signatureSummary?.label || 'SIG')) : matchup}</i>
                  {statusSummary && <i>{statusSummary.label}</i>}
                </span>
              </button>
            );
          })}
          <button
            className={`move-btn ${selectedMoveKey === 'defend' ? 'selected' : ''} ${controllerFocusId === 'defend' ? 'controller-focus' : ''} ${state.phase !== PHASES.PLAYER_TURN && selectedMoveKey !== 'defend' ? 'dimmed' : ''}`}
            data-battle-command="defend"
            onFocus={() => setControllerFocusId('defend')}
            style={{ '--move-color': '#44aa44', '--move-glow': '#66cc66', borderColor: '#44aa44', color: '#66cc66' }}
            disabled={commandDisabled('defend')}
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
          {state.bench && (
            <button
              className={`move-btn swap ${state.bench.playerHp <= 0 ? 'disabled' : ''} ${controllerFocusId === 'swap' ? 'controller-focus' : ''}`}
              data-battle-command="swap"
              onFocus={() => setControllerFocusId('swap')}
              style={{ '--move-color': '#44aaff', '--move-glow': '#66ccff', borderColor: '#44aaff', color: state.bench.playerHp > 0 ? '#66ccff' : '#555', opacity: state.bench.playerHp > 0 ? 1 : 0.5 }}
              disabled={commandDisabled('swap')}
              onClick={handleSwap}
            >
              <span className="tooltip">Swap in {state.bench.dragon.name} — guards the entry hit, then gains an opening next turn</span>
              <strong>SWAP</strong>
              <span className="move-meta">
                <i>{state.bench.dragon.name}</i>
                <i>HP {state.bench.playerHp}/{state.bench.playerMaxHp}</i>
              </span>
            </button>
          )}
          <button
            className={`move-btn speed ${speed === 2 ? 'selected' : ''} ${controllerFocusId === 'speed' ? 'controller-focus' : ''}`}
            data-battle-command="speed"
            onFocus={() => setControllerFocusId('speed')}
            style={{ '--move-color': speed === 2 ? '#ffcc00' : '#666', '--move-glow': speed === 2 ? '#ffcc00' : '#888', borderColor: speed === 2 ? '#ffcc00' : '#666', color: speed === 2 ? '#ffcc00' : '#888' }}
            onClick={toggleSpeed}
            title="Toggle battle animation speed"
          >
            <strong>{speed === 2 ? '2× SPEED' : '1× SPEED'}</strong>
            <span className="move-meta">
              <i>TEMPO</i>
              <i>{speed === 2 ? 'FAST' : 'NORMAL'}</i>
            </span>
          </button>
          <button
            className={`move-btn auto ${autoBattle ? 'selected' : ''} ${!autoBattleAllowed ? 'disabled' : ''} ${controllerFocusId === 'auto' ? 'controller-focus' : ''}`}
            data-battle-command="auto"
            onFocus={() => setControllerFocusId('auto')}
            style={autoBattleAllowed
              ? { '--move-color': autoBattle ? '#44cc44' : '#666', '--move-glow': autoBattle ? '#44cc44' : '#888', borderColor: autoBattle ? '#44cc44' : '#666', color: autoBattle ? '#44cc44' : '#888' }
              : { '--move-color': '#555', '--move-glow': '#555', borderColor: '#444', color: '#666', opacity: 0.55, cursor: 'not-allowed' }}
            onClick={() => { if (autoBattleAllowed) setAutoBattle(!autoBattle); }}
            disabled={!autoBattleAllowed}
            title={autoBattleAllowed ? '' : 'AUTO is disabled for boss and challenge fights'}
          >
            <strong>{!autoBattleAllowed ? 'AUTO: LOCKED' : autoBattle ? 'AUTO: ON' : 'AUTO: OFF'}</strong>
            <span className="move-meta">
              <i>AI LOOP</i>
              <i>{!autoBattleAllowed ? 'BOSS' : autoBattle ? 'ARMED' : 'MANUAL'}</i>
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
            {state.rankBonus > 0 && (
              <div style={{ fontSize: 9, color: '#ffcc00', letterSpacing: '0.04em' }}>
                RANK BONUS +{state.rankBonus} ◆
              </div>
            )}
            {state.stageEvolved && (
              <div className="stage-up-display">
                <div className="stage-up-kicker">EVOLUTION</div>
                <div className="stage-up-body">
                  {dragon.name} reached <strong>STAGE {['I', 'II', 'III', 'IV'][state.stageEvolved - 1]}</strong>
                </div>
                <div className="stage-up-sub">New form unlocked — damage multiplier increased</div>
              </div>
            )}
            <div className="result-summary-grid">
              <div>
                <span>XP</span>
                <strong>+{state.xpGained}</strong>
              </div>
              <div>
                <span>SCRAPS</span>
                <strong>{state.scrapsGained > 0 ? `+${state.scrapsGained}` : '0'}</strong>
                {state.wasRepeat && (
                  <em style={{ display: 'block', fontSize: 9, color: '#cc8844', fontStyle: 'normal', letterSpacing: '0.04em' }}>REPEAT ×0.45</em>
                )}
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
          {state.relicDropped && (() => {
            const r = getRelic(state.relicDropped);
            return (
              <div className="relic-drop-display">
                <span>{r?.icon}</span> ANALOG RELIC: {r?.name}
              </div>
            );
          })()}
          {battleConfig?.dailyNpc && state.streakMultiplier > 1 && (
            <div style={{ color: '#ff6600', fontSize: 12, marginTop: 6 }}>
              🔥 Streak bonus ×{state.streakMultiplier.toFixed(1)} applied
            </div>
          )}
          {battleConfig?.dailyNpc?.shared && (
            <div style={{ color: '#44aaff', fontSize: 9, marginTop: 6 }}>
              SEED BATTLE — streak unaffected
            </div>
          )}
            <button
              className="result-btn"
              onClick={() => onBattleEnd(true)}
              autoFocus
              onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onBattleEnd(true); } }}
            >
              CONTINUE
            </button>
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
            {defeatAdvice && <div className="defeat-advice">
              <strong>{defeatAdvice.title}</strong>
              <p>{defeatAdvice.detail}</p>
            </div>}
            <p style={{ fontSize: 11, color: '#888', marginTop: 4 }}>
              {battleConfig?.dailyNpc
                ? 'Change Setup returns to Battle Select to choose another guardian. Retry Battle keeps this challenge.'
                : getExpedition(battleConfig?.returnScreen)
                  ? 'Change Setup returns you to this room. Your route progress is safe.'
                : (battleConfig?.isSingularity || battleConfig?.isMirrorAdmin)
                  ? 'Change Setup returns to the Singularity breach to prepare another guardian.'
                  : battleConfig?.campaignNodeId
                    ? 'Change Setup returns to the Campaign Map to prepare another guardian.'
                    : 'Change Setup returns to Battle Select to choose your guardian and opponent.'}
            </p>
            <div className="result-actions">
              {onRetryBattle && <button className="result-btn" onClick={retryBattle} autoFocus>
                RETRY BATTLE
              </button>}
              <button className={`result-btn ${onRetryBattle ? 'secondary' : ''}`}
                onClick={leaveDefeat} autoFocus={!onRetryBattle}>
                CHANGE SETUP
              </button>
            </div>
            {onRetryBattle && <p className="result-controls">Same encounter · full party HP<br />Controller A/Start: retry · B: change setup</p>}
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
            {(state.isMirrorAdmin ? MIRROR_ADMIN_EPILOGUE_LINES : EPILOGUE_LINES).map((line, i) => (
              <div key={i}>"{line}"</div>
            ))}
          </div>
          <div className="epilogue-rewards">
            <div style={{ color: '#44aaff' }}>+{state.xpGained} XP</div>
            {state.scrapsGained > 0 && <div style={{ color: '#ffcc00' }}>+{state.scrapsGained} ◆</div>}
          </div>
          <button className="epilogue-btn" autoFocus onClick={() => onBattleEnd(true)}>
            RETURN TO THE FORGE
          </button>
        </div>
      )}
    </div>
  );
}
