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
afterEach(() => vi.unstubAllGlobals());

function tick(timestamp) {
  const frames = [...pendingFrames.values()];
  pendingFrames.clear();
  frames.forEach((callback) => callback(timestamp));
}

function renderEffect(vfxKey, onImpact, onComplete) {
  renderToStaticMarkup(<VfxOverlay vfxKey={vfxKey} element="fire" direction="right-to-left"
    targetSide="left" travelMs={270} impactMs={220} onImpact={onImpact} onComplete={onComplete} />);
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
