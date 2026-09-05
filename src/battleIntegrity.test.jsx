import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import BattleScreen from './BattleScreen';
import DragonSprite from './DragonSprite';
import { loadSave } from './persistence';

const screen = vi.hoisted(() => ({ state: null, seed: null, updates: [], resolutions: [], refs: [], states: [], refIndex: 0, stateIndex: 0 }));

// Exercise the actual command buttons, reducer, and engine in the project's Node
// test environment. Only React lifecycle/DOM animation and elapsed time are inert.
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useReducer(reducer, initial, initialize) {
    if (!screen.state) screen.state = screen.seed(initialize(initial));
    return [screen.state, action => {
      screen.state = reducer(screen.state, action);
      screen.updates.push({ action, state: screen.state });
      if (action.type === 'SET_VFX') action.value.onComplete();
    }];
  },
  useState(initial) {
    const index = screen.stateIndex++;
    if (!(index in screen.states)) {
      // introDone is the sixth local state; the entrance has finished here.
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

function findButton(node, label) {
  if (!node || typeof node !== 'object') return null;
  if (Array.isArray(node)) {
    for (const child of node) {
      const found = findButton(child, label);
      if (found) return found;
    }
    return null;
  }
  if (node.type === 'button') {
    const children = Array.isArray(node.props.children) ? node.props.children : [node.props.children];
    if (children.some(child => child?.type === 'strong' && child.props.children === label)) return node;
  }
  return findButton(node.props?.children, label);
}

function findComponent(node, component) {
  if (!node || typeof node !== 'object') return null;
  if (Array.isArray(node)) return node.map(child => findComponent(child, component)).find(Boolean) || null;
  if (node.type === component) return node;
  return findComponent(node.props?.children, component);
}

function mountBattle({ dragonId = 'light', npcId = 'firewall_sentinel', benchDragonId = 'stone', patch = {}, battleConfig = {} } = {}) {
  const save = loadSave();
  for (const progress of Object.values(save.dragons)) progress.owned = true;
  screen.seed = state => {
    const seeded = {
      ...state,
      playerHp: 50, playerMaxHp: 100,
      playerStats: { hp: 100, atk: 15, def: 20, spd: 100 },
      npcHp: 1000, npcMaxHp: 1000,
      npc: { ...state.npc, stats: { hp: 1000, atk: 10, def: 20, spd: 5 }, moveKeys: ['basic_attack'] },
      bossPatternId: 'test_opponent',
      ...(state.bench ? { bench: { ...state.bench, playerHp: 150, playerMaxHp: 150, playerStats: { hp: 150, atk: 40, def: 80, spd: 1 } } } : {}),
    };
    return typeof patch === 'function' ? patch(seeded) : { ...seeded, ...patch };
  };
  const props = { dragonId, npcId, save, refreshSave: vi.fn(), onBattleEnd: vi.fn(), battleConfig: { benchDragonId, ...battleConfig } };
  const render = () => {
    screen.refIndex = 0;
    screen.stateIndex = 0;
    return BattleScreen(props);
  };
  return {
    async click(label) {
      const button = findButton(render(), label);
      expect(button, `command ${label} should be present`).not.toBeNull();
      expect(button.props.disabled).not.toBe(true);
      await button.props.onClick();
    },
    render,
  };
}

beforeEach(() => {
  Object.assign(screen, { state: null, seed: null, updates: [], resolutions: [], refs: [], states: [], refIndex: 0, stateIndex: 0 });
  const storage = new Map();
  vi.stubGlobal('localStorage', {
    getItem: key => storage.get(key) ?? null,
    setItem: (key, value) => storage.set(key, value),
    removeItem: key => storage.delete(key),
  });
  vi.useFakeTimers();
  vi.spyOn(Math, 'random').mockReturnValue(0.5); // landed, non-critical attacks with stable damage
});

afterEach(() => {
  vi.clearAllTimers();
  vi.useRealTimers();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe('battle screen HP and party integrity', () => {
  it.each([
    ['heals before an enemy hit', 100, 10, 50],
    ['heals after an enemy hit', 1, 10, 50],
    ['takes more damage than it heals', 100, 20, 70],
    ['caps healing at maximum HP before damage', 100, 10, 95],
  ])('%s without losing or duplicating HP', async (_name, speed, enemyAttack, hp) => {
    const battle = mountBattle({ patch: state => ({
      ...state, playerHp: hp, playerStats: { ...state.playerStats, spd: speed },
      npc: { ...state.npc, stats: { ...state.npc.stats, atk: enemyAttack } },
    }) });
    await battle.click('RESTORATION');
    expect(screen.resolutions).toHaveLength(1);
    const { result } = screen.resolutions[0];
    expect(result.events.some(event => event.action === 'heal')).toBe(true);
    expect(result.events.some(event => event.attacker === 'npc' && event.damage > 0)).toBe(true);
    expect(screen.state.playerHp).toBe(result.player.hp);
    expect(screen.state.playerSignatureUsed.light).toBe(true);
    expect(screen.state.turnCount).toBe(1);

    // Final reconciliation must not conceal an incorrect HP animation: each
    // displayed heal/hit should already have reached the engine's outcome.
    const syncIndex = screen.updates.findIndex(({ action }) => action.type === 'SYNC_BATTLE_RESULT');
    expect(syncIndex).toBeGreaterThan(0);
    expect(screen.updates[syncIndex - 1].state.playerHp).toBe(result.player.hp);
    const hpUpdates = screen.updates.filter(({ action }) => ['APPLY_HEAL_TO_PLAYER', 'APPLY_DAMAGE_TO_PLAYER'].includes(action.type));
    expect(hpUpdates).toHaveLength(2);
    expect(hpUpdates[0].action.type).toBe(speed > 5 ? 'APPLY_HEAL_TO_PLAYER' : 'APPLY_DAMAGE_TO_PLAYER');
    expect(hpUpdates.every(({ state }) => state.playerHp <= state.playerMaxHp)).toBe(true);
  });

  it('guards a slower incoming dragon, applies entry damage once, and ticks both statuses once', async () => {
    const battle = mountBattle({ patch: state => ({
      ...state,
      playerStatus: { effect: 'fire', turnsLeft: 3 },
      bench: { ...state.bench, playerStatus: { effect: 'venom', turnsLeft: 3 } },
      npcStatus: { effect: 'fire', turnsLeft: 3 },
      npc: { ...state.npc, stats: { ...state.npc.stats, atk: 25 } },
    }) });
    await battle.click('SWAP');
    const { args, result } = screen.resolutions[0];
    expect(screen.resolutions).toHaveLength(1);
    expect(args[0]).toMatchObject({ element: 'stone', def: 80, spd: 1, hp: 150 });
    expect(args[6].playerGuardOnEntry).toBe(true);
    expect(result.events.filter(event => event.attacker === 'npc' && event.action === 'attack')).toHaveLength(1);
    expect(result.events.filter(event => event.attacker === 'status')).toHaveLength(2);
    expect(screen.state).toMatchObject({ dragonId: 'stone', playerHp: result.player.hp, npcHp: result.npc.hp, playerStatus: result.player.status, npcStatus: result.npc.status, turnCount: 1, phase: 'playerTurn' });
    expect(screen.state.bench).toMatchObject({ dragonId: 'light', playerHp: 50, playerStatus: { effect: 'fire', turnsLeft: 3 } });
    expect(findComponent(battle.render(), DragonSprite).props.actorId).toBe('stone');
    const attack = result.events.find(event => event.attacker === 'npc' && event.action === 'attack');
    expect(screen.updates.filter(({ action }) => action.type === 'APPLY_DAMAGE_TO_PLAYER' && action.damage === attack.damage)).toHaveLength(1);
  });

  it('consumes a stored charged strike when swapping', async () => {
    const battle = mountBattle({ patch: { npcChargedMove: 'magma_breath' } });
    await battle.click('SWAP');
    const { args, result } = screen.resolutions[0];
    expect(args[3]).toBe('magma_breath');
    expect(args[1].chargeMultiplier).toBe(1.4);
    expect(screen.state.npcChargedMove).toBeNull();
    expect(screen.state.playerHp).toBe(result.player.hp);
    expect(screen.state.turnCount).toBe(1);
  });

  it('returns the outgoing dragon after a lethal entry hit without an extra turn or ghost fighter', async () => {
    const battle = mountBattle({ patch: state => ({ ...state, bench: { ...state.bench, playerHp: 1 } }) });
    await battle.click('SWAP');
    expect(screen.resolutions[0].result.player.hp).toBe(0);
    expect(screen.state).toMatchObject({ dragonId: 'light', playerHp: 50, bench: null, turnCount: 1, phase: 'playerTurn' });
    expect(screen.updates.filter(({ action }) => action.type === 'FAINT_SWAP')).toHaveLength(1);
  });

  it.each([2, 5])('Siren turn %i preserves the outgoing fighter and uses incoming stats for one complete turn', async turn => {
    const battle = mountBattle({ npcId: 'phishing_siren', patch: state => ({
      ...state, turnCount: turn - 1, bossPatternId: 'phishing_siren',
      bench: { ...state.bench, playerStatus: { effect: 'venom', turnsLeft: 3 } },
    }) });
    await battle.click('RESTORATION');
    expect(screen.resolutions).toHaveLength(1);
    const { args, result } = screen.resolutions[0];
    expect(args[0]).toMatchObject({ element: 'stone', def: 80, spd: 1, hp: 150 });
    expect(args[2]).toBe('defend');
    expect(args[6]).toMatchObject({ playerGuardOnEntry: true, npcOpeningMoveKey: 'toxic_cloud' });
    const enemyAttacks = result.events.filter(event => event.attacker === 'npc' && event.action === 'attack');
    expect(enemyAttacks.map(event => event.moveKey)).toEqual(['toxic_cloud', 'basic_attack']);
    expect(result.events.filter(event => event.attacker === 'status' && event.target === 'player')).toHaveLength(1);
    expect(result.events.some(event => event.attacker === 'player' && event.action === 'heal')).toBe(false);
    expect(screen.state).toMatchObject({ dragonId: 'stone', playerHp: result.player.hp, turnCount: turn, phase: 'playerTurn', playerStatus: { effect: 'venom', turnsLeft: 2 } });
    expect(screen.state.bench).toMatchObject({ dragonId: 'light', playerHp: 50 });
    expect(findComponent(battle.render(), DragonSprite).props.actorId).toBe('stone');
    expect(screen.state.playerSignatureUsed.light).not.toBe(true);
    expect(screen.state.dualTechUsed).toBe(false);
    expect(screen.state.playerMoveHistory).toEqual(['defend']);
    expect(screen.updates.filter(({ action }) => action.type === 'FAINT_SWAP')).toHaveLength(0);
  });

  it('stops Siren after a lethal opening cloud and returns the healthy reserve exactly once', async () => {
    const battle = mountBattle({ npcId: 'phishing_siren', patch: state => ({
      ...state, turnCount: 1, bossPatternId: 'phishing_siren', bench: { ...state.bench, playerHp: 1 },
    }) });
    await battle.click('RESTORATION');
    expect(screen.resolutions).toHaveLength(1);
    const { result } = screen.resolutions[0];
    expect(result.player.hp).toBe(0);
    expect(result.events.filter(event => event.action === 'attack').map(event => event.moveKey)).toEqual(['toxic_cloud']);
    expect(screen.state).toMatchObject({ dragonId: 'light', playerHp: 50, bench: null, turnCount: 2, phase: 'playerTurn' });
    expect(screen.state.playerSignatureUsed.light).not.toBe(true);
  });

  it('shows Vulture lifesteal before reconciliation and preserves the healed HP', async () => {
    const battle = mountBattle({ npcId: 'protocol_vulture', patch: { npcHp: 400, bossPatternId: 'protocol_vulture' } });
    await battle.click('DEFEND');
    const { result } = screen.resolutions[0];
    const drain = result.events.find(event => event.moveKey === 'vulture_drain');
    expect(drain.lifesteal).toBeGreaterThan(0);
    expect(screen.state.npcHp).toBe(result.npc.hp);
    expect(screen.state.npcHp).toBe(400 + drain.lifesteal);
    expect(screen.state.playerStatus?.effect).toBe('shadow');
    const heal = screen.updates.find(({ action }) => action.type === 'APPLY_HEAL_TO_NPC');
    expect(heal.state.npcHp).toBe(result.npc.hp);
  });

  it.each([['DEFEND', true], ['RESTORATION', false]])('accounts for current-turn %s before Great Reset and reserve entry', async (command, shouldReset) => {
    const battle = mountBattle({ battleConfig: { isMirrorAdmin: true }, patch: state => ({
      ...state, playerHp: 1, npcHp: 500, currentPhase: 2,
      npc: { ...state.npc, stats: { ...state.npc.stats, atk: 100 } },
    }) });
    await battle.click(command);
    expect(screen.resolutions[0].result.player.hp).toBe(0);
    expect(screen.state).toMatchObject({ dragonId: 'stone', playerHp: 150, bench: null, phase: 'playerTurn', turnCount: 1 });
    expect(screen.state.npcHp).toBe(shouldReset ? 750 : 500);
    expect(screen.state.bossState.mirrorHealPunished).toBe(shouldReset);
    expect(screen.state.phaseMoveHistory).toEqual([command.toLowerCase()]);
  });

  it('does not spend an interrupted Restoration when Glitch resolves another move', async () => {
    const battle = mountBattle({ battleConfig: { isMirrorAdmin: true }, patch: state => ({
      ...state, playerHp: 1, npcHp: 500, currentPhase: 2, playerStatus: { effect: 'void', turnsLeft: 3 },
      npc: { ...state.npc, stats: { ...state.npc.stats, atk: 100 } },
    }) });
    await battle.click('RESTORATION');
    const { result } = screen.resolutions[0];
    const executed = result.events.find(event => event.attacker === 'player');
    expect(executed.moveKey).toBe('solar_flare');
    expect(screen.state.playerSignatureUsed.light).not.toBe(true);
    expect(screen.state.phaseMoveHistory).toEqual(['solar_flare']);
    expect(screen.state.npcHp).toBe(result.npc.hp + 250);
    expect(screen.state.bossState.mirrorHealPunished).toBe(true);
  });

  it.each([true, false])('settles simultaneous DOT knockouts during a phase shift (reserve: %s)', async hasReserve => {
    const nextPhase = { name: 'Next Phase', element: 'storm', level: 1, stats: { hp: 200, atk: 20, def: 20, spd: 20 }, moveKeys: ['basic_attack'] };
    const battle = mountBattle({
      benchDragonId: hasReserve ? 'stone' : null,
      battleConfig: { phases: [{}, nextPhase] },
      patch: { playerHp: 1, npcHp: 1, npcChargedMove: 'npc_focus', playerStatus: { effect: 'fire', turnsLeft: 2 }, npcStatus: { effect: 'fire', turnsLeft: 2 } },
    });
    await battle.click('DEFEND');
    const { result } = screen.resolutions[0];
    expect(result.events.filter(event => event.attacker === 'status')).toHaveLength(2);
    expect(result.player.hp).toBe(0);
    expect(result.npc.hp).toBe(0);
    expect(screen.state).toMatchObject({ currentPhase: 1, npcHp: 200, turnCount: 1 });
    if (hasReserve) {
      expect(screen.state).toMatchObject({ dragonId: 'stone', playerHp: 150, bench: null, phase: 'playerTurn' });
    } else {
      expect(screen.state).toMatchObject({ playerHp: 0, phase: 'defeat' });
    }
  });
});
