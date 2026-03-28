import { useReducer, useCallback, useEffect, useRef } from 'react';
import { wait } from './utils';
import { playSound, playMusic, stopMusic } from './soundEngine';
import { dragons, npcs, moves, elementColors, STATUS_EFFECTS } from './gameData';
import {
  resolveTurn, pickNpcMove, calculateStatsForLevel,
  getStageForLevel, calculateXpGain,
} from './battleEngine';
import { loadSave, saveDragonProgress, addScraps, recordNpcDefeat, recordSingularityDefeat, markSingularityComplete, addCore, decrementXpBoost, trackStat, completeDailyChallenge, updateRecords } from './persistence';
import { CORE_DROP_CHANCE, CORE_DOUBLE_CHANCE } from './shopItems';
import { EPILOGUE_LINES } from './singularityBosses';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';
import DamageNumber from './DamageNumber';
import VfxOverlay from './VfxOverlay';

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

  const animateEvent = useCallback(async (event, dispatch) => {
    const isPlayer = event.attacker === 'player';
    const who = isPlayer ? 'You' : event.moveName ? 'Enemy' : 'Status';

    if (event.action === 'defend') {
      dispatch({ type: 'ADD_LOG', text: `${who} defended.` });
      playSound('defend');
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
        await wait(400);
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      }
      return;
    }

    if (event.action === 'reflect') {
      dispatch({ type: 'ADD_LOG', text: `${who} used Null Reflect!` });
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

    // TELEGRAPH phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-telegraph' });
    }
    playSound('attackLaunch');
    await wait(400);

    // VFX TRAVEL + IMPACT phase
    const move = moves[event.moveKey] || moves.basic_attack;
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
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_NPC_ATTACKING', value: true });
    }

    if (event.hit) {
      if (event.reflected) {
        // Reflected — damage goes back to attacker
        if (isPlayer) {
          dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        } else {
          dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        }
        playSound('superEffective');
      } else {
        // Normal — damage goes to target
        if (isPlayer) {
          dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        } else {
          dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        }
        if (event.effectiveness > 1.0) playSound('superEffective');
        else if (event.effectiveness < 1.0) playSound('resisted');
        else playSound('attackHit');
      }
    } else {
      playSound('miss');
    }

    const dmgTarget = event.reflected ? (isPlayer ? 'player' : 'npc') : (isPlayer ? 'npc' : 'player');
    const dmgId = ++damageIdRef.current;
    dispatch({
      type: 'ADD_DAMAGE_NUMBER',
      entry: {
        id: dmgId,
        damage: event.damage,
        effectiveness: event.effectiveness,
        hit: event.hit,
        target: dmgTarget,
      },
    });
    // Track max damage for records
    if (event.hit && isPlayer && !event.reflected) {
      dispatch({ type: 'TRACK_DAMAGE', damage: event.damage });
    }

    // Battle log entry for attack
    if (event.hit) {
      const effText = event.effectiveness > 1 ? ' Super effective!' : event.effectiveness < 1 ? ' Resisted.' : '';
      const reflectText = event.reflected ? ' REFLECTED!' : '';
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — ${event.damage} dmg.${effText}${reflectText}` });
    } else {
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — missed!` });
    }
    if (event.appliedStatus) {
      dispatch({ type: 'ADD_LOG', text: `${event.appliedStatus} applied!` });
      playSound('statusApply');
    }
    await wait(300);

    // RECOIL phase
    if (isPlayer) {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-recoil' });
    } else {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-recoil' });
    }
    await wait(200);

    // RESOLUTION
    dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_ATTACKING', value: false });
    dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });
    await wait(200);
  }, []);

  const handleMoveSelect = useCallback(async (moveKey) => {
    if (animatingRef.current) return;
    playSound('buttonClick');
    animatingRef.current = true;
    dispatch({ type: 'START_ANIMATION' });

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
      await animateEvent(event, dispatch);
    }

    // Sync status from engine
    dispatch({ type: 'SET_PLAYER_STATUS', value: result.player.status || null });
    dispatch({ type: 'SET_NPC_STATUS', value: result.npc.status || null });

    // Process status tick events (DOT, skip)
    for (const event of result.events) {
      if (event.attacker === 'status') {
        if (event.damage > 0) {
          playSound('statusTick');
          const dmgId = ++damageIdRef.current;
          dispatch({
            type: 'ADD_DAMAGE_NUMBER',
            entry: { id: dmgId, damage: event.damage, effectiveness: 1.0, hit: true, target: event.target },
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
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
        playSound('ko');
        await wait(600);

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

        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
        playSound('ko');
        await wait(600);

        if (battleConfig?.isSingularity && phases && !save.singularityComplete) {
          trackStat('battlesWon');
          if (scrapsGained > 0) trackStat('totalScrapsEarned', scrapsGained);
          dispatch({ type: 'SET_EPILOGUE', xpGained, scrapsGained });
          stopMusic();
          playSound('victoryFanfare');
        } else {
          trackStat('battlesWon');
          if (scrapsGained > 0) trackStat('totalScrapsEarned', scrapsGained);
          updateRecords({ turns: state.turnCount + 1, maxDamage: state.maxDamageDealt, won: true });
          dispatch({ type: 'SET_VICTORY', xpGained, leveledUp, newLevel, scrapsGained, coreDropped });
          stopMusic();
          playSound('victoryFanfare');
          playSound('xpGain');
          if (scrapsGained > 0) setTimeout(() => playSound('scrapsEarned'), 200);
          if (leveledUp) setTimeout(() => playSound('levelUp'), 400);
        }
      }
    } else if (result.player.hp <= 0) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-ko' });
      playSound('ko');
      await wait(600);
      trackStat('battlesLost');
      updateRecords({ turns: state.turnCount + 1, maxDamage: state.maxDamageDealt, won: false });
      dispatch({ type: 'SET_DEFEAT' });
      stopMusic();
      playSound('defeatDrone');
    } else {
      const playerHpPct = result.player.hp / (result.player.maxHp || state.playerMaxHp);
      const npcHpPct = result.npc.hp / (result.npc.maxHp || state.npcMaxHp);
      if (playerHpPct < 0.25 || npcHpPct < 0.25) {
        playMusic('battleIntense');
      } else {
        playMusic('battle');
      }
      dispatch({ type: 'RESET_TURN' });
    }

    animatingRef.current = false;
  }, [state, animateEvent]);

  const dragon = state.dragon;
  const npc = state.npc;
  const playerMoves = [...dragon.moveKeys.map((k) => ({ key: k, ...moves[k] })), { key: 'basic_attack', ...moves.basic_attack }];
  const playerColor = elementColors[dragon.element];
  const npcColor = elementColors[npc.element];

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%' }}>
      {/* Arena background */}
      <div className="arena pixelated" style={{ backgroundImage: `url(${npc.arena})`, filter: state.npc.arenaFilter || 'none' }} />

      {/* Top bar — HP */}
      <div className="panel panel-top">
        <div className="hp-bar-container">
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
                width: `${(state.npcHp / state.npcMaxHp) * 100}%`,
                background: `linear-gradient(90deg, ${npcColor.primary}, ${npcColor.glow})`,
              }}
            />
          </div>
          <div style={{ fontSize: 8, color: '#888', marginTop: 2 }}>
            HP {state.npcHp}/{state.npcMaxHp}
          </div>
          {state.npcStatus && (
            <div className={`status-indicator ${STATUS_EFFECTS[state.npcStatus.effect]?.name.toLowerCase().replace(' ', '')}`}>
              {STATUS_EFFECTS[state.npcStatus.effect]?.icon} {STATUS_EFFECTS[state.npcStatus.effect]?.name} {state.npcStatus.turnsLeft}t
            </div>
          )}
        </div>

        <div style={{ color: '#555', fontSize: 14 }}>VS</div>

        <div className="hp-bar-container" style={{ textAlign: 'right' }}>
          <div className="hp-bar-label" style={{ color: playerColor.glow }}>
            <span style={{ color: '#888' }}>Lv.{state.playerLevel}</span> {playerColor.icon} {save.dragons[dragonId]?.nickname || dragon.name}
          </div>
          <div className="hp-bar-track">
            <div
              className="hp-bar-fill"
              style={{
                width: `${(state.playerHp / state.playerMaxHp) * 100}%`,
                background: `linear-gradient(90deg, ${playerColor.primary}, ${playerColor.glow})`,
                marginLeft: 'auto',
              }}
            />
          </div>
          <div style={{ fontSize: 8, color: '#888', marginTop: 2, textAlign: 'right' }}>
            HP {state.playerHp}/{state.playerMaxHp}
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
        <div style={{ position: 'relative' }}>
          <NpcSprite
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
                position={{ x: 40, y: -20 }}
                onComplete={() => dispatch({ type: 'REMOVE_DAMAGE_NUMBER', id: d.id })}
              />
            ))}
        </div>

        <div style={{ position: 'relative' }}>
          <DragonSprite
            spriteSheet={dragon.spriteSheet}
            stage={state.playerStage}
            flipX={true}
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
                position={{ x: 40, y: -20 }}
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

      {/* Battle log */}
      {state.battleLog.length > 0 && (
        <div className="battle-log">
          {state.battleLog.slice(-4).map((text, i) => (
            <div key={i} className="battle-log-entry">{text}</div>
          ))}
        </div>
      )}

      {/* Bottom panel — moves */}
      <div className="panel panel-bottom">
        <div className="move-panel">
          {playerMoves.map((move) => {
            const moveColor = elementColors[move.element] || elementColors.neutral;
            return (
              <button
                key={move.key}
                className="move-btn"
                style={{ borderColor: moveColor.primary, color: moveColor.glow }}
                disabled={state.phase !== PHASES.PLAYER_TURN}
                onClick={() => handleMoveSelect(move.key)}
              >
                <span className="tooltip">PWR:{move.power} ACC:{move.accuracy}%</span>
                {move.name.toUpperCase()}
              </button>
            );
          })}
          <button
            className="move-btn"
            style={{ borderColor: '#44aa44', color: '#66cc66' }}
            disabled={state.phase !== PHASES.PLAYER_TURN}
            onClick={() => handleMoveSelect('defend')}
          >
            <span className="tooltip">Halves damage this turn</span>
            DEFEND
          </button>
        </div>
      </div>

      {/* Victory overlay */}
      {state.phase === PHASES.VICTORY && (
        <div className="result-overlay victory">
          <h2>VICTORY!</h2>
          <div className="xp-display">+{state.xpGained} XP</div>
          {state.scrapsGained > 0 && (
            <div className="xp-display" style={{ color: '#ffcc00' }}>+{state.scrapsGained} ◆</div>
          )}
          {state.leveledUp && (
            <div className="level-up-display">LEVEL UP! Now Lv.{state.newLevel}</div>
          )}
          {state.coreDropped && (
            <div style={{ fontSize: 9, color: elementColors[state.coreDropped.element]?.glow || '#44aaff', marginTop: 4 }}>
              +{state.coreDropped.count} {state.coreDropped.element.toUpperCase()} CORE{state.coreDropped.count > 1 ? 'S' : ''}
            </div>
          )}
          <button className="result-btn" onClick={onBattleEnd}>CONTINUE</button>
        </div>
      )}

      {/* Defeat overlay */}
      {state.phase === PHASES.DEFEAT && (
        <div className="result-overlay defeat">
          <h2>DEFEATED</h2>
          <p style={{ fontSize: 9, color: '#44ff44', maxWidth: 400, textAlign: 'center', lineHeight: 1.8 }}>
            "Hmm, a setback! But every great Dragon Forger learns from defeat. Recalibrate and try again!"
            <br />— Professor Felix
          </p>
          <button className="result-btn" onClick={onBattleEnd}>TRY AGAIN</button>
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
