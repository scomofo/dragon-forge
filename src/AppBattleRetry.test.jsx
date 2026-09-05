import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import App from './App';
import TitleScreen from './TitleScreen';
import HatcheryScreen from './HatcheryScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import OuterGridScreen from './OuterGridScreen';
import SingularityScreen from './SingularityScreen';
import { loadSave, writeSave } from './persistence';
import { getDailyChallenge } from './dailyChallenge';
import { MIRROR_ADMIN } from './singularityBosses';
import { playMusic } from './soundEngine';

const hooks = vi.hoisted(() => ({ states: [], refs: [], stateIndex: 0, refIndex: 0 }));
vi.mock('react', async original => ({
  ...await original(),
  useState(initial) {
    const index = hooks.stateIndex++;
    if (!(index in hooks.states)) hooks.states[index] = typeof initial === 'function' ? initial() : initial;
    return [hooks.states[index], value => { hooks.states[index] = typeof value === 'function' ? value(hooks.states[index]) : value; }];
  },
  useRef(initial) { return hooks.refs[hooks.refIndex++] ??= { current: initial }; },
  useEffect: () => {},
  useSyncExternalStore: (_subscribe, snapshot) => snapshot(),
}));
vi.mock('./soundEngine', () => ({ playMusic: vi.fn(), playSound: vi.fn(), stopMusic: vi.fn() }));

function render() {
  hooks.stateIndex = 0;
  hooks.refIndex = 0;
  return App();
}

function find(node, component) {
  if (!node || typeof node !== 'object') return null;
  if (Array.isArray(node)) return node.map(child => find(child, component)).find(Boolean);
  return node.type === component ? node : find(node.props?.children, component);
}

function navigate(target) {
  find(render(), TitleScreen).props.onStart();
  find(render(), HatcheryScreen).props.onNavigate(target);
}

beforeEach(() => {
  Object.assign(hooks, { states: [], refs: [], stateIndex: 0, refIndex: 0 });
  const data = new Map();
  vi.stubGlobal('window', { localStorage: {
    getItem: key => data.get(key) ?? null,
    setItem: (key, value) => data.set(key, value),
    removeItem: key => data.delete(key),
  } });
  const save = loadSave();
  save.dragons.fire.owned = true;
  save.dragons.ice.owned = true;
  writeSave(save);
  vi.clearAllMocks();
});

afterEach(() => vi.unstubAllGlobals());

describe('App rematch boundary', () => {
  it('remounts the same room encounter using fresh saved party progress', () => {
    navigate('outerGrid');
    find(render(), OuterGridScreen).props.onBeginCampaignBattle({
      dragonId: 'fire', npcId: 'firewall_sentinel', benchDragonId: 'ice',
      nodeId: 'signal-breach', returnScreen: 'outerGrid',
    });
    const first = find(render(), BattleScreen);
    const latest = loadSave();
    latest.dragons.fire.level = 7;
    writeSave(latest);
    first.props.onRetryBattle();
    const retry = find(render(), BattleScreen);
    expect(retry.key).not.toBe(first.key);
    expect(retry.props.battleConfig).toEqual(first.props.battleConfig);
    expect(retry.props.save.dragons.fire.level).toBe(7);
    expect(loadSave().stats.battlesWon).toBe(0);
    expect(playMusic).toHaveBeenLastCalledWith('battle', true);
    retry.props.onBattleEnd(false);
    expect(find(render(), OuterGridScreen)).toBeTruthy();
  });

  it('retries the same daily snapshot without rerolling its reward policy', () => {
    navigate('battleSelect');
    const dailyNpc = getDailyChallenge(20260905, { boostRewards: false });
    find(render(), BattleSelectScreen).props.onBeginBattle({ dragonId: 'fire', npcId: dailyNpc.id, dailyNpc });
    const first = find(render(), BattleScreen);
    first.props.onRetryBattle();
    const retry = find(render(), BattleScreen);
    expect(retry.props.battleConfig.dailyNpc).toEqual(dailyNpc);
    expect(retry.key).not.toBe(first.key);
    expect(loadSave().lastDailyCompleted).toBe(0);
  });

  it('starts a fresh Mirror Admin attempt while keeping its scaled phase definitions', () => {
    navigate('singularity');
    find(render(), SingularityScreen).props.onEngageBoss({ dragonId: 'fire', boss: MIRROR_ADMIN, isMirrorAdmin: true });
    const first = find(render(), BattleScreen);
    first.props.onRetryBattle();
    const retry = find(render(), BattleScreen);
    expect(retry.key).not.toBe(first.key);
    expect(retry.props.battleConfig.boss).toEqual(first.props.battleConfig.boss);
    expect(retry.props.battleConfig.isMirrorAdmin).toBe(true);
    expect(playMusic).toHaveBeenLastCalledWith('mirrorAdmin', true);
    expect(loadSave().mirrorAdminDefeated).toBe(false);
    retry.props.onBattleEnd(false);
    expect(find(render(), SingularityScreen)).toBeTruthy();
  });

  it('returns to preparation if the selected guardian is no longer owned', () => {
    navigate('battleSelect');
    find(render(), BattleSelectScreen).props.onBeginBattle({ dragonId: 'fire', npcId: 'firewall_sentinel' });
    const first = find(render(), BattleScreen);
    const latest = loadSave();
    latest.dragons.fire.owned = false;
    writeSave(latest);
    first.props.onRetryBattle();
    expect(find(render(), BattleScreen)).toBeFalsy();
    expect(find(render(), BattleSelectScreen)).toBeTruthy();
  });
});
