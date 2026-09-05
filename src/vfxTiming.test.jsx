import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import VfxOverlay from './VfxOverlay';

// Run the actual component effects against tiny style-only element stand-ins.
// This covers RAF and CSS-animation callbacks without adding a DOM runtime.
const harness = vi.hoisted(() => ({ effects: [], elements: [], callbacks: {}, handlers: [], setPhase: null }));
vi.mock('react', async (importOriginal) => {
  const react = await importOriginal();
  return {
    ...react,
    useEffect(effect) { harness.effects.push(effect); },
    useRef(value) {
      const ref = react.useRef(value);
      if (value === null) {
        ref.current = { style: {} };
        harness.elements.push(ref.current);
      }
      return ref;
    },
    useCallback(callback) { harness.handlers.push(callback); return callback; },
    useState(initial) { return [initial, harness.setPhase]; },
  };
});

vi.mock('./sprites', async (importOriginal) => {
  const sprites = await importOriginal();
  return {
    ...sprites,
    VFX_FRAMES: {
      ...sprites.VFX_FRAMES,
      TEST_SIGNATURE: { signature: { label: 'Test', palette: ['white', 'gold', 'black'], motif: 'anvil-ring', motion: 'rise' } },
    },
  };
});

let pendingFrames;
let nextFrame;
beforeEach(() => {
  harness.effects = [];
  harness.elements = [];
  harness.callbacks = {};
  harness.handlers = [];
  harness.setPhase = vi.fn();
  pendingFrames = new Map();
  nextFrame = 0;
  vi.stubGlobal('requestAnimationFrame', (callback) => {
    pendingFrames.set(++nextFrame, callback);
    return nextFrame;
  });
  vi.stubGlobal('cancelAnimationFrame', (id) => pendingFrames.delete(id));
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

function tick(timestamp) {
  const frames = [...pendingFrames.values()];
  pendingFrames.clear();
  frames.forEach((callback) => callback(timestamp));
}

function renderEffect(vfxKey, onImpact, onComplete, travelMs = 270, impactMs = 220) {
  renderToStaticMarkup(<VfxOverlay vfxKey={vfxKey} element="fire" direction="right-to-left"
    targetSide="left" travelMs={travelMs} impactMs={impactMs} onImpact={onImpact} onComplete={onComplete} />);
  // LegacyVfx registers the slash-end handler before its travel-end handler.
  [harness.callbacks.handleImpactEnd, harness.callbacks.handleTravelEnd] = harness.handlers;
  return harness.effects.at(-1);
}

describe.each(['MAGMA_BREATH', 'TEST_SIGNATURE'])('%s projectile contact', (vfxKey) => {
  it('signals contact at arrival and completes only after the impact burst', () => {
    const onImpact = vi.fn();
    const onComplete = vi.fn();
    const cleanup = renderEffect(vfxKey, onImpact, onComplete)();
    tick(100);
    tick(369);
    expect(onImpact).not.toHaveBeenCalled();
    expect(onComplete).not.toHaveBeenCalled();
    tick(370);
    expect(harness.elements[0].style.left).toBe('18%');
    expect(onImpact).toHaveBeenCalledOnce();
    expect(onComplete).not.toHaveBeenCalled();
    tick(589);
    expect(onImpact).toHaveBeenCalledOnce();
    expect(onComplete).not.toHaveBeenCalled();
    tick(590);
    expect(onComplete).toHaveBeenCalledOnce();
    expect(pendingFrames.size).toBe(0);
    cleanup();
  });

  it('emits both callbacks in order if a delayed frame skips over the burst', () => {
    const order = [];
    const cleanup = renderEffect(vfxKey, () => order.push('impact'), () => order.push('complete'))();
    tick(0);
    tick(1000);
    expect(order).toEqual(['impact', 'complete']);
    tick(2000);
    expect(order).toEqual(['impact', 'complete']);
    cleanup();
  });

  it('resets contact guards on effect restart and rejects cancelled RAF callbacks', () => {
    const onImpact = vi.fn();
    const onComplete = vi.fn();
    const effect = renderEffect(vfxKey, onImpact, onComplete);
    const firstCleanup = effect();
    tick(0);
    tick(270);
    const staleTick = [...pendingFrames.values()][0];
    firstCleanup();
    expect(pendingFrames.size).toBe(0);

    const secondCleanup = effect();
    staleTick(1000);
    expect(onComplete).not.toHaveBeenCalled();
    tick(1000);
    tick(1270);
    expect(onImpact).toHaveBeenCalledTimes(2);
    tick(1490);
    expect(onComplete).toHaveBeenCalledOnce();
    secondCleanup();
  });
});

describe('fallback VFX pacing', () => {
  it('uses the requested travel duration for a basic attack', () => {
    const html = renderToStaticMarkup(<VfxOverlay vfxKey="BASIC_ATTACK" element="neutral" direction="left-to-right"
      targetSide="left" travelMs={135} impactMs={110} onComplete={() => {}} />);
    expect(html).toContain('vfx-travel');
    expect(html).toContain('animation-duration:135ms');
  });

  it('signals basic-attack contact at travel end and completes at slash end', () => {
    const onImpact = vi.fn();
    const onComplete = vi.fn();
    const cleanup = renderEffect('BASIC_ATTACK', onImpact, onComplete)();
    harness.callbacks.handleTravelEnd();
    expect(onImpact).toHaveBeenCalledOnce();
    expect(harness.setPhase).toHaveBeenLastCalledWith('impact');
    expect(onComplete).not.toHaveBeenCalled();
    harness.callbacks.handleTravelEnd();
    harness.callbacks.handleImpactEnd();
    harness.callbacks.handleImpactEnd();
    expect(onImpact).toHaveBeenCalledOnce();
    expect(onComplete).toHaveBeenCalledOnce();
    cleanup();
  });

  it('signals contact before completion for an unknown projectile without a burst', () => {
    const order = [];
    const cleanup = renderEffect('UNKNOWN', () => order.push('impact'), () => order.push('complete'))();
    harness.callbacks.handleTravelEnd();
    harness.callbacks.handleTravelEnd();
    expect(order).toEqual(['impact', 'complete']);
    cleanup();
  });

  it('cleans up legacy callbacks and resets them for a restarted effect', () => {
    const onImpact = vi.fn();
    const onComplete = vi.fn();
    const effect = renderEffect('BASIC_ATTACK', onImpact, onComplete);
    const firstCleanup = effect();
    harness.callbacks.handleTravelEnd();
    firstCleanup();
    harness.callbacks.handleImpactEnd();
    expect(onComplete).not.toHaveBeenCalled();
    const secondCleanup = effect();
    harness.callbacks.handleTravelEnd();
    harness.callbacks.handleImpactEnd();
    expect(onImpact).toHaveBeenCalledTimes(2);
    expect(onComplete).toHaveBeenCalledOnce();
    secondCleanup();
  });

  it('preserves completion when onImpact is omitted', () => {
    const onComplete = vi.fn();
    const cleanup = renderEffect('BASIC_ATTACK', undefined, onComplete)();
    harness.callbacks.handleTravelEnd();
    harness.callbacks.handleImpactEnd();
    expect(onComplete).toHaveBeenCalledOnce();
    cleanup();
  });
});

describe('reduced-motion VFX pacing', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.stubGlobal('window', { matchMedia: () => ({ matches: true }) });
  });

  it.each([
    ['MAGMA_BREATH', true], ['TEST_SIGNATURE', true], ['BASIC_ATTACK', true], ['UNKNOWN', false],
  ])('keeps %s contact and completion on their original beats without RAF or animation events', (key, hasBurst) => {
    const order = [];
    const cleanup = renderEffect(key, () => order.push('impact'), () => order.push('complete'))();
    expect(pendingFrames.size).toBe(0);
    expect(harness.handlers).toHaveLength(0);
    vi.advanceTimersByTime(269);
    expect(order).toEqual([]);
    vi.advanceTimersByTime(1);
    expect(harness.setPhase).toHaveBeenLastCalledWith(true);
    expect(order).toEqual(hasBurst ? ['impact'] : ['impact', 'complete']);
    if (hasBurst) {
      vi.advanceTimersByTime(219);
      expect(order).toEqual(['impact']);
      vi.advanceTimersByTime(1);
    }
    expect(order).toEqual(['impact', 'complete']);
    vi.advanceTimersByTime(1000);
    expect(order).toEqual(['impact', 'complete']);
    cleanup();
  });

  it('preserves 2x speed instead of allowing the CSS reset to complete a basic attack instantly', () => {
    const onImpact = vi.fn();
    const onComplete = vi.fn();
    const cleanup = renderEffect('BASIC_ATTACK', onImpact, onComplete, 135, 110)();
    vi.advanceTimersByTime(134);
    expect(onImpact).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(onImpact).toHaveBeenCalledOnce();
    vi.advanceTimersByTime(109);
    expect(onComplete).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(onComplete).toHaveBeenCalledOnce();
    cleanup();
  });

  it('cancels both callbacks on unmount before contact', () => {
    const onImpact = vi.fn();
    const onComplete = vi.fn();
    const cleanup = renderEffect('MAGMA_BREATH', onImpact, onComplete)();
    vi.advanceTimersByTime(100);
    cleanup();
    vi.advanceTimersByTime(1000);
    expect(onImpact).not.toHaveBeenCalled();
    expect(onComplete).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  it('cancels an old completion when its effect restarts after contact', () => {
    const onImpact = vi.fn();
    const onComplete = vi.fn();
    const effect = renderEffect('TEST_SIGNATURE', onImpact, onComplete);
    const firstCleanup = effect();
    vi.advanceTimersByTime(270);
    expect(onImpact).toHaveBeenCalledOnce();
    firstCleanup();
    const secondCleanup = effect();
    vi.advanceTimersByTime(220);
    expect(onComplete).not.toHaveBeenCalled();
    vi.advanceTimersByTime(50);
    expect(onImpact).toHaveBeenCalledTimes(2);
    vi.advanceTimersByTime(220);
    expect(onComplete).toHaveBeenCalledOnce();
    secondCleanup();
  });

  it('does not complete an effect that its contact callback unmounts', () => {
    const onComplete = vi.fn();
    let cleanup;
    cleanup = renderEffect('BASIC_ATTACK', () => cleanup(), onComplete)();
    vi.advanceTimersByTime(490);
    expect(onComplete).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  it('completes even when a contact callback is not supplied', () => {
    const onComplete = vi.fn();
    const cleanup = renderEffect('BASIC_ATTACK', undefined, onComplete)();
    vi.advanceTimersByTime(490);
    expect(onComplete).toHaveBeenCalledOnce();
    cleanup();
  });

  it.each(['left', 'right'])('places a stationary strip impact frame on the %s target', (targetSide) => {
    const html = renderToStaticMarkup(<VfxOverlay vfxKey="MAGMA_BREATH" element="fire"
      direction="left-to-right" targetSide={targetSide} onComplete={() => {}} />);
    expect(html).toContain('vfx-reduced-impact');
    expect(html).toContain(`left:${targetSide === 'left' ? 18 : 78}%`);
    expect(html).toContain('background-position:-600px 0px');
    expect(html.includes('scaleX(-1)')).toBe(targetSide === 'left');
    expect(html).not.toContain('vfx-travel');
    expect(html).not.toContain('animation');
  });
});
