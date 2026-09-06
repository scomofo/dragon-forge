import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import BattleScreen from './BattleScreen';
import BattleCues from './BattleCues';
import { loadSave } from './persistence';
import { moves } from './gameData';
import { SINGULARITY_BOSSES } from './singularityBosses';

const screen = vi.hoisted(() => ({ state: null, seed: null, resolutions: [], refs: [], states: [], refIndex: 0, stateIndex: 0 }));

// Run real command handlers, reducer transitions and engine outcomes. Only
// React lifecycle, DOM animation and elapsed time are inert in Node.
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useReducer(reducer, initial, initialize) {
    if (!screen.state) screen.state = screen.seed(initialize(initial));
    return [screen.state, action => {
      screen.state = reducer(screen.state, action);
      if (action.type === 'SET_VFX') action.value.onComplete();
    }];
  },
  useState(initial) {
    const index = screen.stateIndex++;
    if (!(index in screen.states)) {
      // As in battleIntegrity, the sixth local state is the completed intro.
      screen.states[index] = index === 5 ? true : typeof initial === 'function' ? initial() : initial;
    }
    return [screen.states[index], value => { screen.states[index] = typeof value === 'function' ? value(screen.states[index]) : value; }];
  },
  useRef(initial) {
    const index = screen.refIndex++;
    return screen.refs[index] ||= { current: initial };
  },
  useCallback: callback => callback,
  useEffect: () => {},
}));

vi.mock('./battleSpeed', async importOriginal => ({ ...await importOriginal(), battleWait: async () => {} }));
vi.mock('./soundEngine', () => ({
  playSound: vi.fn(), playMusic: vi.fn(), stopMusic: vi.fn(), startHeartbeat: vi.fn(), stopHeartbeat: vi.fn(),
}));
vi.mock('./useGamepadController', () => ({ default: () => {} }));
vi.mock('./battleEngine', async importOriginal => {
  const engine = await importOriginal();
  return {
    ...engine,
    resolveTurn(...args) {
      const result = engine.resolveTurn(...args);
      screen.resolutions.push({ args, result });
      return result;
    },
  };
});

function findNode(node, predicate) {
  if (!node || typeof node !== 'object') return null;
  if (Array.isArray(node)) return node.map(child => findNode(child, predicate)).find(Boolean) || null;
  if (predicate(node)) return node;
  return findNode(node.props?.children, predicate);
}

function textContent(node) {
  if (node == null || typeof node === 'boolean') return '';
  if (typeof node !== 'object') return String(node);
  if (Array.isArray(node)) return node.map(textContent).join(' ');
  return textContent(node.props?.children);
}

function mountBattle({ corruption = false, patch = {} } = {}) {
  const save = loadSave();
  for (const progress of Object.values(save.dragons)) progress.owned = true;
  const boss = corruption ? SINGULARITY_BOSSES.find(entry => entry.id === 'data_corruption') : null;
  screen.seed = state => {
    const seeded = {
      ...state,
      playerHp: 1000, playerMaxHp: 1000,
      playerStats: { hp: 1000, atk: 15, def: 20, spd: 100 },
      npcHp: 1000, npcMaxHp: 1000,
      npc: { ...state.npc, stats: { hp: 1000, atk: 10, def: 20, spd: 5 }, moveKeys: ['basic_attack'] },
      bench: { ...state.bench, playerHp: 1000, playerMaxHp: 1000, playerStats: { hp: 1000, atk: 15, def: 20, spd: 1 } },
    };
    return typeof patch === 'function' ? patch(seeded) : { ...seeded, ...patch };
  };
  const props = {
    dragonId: 'light', npcId: 'logic_bomb', save, refreshSave: vi.fn(), onBattleEnd: vi.fn(),
    battleConfig: { benchDragonId: 'stone', ...(boss ? { boss } : {}) },
  };
  const render = () => {
    screen.refIndex = 0;
    screen.stateIndex = 0;
    return BattleScreen(props);
  };
  const button = command => findNode(render(), node => node.type === 'button' && (
    node.key === command || findNode(node.props.children, child => child.type === 'strong' && child.props.children === command)
  ));
  return {
    render,
    button,
    cue(id) {
      return findNode(render(), node => node.type === BattleCues).props.cues.find(entry => entry.id === id);
    },
    async click(command) {
      const control = button(command);
      expect(control, `command ${command} should exist`).not.toBeNull();
      expect(control.props.disabled).not.toBe(true);
      await control.props.onClick();
      return screen.resolutions.at(-1);
    },
  };
}

const npcAttack = result => result.events.find(event => event.attacker === 'npc' && event.action === 'attack');
const playerAction = result => result.events.find(event => event.attacker === 'player');

beforeEach(() => {
  Object.assign(screen, { state: null, seed: null, resolutions: [], refs: [], states: [], refIndex: 0, stateIndex: 0 });
  const storage = new Map();
  vi.stubGlobal('localStorage', {
    getItem: key => storage.get(key) ?? null,
    setItem: (key, value) => storage.set(key, value),
    removeItem: key => storage.delete(key),
  });
  vi.useFakeTimers();
  vi.spyOn(Math, 'random').mockReturnValue(0.5);
});

afterEach(() => {
  vi.clearAllTimers();
  vi.useRealTimers();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe('Logic Bomb authored deadline', () => {
  it('keeps turn seven after an early signature, overrides a stored charge, then spends the fuse', async () => {
    const battle = mountBattle({ patch: { npcHp: 300 } });
    const early = await battle.click('DEFEND');
    expect(npcAttack(early.result).moveKey).toBe('bomb_detonation');
    expect(screen.state.bossState.fuseTurns).toBe(5);
    expect(screen.state.signatureMoveUsed).toBe(true);

    for (let turn = 2; turn <= 6; turn++) {
      const ordinary = await battle.click('DEFEND');
      expect(npcAttack(ordinary.result).moveKey).not.toBe('bomb_detonation');
    }
    expect(screen.state.turnCount).toBe(6);
    expect(screen.state.bossState.fuseTurns).toBe(0);
    expect(battle.cue('fuse').title).toMatch(/armed/i);

    // A charge retained from the preceding turn must not postpone the deadline.
    screen.state = { ...screen.state, npcChargedMove: 'flame_wall', npcStatus: { effect: 'shadow', turnsLeft: 2 } };
    Math.random.mockReturnValue(0.99);
    const detonation = await battle.click('DEFEND');
    expect(npcAttack(detonation.result)).toMatchObject({ moveKey: 'bomb_detonation', hit: true });
    expect(detonation.args[1].chargeMultiplier).toBeUndefined();
    expect(screen.state).toMatchObject({ turnCount: 7, npcChargedMove: null });
    expect(screen.state.bossState.fuseDetonated).toBe(true);
    expect(battle.cue('fuse').title).not.toMatch(/armed/i);

    const following = await battle.click('DEFEND');
    expect(npcAttack(following.result).moveKey).not.toBe('bomb_detonation');
  });

  it.each(['ice', 'storm', 'void'])('fires the armed deadline despite %s without deleting the ailment', async effect => {
    const battle = mountBattle({ patch: state => ({
      ...state, turnCount: 6, npcChargedMove: 'flame_wall', npcStatus: { effect, turnsLeft: 2 },
      bossState: { ...state.bossState, fuseTurns: 0 },
    }) });
    Math.random.mockReturnValue(0.1);
    const { result } = await battle.click('DEFEND');
    expect(npcAttack(result)).toMatchObject({ moveKey: 'bomb_detonation', hit: true });
    expect(result.npc.status).toEqual({ effect, turnsLeft: 1 });
    expect(screen.state.bossState.fuseDetonated).toBe(true);
  });
});

describe('Data Corruption command contract', () => {
  it('shows the corrupted command before the first choice and executes its advertised Basic Attack', async () => {
    const battle = mountBattle({ corruption: true });
    battle.render();
    const { garbledMoveKey } = screen.state.bossState;
    expect(screen.state.bossState).toMatchObject({ garbledDragonId: 'light', garbledTurnsLeft: 2 });
    expect(screen.state.dragon.moveKeys).toContain(garbledMoveKey);
    expect(moves[garbledMoveKey].isSignature).not.toBe(true);
    expect(battle.cue('garble').title).toContain(moves[garbledMoveKey].name);
    expect(battle.cue('garble').detail).toContain('2 more uses');
    expect(textContent(battle.button(garbledMoveKey))).toMatch(/BASIC/i);
    expect(textContent(battle.button(garbledMoveKey))).toContain(`PWR ${moves.basic_attack.power}`);

    const { result } = await battle.click(garbledMoveKey);
    expect(playerAction(result)).toMatchObject({ moveKey: 'basic_attack', corruptedMoveKey: garbledMoveKey, element: 'neutral' });
    expect(screen.state.playerMoveHistory).toEqual(['basic_attack']);
    expect(screen.state.bossState.garbledTurnsLeft).toBe(1);
  });

  it('keeps unused corruption through other commands and Freeze, clearing after two executed uses', async () => {
    const battle = mountBattle({ corruption: true });
    battle.render();
    const key = screen.state.bossState.garbledMoveKey;
    await battle.click('DEFEND');
    expect(screen.state.bossState.garbledTurnsLeft).toBe(2);

    screen.state = { ...screen.state, playerStatus: { effect: 'ice', turnsLeft: 1 } };
    const skipped = await battle.click(key);
    expect(playerAction(skipped.result)).toMatchObject({ action: 'statusSkip', statusName: 'Freeze' });
    expect(screen.state.bossState.garbledTurnsLeft).toBe(2);

    await battle.click(key);
    expect(screen.state.bossState.garbledTurnsLeft).toBe(1);
    await battle.click(key);
    expect(screen.state.bossState).toMatchObject({ garbledMoveKey: null, garbledTurnsLeft: 0 });
    expect(battle.cue('garble').title).toMatch(/clear/i);
  });

  it.each([
    ['into', 'solar_flare', 0.1, 'basic_attack', 1],
    ['out of', 'radiant_beam', 0.5, 'solar_flare', 2],
  ])('counts the move Glitch actually chooses %s the corrupted slot', async (_direction, selected, roll, expected, remaining) => {
    const battle = mountBattle({ corruption: true, patch: state => ({
      ...state, playerStatus: { effect: 'void', turnsLeft: 2 },
      bossState: { ...state.bossState, garbledMoveKey: 'radiant_beam', garbledDragonId: 'light', garbledTurnsLeft: 2 },
    }) });
    battle.render();
    Math.random.mockReturnValue(roll);
    const { result } = await battle.click(selected);
    expect(playerAction(result).moveKey).toBe(expected);
    expect(screen.state.bossState.garbledTurnsLeft).toBe(remaining);
    expect(screen.state.playerMoveHistory).toEqual([expected]);
  });

  it.each([null, { effect: 'fire', turnsLeft: 1 }])('rearms after a successful Burn application, including a refresh (%j)', async status => {
    const battle = mountBattle({ corruption: true, patch: state => ({
      ...state, playerStatus: status, npcChargedMove: 'flame_wall',
      npc: { ...state.npc, stats: { ...state.npc.stats, spd: 200 } },
      bossState: { ...state.bossState, garbledMoveKey: 'solar_flare', garbledDragonId: 'light', garbledTurnsLeft: 1 },
    }) });
    battle.render();
    Math.random.mockReturnValue(0.1);
    const { result } = await battle.click('solar_flare');
    expect(npcAttack(result)).toMatchObject({ hit: true, appliedStatus: 'Burn' });
    // The already committed command uses its original corruption; the new
    // slot takes effect for the next choice even when the boss attacks first.
    expect(playerAction(result)).toMatchObject({ moveKey: 'basic_attack', corruptedMoveKey: 'solar_flare' });
    expect(screen.state.bossState).toMatchObject({ garbledDragonId: 'light', garbledMoveKey: 'radiant_beam', garbledTurnsLeft: 2 });
    expect(battle.cue('garble').title).toContain('Radiant Beam');
  });

  it('does not rearm from an existing Burn tick or a failed new status roll', async () => {
    const battle = mountBattle({ corruption: true, patch: state => ({
      ...state, playerStatus: { effect: 'fire', turnsLeft: 2 }, npcChargedMove: 'flame_wall',
      bossState: { ...state.bossState, garbledMoveKey: 'solar_flare', garbledDragonId: 'light', garbledTurnsLeft: 1 },
    }) });
    const { result } = await battle.click('DEFEND');
    expect(npcAttack(result)).toMatchObject({ hit: true, appliedStatus: null });
    expect(result.events.some(event => event.attacker === 'status' && event.effectName === 'Burn')).toBe(true);
    expect(screen.state.bossState).toMatchObject({ garbledMoveKey: 'solar_flare', garbledDragonId: 'light', garbledTurnsLeft: 1 });
  });

  it('keeps corruption with its dragon on a swap and rearms on the incoming Burn recipient', async () => {
    const battle = mountBattle({ corruption: true });
    battle.render();
    const original = { ...screen.state.bossState };
    const swapped = await battle.click('SWAP');
    expect(screen.state.dragonId).toBe('stone');
    expect(screen.state.bossState).toMatchObject({ garbledDragonId: 'light', garbledMoveKey: original.garbledMoveKey, garbledTurnsLeft: 2 });
    expect(playerAction(swapped.result).action).toBe('defend');
    expect(swapped.args[6].playerCorruptedMoveKey).toBeFalsy();

    screen.state = { ...screen.state, npcChargedMove: 'flame_wall' };
    Math.random.mockReturnValue(0.1);
    const burned = await battle.click('DEFEND');
    expect(npcAttack(burned.result).appliedStatus).toBe('Burn');
    expect(screen.state.bossState).toMatchObject({ garbledDragonId: 'stone', garbledTurnsLeft: 2 });
    expect(screen.state.dragon.moveKeys).toContain(screen.state.bossState.garbledMoveKey);
  });
});
