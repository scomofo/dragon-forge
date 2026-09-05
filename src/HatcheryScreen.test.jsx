import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import HatcheryScreen from './HatcheryScreen';
import { PULL_COST } from './gameData';
import { writeSave, trackStat } from './persistence';

const control = vi.hoisted(() => ({ states: [], refs: [], stateIndex: 0, refIndex: 0, save: null }));

// The node test environment has no DOM. Keep hook state across renders and
// exercise the screen's real click handlers, async hatch, and pull engine.
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useState(initial) {
    const index = control.stateIndex++;
    if (!(index in control.states)) control.states[index] = typeof initial === 'function' ? initial() : initial;
    return [control.states[index], value => {
      control.states[index] = typeof value === 'function' ? value(control.states[index]) : value;
    }];
  },
  useRef(initial) {
    const index = control.refIndex++;
    return control.refs[index] ||= { current: initial };
  },
  useCallback: callback => callback,
}));

vi.mock('./persistence', () => ({
  loadSave: () => structuredClone(control.save),
  writeSave: vi.fn(save => { control.save = structuredClone(save); return true; }),
  trackStat: vi.fn(),
  applyDragonXp: vi.fn(),
}));
vi.mock('./soundEngine', () => ({ playSound: vi.fn() }));
vi.mock('./animationEngine', () => ({ eggBurst: vi.fn() }));
vi.mock('./NavBar', () => ({ default: () => null }));
vi.mock('./DragonSprite', () => ({ default: () => null }));
vi.mock('./EggSprite', () => ({ default: () => null }));

function render(onNavigate = vi.fn()) {
  control.stateIndex = 0;
  control.refIndex = 0;
  return HatcheryScreen({ save: control.save, refreshSave: vi.fn(), onNavigate });
}

function nodes(tree, predicate) {
  if (!tree || typeof tree !== 'object') return [];
  if (Array.isArray(tree)) return tree.flatMap(child => nodes(child, predicate));
  return [...(predicate(tree) ? [tree] : []), ...nodes(tree.props?.children, predicate)];
}

function byClass(tree, className) {
  return nodes(tree, node => node.props?.className === className);
}

function click(tree, node) {
  const event = { stopPropagation: vi.fn() };
  const result = node.props.onClick(event);
  if (!event.stopPropagation.mock.calls.length) byClass(tree, 'hatchery-content')[0].props.onClick();
  return result;
}

beforeEach(() => {
  vi.useFakeTimers();
  vi.clearAllMocks();
  vi.spyOn(Math, 'random').mockReturnValue(0.2);
  control.states = [];
  control.refs = [];
  control.save = {
    dragons: {
      fire: { owned: true, level: 1, xp: 0 },
      shadow: { owned: false, level: 1, xp: 0 },
      void: { owned: false, level: 1, xp: 0 },
    },
    pityCounter: 0, dataScraps: PULL_COST * 30, inventory: {}, defeatedNpcs: [],
  };
});

afterEach(() => { vi.useRealTimers(); vi.restoreAllMocks(); });

describe('hatchery handoff and paid-pull controls', () => {
  it('offers a native Outer Grid action after the first hatch and keeps it after dismissing the reveal', async () => {
    control.save.dragons.fire.owned = false;
    control.save.dataScraps = 0;
    let tree = render();
    expect(byClass(tree, 'hatchery-adventure-btn')).toHaveLength(0);
    click(tree, byClass(tree, 'hatchery-text-btn')[0]);
    tree = render();
    const hatch = click(tree, byClass(tree, 'pull-btn')[0]);
    expect(byClass(render(), 'hatchery-adventure-btn')).toHaveLength(0);
    await vi.runAllTimersAsync();
    await hatch;

    const onNavigate = vi.fn();
    tree = render(onNavigate);
    const adventure = byClass(tree, 'hatchery-adventure-btn')[0];
    expect(adventure.type).toBe('button');
    click(tree, adventure);
    expect(onNavigate).toHaveBeenCalledExactlyOnceWith('outerGrid');
    expect(control.save.dataScraps).toBe(0);
    expect(byClass(render(), 'reveal-result')).toHaveLength(1);
    click(tree, byClass(tree, 'hatchery-text-btn')[0]);
    expect(byClass(render(), 'hatchery-adventure-btn')).toHaveLength(1);
    control.save.defeatedNpcs = ['firewall_sentinel'];
    expect(byClass(render(), 'hatchery-adventure-btn')).toHaveLength(0);
  });

  it('charges a repeat pull once and keeps its animation active when clicked from the previous reveal', async () => {
    let tree = render();
    const first = click(tree, byClass(tree, 'pull-btn')[0]);
    await vi.runAllTimersAsync();
    await first;
    tree = render();
    expect(byClass(tree, 'reveal-result')).toHaveLength(1);

    const repeatButton = byClass(tree, 'pull-btn')[0];
    const repeat = click(tree, repeatButton);
    // A second event can arrive before React replaces the button. The ref
    // must reject it even though this closure still has the REVEAL phase.
    await click(tree, repeatButton);
    expect(writeSave).toHaveBeenCalledTimes(2);
    expect(control.save.dataScraps).toBe(PULL_COST * 28);
    expect(byClass(render(), 'pull-btn')).toHaveLength(0);
    expect(byClass(render(), 'hatchery-text-btn')[0].props.children).toBe('SKIP HATCH ANIMATION');
    await vi.runAllTimersAsync();
    await repeat;
    expect(byClass(render(), 'reveal-result')).toHaveLength(1);
  });

  it('shares the in-flight lock across single and ten-pull buttons until the grid is ready', async () => {
    let tree = render();
    const [singleButton, tenButton] = byClass(tree, 'pull-btn');
    const tenPull = click(tree, tenButton);
    await click(tree, singleButton);
    await click(tree, tenButton);
    expect(writeSave).toHaveBeenCalledTimes(1);
    expect(trackStat).toHaveBeenCalledExactlyOnceWith('totalPulls', 10);
    expect(control.save.dataScraps).toBe(PULL_COST * 20);

    // Finish the first hatch but stop in the half-second reveal before GRID.
    await vi.advanceTimersByTimeAsync(3200);
    tree = render();
    expect(byClass(tree, 'pull-btn')).toHaveLength(2);
    expect(byClass(tree, 'pull-btn').every(button => button.props.disabled)).toBe(true);
    byClass(tree, 'hatchery-content')[0].props.onClick();
    await click(tree, singleButton);
    expect(writeSave).toHaveBeenCalledTimes(1);
    await vi.runAllTimersAsync();
    await tenPull;
    expect(byClass(render(), 'pull-grid')).toHaveLength(1);
    expect(byClass(render(), 'pull-btn').every(button => !button.props.disabled)).toBe(true);
  });

  it('uses the latest save to decide whether a hatch is still free', async () => {
    control.save.dragons.fire.owned = false;
    const tree = render();
    control.save.dragons.fire.owned = true;
    control.save.dataScraps = 0;
    await click(tree, byClass(tree, 'pull-btn')[0]);
    expect(writeSave).not.toHaveBeenCalled();
    expect(trackStat).not.toHaveBeenCalled();
  });
});
