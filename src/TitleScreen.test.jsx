import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import TitleScreen from './TitleScreen';
import { markIntroSeen } from './persistence';

const control = vi.hoisted(() => ({ states: [], refs: [], effects: [], stateIndex: 0, refIndex: 0, handlers: null }));
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useState(initial) {
    const index = control.stateIndex++;
    if (!(index in control.states)) control.states[index] = typeof initial === 'function' ? initial() : initial;
    return [control.states[index], value => { control.states[index] = typeof value === 'function' ? value(control.states[index]) : value; }];
  },
  useRef(initial) { return control.refs[control.refIndex++] ||= { current: initial }; },
  useCallback: callback => callback,
  useEffect: callback => { control.effects.push(callback); },
}));
vi.mock('./useGamepadController', () => ({ default: handlers => { control.handlers = handlers; return { id: 'test-pad' }; } }));
vi.mock('./persistence', () => ({ markIntroSeen: vi.fn() }));
vi.mock('./soundEngine', () => ({ playSound: vi.fn(), playMusic: vi.fn() }));
vi.mock('./SoundToggle', () => ({ default: () => null }));

function render(onStart, introSeen = false) {
  control.stateIndex = 0;
  control.refIndex = 0;
  control.effects = [];
  const tree = TitleScreen({ onStart, save: { introSeen, dragons: {} } });
  control.effects.forEach(effect => effect());
  return tree;
}

function buttons(tree) {
  if (!tree || typeof tree !== 'object') return [];
  if (Array.isArray(tree)) return tree.flatMap(buttons);
  return [...(tree.type === 'button' ? [tree] : []), ...buttons(tree.props?.children)];
}

beforeEach(() => {
  vi.useFakeTimers();
  vi.clearAllMocks();
  control.states = [];
  control.refs = [];
});
afterEach(() => vi.useRealTimers());

describe('title controller handoff', () => {
  it('skips the boot on one press and starts exactly once on a later confirm', async () => {
    const onStart = vi.fn();
    render(onStart);
    control.handlers.onButtonPress('A');
    control.handlers.onButtonPress('START'); // Same polling frame still only skips.
    expect(onStart).not.toHaveBeenCalled();
    await vi.runAllTimersAsync();
    const tree = render(onStart);
    expect(buttons(tree)).toHaveLength(1);
    expect(buttons(tree)[0].props.style.outline).toContain('#ffcc00');
    control.handlers.onButtonPress('A');
    control.handlers.onButtonPress('START');
    expect(onStart).toHaveBeenCalledTimes(1);
    expect(markIntroSeen).toHaveBeenCalledTimes(1);
  });

  it('lets a returning player start immediately with Start and ignores unrelated buttons', () => {
    const onStart = vi.fn();
    render(onStart, true);
    render(onStart, true);
    control.handlers.onButtonPress('B');
    control.handlers.onButtonPress('X');
    expect(onStart).not.toHaveBeenCalled();
    control.handlers.onButtonPress('START');
    expect(onStart).toHaveBeenCalledTimes(1);
  });

  it('preserves keyboard ownership for sound controls and guards mixed native/controller activation', () => {
    const onStart = vi.fn();
    render(onStart, true);
    const tree = render(onStart, true);
    const event = { target: {}, currentTarget: {}, key: 'Enter', preventDefault: vi.fn() };
    tree.props.onKeyDown(event);
    expect(onStart).not.toHaveBeenCalled();
    expect(event.preventDefault).not.toHaveBeenCalled();
    buttons(tree)[0].props.onClick({ stopPropagation: vi.fn() });
    control.handlers.onButtonPress('A');
    expect(onStart).toHaveBeenCalledTimes(1);
  });
});
