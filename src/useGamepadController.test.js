import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import useGamepadController from './useGamepadController';

const hooks = vi.hoisted(() => ({ refs: [], states: [], effects: [], pending: [], refIndex: 0, stateIndex: 0, effectIndex: 0 }));

// Run the real polling hook with retained hooks and a controllable browser
// frame queue. No physical controller or DOM is simulated by React itself.
vi.mock('react', () => ({
  useRef(initial) { return hooks.refs[hooks.refIndex++] ||= { current: initial }; },
  useState(initial) {
    const index = hooks.stateIndex++;
    if (!(index in hooks.states)) hooks.states[index] = initial;
    return [hooks.states[index], value => { hooks.states[index] = typeof value === 'function' ? value(hooks.states[index]) : value; }];
  },
  useEffect(effect, deps) {
    const index = hooks.effectIndex++;
    const previous = hooks.effects[index];
    if (!previous || deps.some((value, i) => !Object.is(value, previous.deps[i]))) {
      hooks.pending.push(() => {
        previous?.cleanup?.();
        hooks.effects[index] = { deps, cleanup: effect() };
      });
    }
  },
}));

let pads;
let frames;
let nextFrame;
let handlers;

function pad(pressed = [], axes = [0, 0], id = 'standard-pad', index = 0) {
  return { id, index, buttons: Array.from({ length: 16 }, (_, i) => ({ pressed: pressed.includes(i) })), axes };
}

function render(enabled = true, callbacks = handlers) {
  hooks.refIndex = hooks.stateIndex = hooks.effectIndex = 0;
  hooks.pending = [];
  const connected = useGamepadController(callbacks, enabled);
  for (const effect of hooks.pending) effect();
  return connected;
}

function tick() {
  const pending = [...frames.values()];
  frames.clear();
  for (const callback of pending) callback();
}

function unmount() {
  for (const effect of hooks.effects) effect?.cleanup?.();
}

beforeEach(() => {
  Object.assign(hooks, { refs: [], states: [], effects: [], pending: [], refIndex: 0, stateIndex: 0, effectIndex: 0 });
  pads = [pad()];
  frames = new Map();
  nextFrame = 0;
  handlers = { onButtonPress: vi.fn(), onDirectionPress: vi.fn() };
  vi.stubGlobal('window', {
    requestAnimationFrame: vi.fn(callback => { const id = nextFrame++; frames.set(id, callback); return id; }),
    cancelAnimationFrame: vi.fn(id => frames.delete(id)),
  });
  vi.stubGlobal('navigator', { getGamepads: () => pads });
});

afterEach(() => { unmount(); vi.unstubAllGlobals(); });

describe('controller screen handoffs', () => {
  it('observes held Confirm, Start, d-pad and stick on arrival without activating them', () => {
    pads = [pad([0, 9, 13], [0.8, -0.8])];
    render();
    tick();
    tick();
    expect(render()).toEqual({ id: 'standard-pad', index: 0 });
    expect(handlers.onButtonPress).not.toHaveBeenCalled();
    expect(handlers.onDirectionPress).not.toHaveBeenCalled();
    pads = [pad()];
    tick();
    pads = [pad([0, 9, 13], [0.8, -0.8])];
    tick();
    expect(handlers.onButtonPress.mock.calls.map(([button]) => button)).toEqual(['A', 'START']);
    expect(handlers.onDirectionPress.mock.calls.map(([direction]) => direction)).toEqual(['DOWN', 'RIGHT', 'UP']);
    tick();
    expect(handlers.onButtonPress).toHaveBeenCalledTimes(2);
  });

  it('accepts a new press after a neutral first frame without an extra delay', () => {
    render();
    tick();
    pads = [pad([1])];
    tick();
    expect(handlers.onButtonPress).toHaveBeenCalledExactlyOnceWith('B', pads[0]);
  });

  it('primes again when an overlay returns control to the screen', () => {
    render();
    tick();
    render(false);
    expect(frames.size).toBe(0);
    pads = [pad([0])];
    render(true);
    tick();
    expect(handlers.onButtonPress).not.toHaveBeenCalled();
    pads = [pad()];
    tick();
    pads = [pad([0])];
    tick();
    expect(handlers.onButtonPress).toHaveBeenCalledTimes(1);
  });

  it('primes held input after disconnect and after switching the primary controller', () => {
    render();
    tick();
    pads = [];
    tick();
    expect(render()).toBeNull();
    pads = [pad([0])];
    tick();
    expect(handlers.onButtonPress).not.toHaveBeenCalled();
    pads = [pad()];
    tick();
    pads = [null, pad([0], [0.8, 0], 'other-pad', 1)];
    tick();
    expect(render()).toEqual({ id: 'other-pad', index: 1 });
    expect(handlers.onButtonPress).not.toHaveBeenCalled();
    expect(handlers.onDirectionPress).not.toHaveBeenCalled();
    pads = [null, pad([], [0, 0], 'other-pad', 1)];
    tick();
    pads = [null, pad([0], [0.8, 0], 'other-pad', 1)];
    tick();
    expect(handlers.onButtonPress).toHaveBeenCalledTimes(1);
    expect(handlers.onDirectionPress).toHaveBeenCalledExactlyOnceWith('RIGHT', pads[1]);
  });

  it('updates handlers without restarting the poll or repeating a held press', () => {
    render();
    tick();
    pads = [pad([0])];
    tick();
    const replacement = { onButtonPress: vi.fn() };
    render(true, replacement);
    tick();
    expect(replacement.onButtonPress).not.toHaveBeenCalled();
    pads = [pad()];
    tick();
    pads = [pad([0])];
    tick();
    expect(replacement.onButtonPress).toHaveBeenCalledExactlyOnceWith('A', pads[0]);
    expect(handlers.onButtonPress).toHaveBeenCalledTimes(1);
  });

  it('cancels even frame zero and makes a queued callback inert after unmount', () => {
    render();
    const queued = frames.get(0);
    unmount();
    expect(window.cancelAnimationFrame).toHaveBeenCalledWith(0);
    pads = [pad([0])];
    queued();
    expect(frames.size).toBe(0);
    expect(handlers.onButtonPress).not.toHaveBeenCalled();
  });

  it('continues safely when the browser has no Gamepad API', () => {
    vi.stubGlobal('navigator', {});
    render();
    tick();
    expect(render()).toBeNull();
    expect(frames.size).toBe(1);
  });
});
