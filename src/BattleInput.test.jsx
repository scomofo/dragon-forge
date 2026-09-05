import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import BattleScreen from './BattleScreen';
import { loadSave } from './persistence';
import { getBattleSpeed, setBattleSpeed } from './battleSpeed';

const screen = vi.hoisted(() => ({
  state: null, seed: null, states: [], refs: [], stateIndex: 0, refIndex: 0,
  effects: [], effectIndex: 0, pendingEffects: [], dirty: false, introDone: true,
  handlers: null, resolutions: [], activeElement: null,
}));

// Exercise the actual screen's registered input handlers and command props in
// the project's Node environment. Hooks retain state and effects register the
// real window listener; only animation/time and physical DOM focus are inert.
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useReducer(reducer, initial, initialize) {
    if (!screen.state) screen.state = screen.seed(initialize(initial));
    return [screen.state, action => {
      screen.state = reducer(screen.state, action);
      screen.dirty = true;
      if (action.type === 'SET_VFX') action.value.onComplete();
    }];
  },
  useState(initial) {
    const index = screen.stateIndex++;
    if (!(index in screen.states)) screen.states[index] = index === 5 ? screen.introDone : typeof initial === 'function' ? initial() : initial;
    return [screen.states[index], value => {
      const next = typeof value === 'function' ? value(screen.states[index]) : value;
      if (!Object.is(next, screen.states[index])) screen.dirty = true;
      screen.states[index] = next;
    }];
  },
  useRef(initial) { return screen.refs[screen.refIndex++] ||= { current: initial }; },
  useCallback: callback => callback,
  useEffect(effect, dependencies) {
    const index = screen.effectIndex++;
    const previous = screen.effects[index];
    if (!previous || !dependencies || dependencies.some((value, i) => !Object.is(value, previous.dependencies?.[i]))) {
      screen.pendingEffects.push(() => {
        previous?.cleanup?.();
        screen.effects[index] = { dependencies, cleanup: effect() };
      });
    }
  },
}));
vi.mock('./useGamepadController', () => ({ default: handlers => { screen.handlers = handlers; } }));
vi.mock('./soundEngine', () => ({ playSound: vi.fn(), playMusic: vi.fn(), stopMusic: vi.fn(), startHeartbeat: vi.fn(), stopHeartbeat: vi.fn() }));
vi.mock('./battleSpeed', async importOriginal => ({ ...await importOriginal(), battleWait: async () => {} }));
vi.mock('./animationEngine', async importOriginal => ({ ...await importOriginal(), hitStop: async () => {}, pixelShake: vi.fn() }));
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

function findAll(node, predicate) {
  if (!node || typeof node !== 'object') return [];
  if (Array.isArray(node)) return node.flatMap(child => findAll(child, predicate));
  return [...(predicate(node) ? [node] : []), ...findAll(node.props?.children, predicate)];
}

function domButton(props = {}) {
  const element = {
    dataset: { battleCommand: props['data-battle-command'] },
    closest(query) {
      const selectors = query.split(',').map(selector => selector.trim());
      return selectors.includes('button') || (selectors.includes('[data-battle-command]') && element.dataset.battleCommand) ? element : null;
    },
    focus() { screen.activeElement = element; props.onFocus?.(); },
  };
  return element;
}

function mountBattle({ benchDragonId = 'stone', patch = {} } = {}) {
  const save = loadSave();
  for (const dragon of Object.values(save.dragons)) dragon.owned = true;
  screen.seed = state => ({
    ...state,
    playerHp: 100, playerMaxHp: 100,
    playerStats: { hp: 100, atk: 20, def: 80, spd: 80 },
    npcHp: 1000, npcMaxHp: 1000,
    npc: { ...state.npc, stats: { hp: 1000, atk: 10, def: 50, spd: 5 }, moveKeys: ['basic_attack'] },
    bossPatternId: 'input_test_opponent',
    ...patch,
  });
  const props = { dragonId: 'fire', npcId: 'firewall_sentinel', save, refreshSave: vi.fn(), onBattleEnd: vi.fn(), battleConfig: { benchDragonId } };
  let tree;
  const render = () => {
    let renders = 0;
    do {
      if (++renders > 8) throw new Error('Battle input render did not settle');
      screen.dirty = false;
      screen.stateIndex = 0;
      screen.refIndex = 0;
      screen.effectIndex = 0;
      screen.pendingEffects = [];
      tree = BattleScreen(props);
      const buttons = findAll(tree, node => node.type === 'button' && node.props['data-battle-command']);
      tree.ref.current = { querySelectorAll: () => buttons.map(button => domButton(button.props)) };
      for (const effect of screen.pendingEffects) effect();
    } while (screen.dirty);
    return tree;
  };
  const command = id => findAll(render(), node => node.type === 'button' && node.props['data-battle-command'] === id)[0];
  render();
  return {
    render, command,
    focus(id) { domButton(command(id).props).focus(); render(); },
    selected() { return findAll(render(), node => node.type === 'button' && node.props['data-battle-command'] && node.props.className.includes('controller-focus')).map(node => node.props['data-battle-command']); },
    direction(direction) { screen.handlers.onDirectionPress(direction); render(); },
    key(key, target = null) {
      const event = { key, target, preventDefault: vi.fn() };
      window.keyHandler?.(event);
      return event;
    },
  };
}

beforeEach(() => {
  Object.assign(screen, { state: null, seed: null, states: [], refs: [], stateIndex: 0, refIndex: 0, effects: [], effectIndex: 0, pendingEffects: [], dirty: false, introDone: true, handlers: null, resolutions: [], activeElement: null });
  const storage = new Map();
  vi.stubGlobal('window', {
    localStorage: { getItem: key => storage.get(key) ?? null, setItem: (key, value) => storage.set(key, value), removeItem: key => storage.delete(key) },
    addEventListener(type, listener) { if (type === 'keydown') this.keyHandler = listener; },
    removeEventListener(type, listener) { if (type === 'keydown' && this.keyHandler === listener) this.keyHandler = null; },
  });
  vi.useFakeTimers();
  vi.spyOn(Math, 'random').mockReturnValue(0.5);
  setBattleSpeed(1);
});

afterEach(() => {
  for (const effect of screen.effects) effect?.cleanup?.();
  vi.clearAllTimers();
  vi.useRealTimers();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  setBattleSpeed(1);
});

describe('battle input integration', () => {
  it('leaves Enter on focused Swap to native activation and spends exactly one swap turn', async () => {
    const battle = mountBattle();
    battle.focus('swap');
    const button = battle.command('swap');
    const event = battle.key('Enter', domButton(button.props));
    expect(event.preventDefault).not.toHaveBeenCalled();
    expect(screen.resolutions).toHaveLength(0);
    // The browser's following native button activation calls this real handler.
    await button.props.onClick();
    expect(screen.resolutions).toHaveLength(1);
    expect(screen.resolutions[0].args[2]).toBe('defend');
    expect(screen.state.dragonId).toBe('stone');
    expect(screen.state.turnCount).toBe(1);
  });

  it('lets gamepad directions reach Swap, skip the spent signature, and synchronize DOM focus', () => {
    const battle = mountBattle({ patch: { playerSignatureUsed: { fire: true } } });
    battle.focus('flame_wall');
    battle.direction('RIGHT');
    expect(battle.selected()).toEqual(['basic_attack']);
    expect(screen.activeElement.dataset.battleCommand).toBe('basic_attack');
    battle.focus('defend');
    battle.direction('RIGHT');
    expect(battle.selected()).toEqual(['swap']);
    expect(screen.activeElement.dataset.battleCommand).toBe('swap');
    battle.direction('RIGHT');
    expect(battle.selected()).toEqual(['speed']);
  });

  it('does not start a turn or toggle tempo/auto while a save-download button has focus', () => {
    const battle = mountBattle();
    const download = domButton();
    for (const key of ['Enter', ' ', 'ArrowRight', 'd', 's', 'a']) {
      expect(battle.key(key, download).preventDefault).not.toHaveBeenCalled();
    }
    expect(screen.resolutions).toHaveLength(0);
    expect(getBattleSpeed()).toBe(1);
    expect(battle.command('auto').props.className).not.toMatch(/\bselected\b/);
    expect(battle.selected()).toEqual(['magma_breath']);
  });

  it('disables Defend and Swap until the entrance finishes across pointer, key and gamepad input', async () => {
    screen.introDone = false;
    const battle = mountBattle();
    for (const id of ['defend', 'swap']) {
      expect(battle.command(id).props.disabled).toBe(true);
      await battle.command(id).props.onClick();
    }
    battle.key('d');
    screen.handlers.onButtonPress('B');
    screen.handlers.onButtonPress('A');
    expect(screen.resolutions).toHaveLength(0);
    battle.key('s');
    expect(getBattleSpeed()).toBe(2);
  });

  it('keeps Defend selected when a consumed dual tech disappears, then confirms Defend rather than Speed', async () => {
    const battle = mountBattle({ benchDragonId: 'ice' });
    expect(battle.command('dual_steam_burst')).toBeDefined();
    battle.focus('defend');
    screen.state = { ...screen.state, dualTechUsed: true };
    expect(battle.command('dual_steam_burst')).toBeUndefined();
    expect(battle.selected()).toEqual(['defend']);
    screen.handlers.onButtonPress('A');
    await vi.runAllTimersAsync();
    expect(screen.resolutions).toHaveLength(1);
    expect(screen.resolutions[0].args[2]).toBe('defend');
    expect(getBattleSpeed()).toBe(1);
  });
});
