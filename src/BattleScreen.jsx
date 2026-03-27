import { useReducer, useCallback, useEffect, useRef } from 'react';
import { dragons, npcs, moves, elementColors } from './gameData';
import {
  resolveTurn, pickNpcMove, calculateStatsForLevel,
  getStageForLevel, calculateXpGain,
} from './battleEngine';
import { loadSave, saveDragonProgress } from './persistence';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';
import DamageNumber from './DamageNumber';

const PHASES = {
  PLAYER_TURN: 'playerTurn',
  ANIMATING: 'animating',
  VICTORY: 'victory',
  DEFEAT: 'defeat',
};

function initBattle(dragonId, npcId) {
  const dragon = dragons[dragonId];
  const npc = npcs[npcId];
  const save = loadSave();
  const progress = save.dragons[dragonId] || { level: 1, xp: 0 };
  const stage = getStageForLevel(progress.level);
  const stats = calculateStatsForLevel(dragon.baseStats, progress.level);

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
      return { ...state, phase: PHASES.VICTORY, xpGained: action.xpGained, leveledUp: action.leveledUp, newLevel: action.newLevel };
    case 'SET_DEFEAT':
      return { ...state, phase: PHASES.DEFEAT };
    case 'RESET_TURN':
      return { ...state, phase: PHASES.PLAYER_TURN, playerSpriteClass: '', npcSpriteClass: '', npcAttacking: false, playerForcedFrame: null };
    default:
      return state;
  }
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let damageIdCounter = 0;

export default function BattleScreen({ dragonId, npcId, onBattleEnd }) {
  const [state, dispatch] = useReducer(battleReducer, null, () => initBattle(dragonId, npcId));
  const animatingRef = useRef(false);

  const animateEvent = useCallback(async (event, dispatch) => {
    const isPlayer = event.attacker === 'player';

    if (event.action === 'defend') {
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
        await wait(400);
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
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
    await wait(400);

    // IMPACT phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: 3 });
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_NPC_ATTACKING', value: true });
    }

    // Apply damage + show number
    if (event.hit) {
      if (isPlayer) {
        dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
      } else {
        dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
      }
    }

    const dmgId = ++damageIdCounter;
    dispatch({
      type: 'ADD_DAMAGE_NUMBER',
      entry: {
        id: dmgId,
        damage: event.damage,
        effectiveness: event.effectiveness,
        hit: event.hit,
        target: isPlayer ? 'npc' : 'player',
      },
    });
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
    };

    const npcMoveKey = pickNpcMove(state.npc.moveKeys, state.npc.element, state.dragon.element);
    const result = resolveTurn(playerState, npcState, moveKey, npcMoveKey);

    for (const event of result.events) {
      await animateEvent(event, dispatch);
    }

    if (result.npc.hp <= 0) {
      const xpGained = calculateXpGain(state.npc.baseXP, state.playerLevel, state.npc.level);
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

      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
      await wait(600);
      dispatch({ type: 'SET_VICTORY', xpGained, leveledUp, newLevel });
    } else if (result.player.hp <= 0) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-ko' });
      await wait(600);
      dispatch({ type: 'SET_DEFEAT' });
    } else {
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
      <div className="arena" style={{ background: npc.arena }} />

      {/* Top bar — HP */}
      <div className="panel panel-top">
        <div className="hp-bar-container">
          <div className="hp-bar-label" style={{ color: npcColor.glow }}>
            {npc.name} <span style={{ color: '#888' }}>Lv.{npc.level}</span>
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
        </div>

        <div style={{ color: '#555', fontSize: 14 }}>VS</div>

        <div className="hp-bar-container" style={{ textAlign: 'right' }}>
          <div className="hp-bar-label" style={{ color: playerColor.glow }}>
            <span style={{ color: '#888' }}>Lv.{state.playerLevel}</span> {dragon.name}
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
      </div>

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
          {state.leveledUp && (
            <div className="level-up-display">LEVEL UP! Now Lv.{state.newLevel}</div>
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
    </div>
  );
}
