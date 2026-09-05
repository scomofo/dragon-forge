import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import gsap from 'gsap';
import DamageNumber from './DamageNumber';

const harness = vi.hoisted(() => ({ effects: [], el: null, setVisible: null }));
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useEffect(effect) { harness.effects.push(effect); },
  useRef() { return { current: harness.el }; },
  useState(initial) { return [initial, harness.setVisible]; },
}));

beforeEach(() => {
  harness.effects = [];
  harness.el = { opacity: 0, x: 0, y: 0, scale: 1 };
  harness.setVisible = vi.fn();
  vi.stubGlobal('window', { matchMedia: () => ({ matches: true }) });
});
afterEach(() => {
  gsap.globalTimeline.getChildren().forEach(animation => animation.kill());
  gsap.ticker.sleep();
  vi.unstubAllGlobals();
});

describe('reduced-motion damage feedback', () => {
  it.each([
    ['critical damage', { damage: 42, hit: true, isCritical: true }, 'CRIT 42', 1],
    ['normal damage', { damage: 9, hit: true }, '9', 0.8],
    ['miss', { damage: 0, hit: false }, 'MISS', 0.6],
    ['status', { damage: 0, hit: true, variant: 'status', label: 'BURN' }, 'BURN', 0.8],
  ])('keeps %s visible for its reading window and completes once', (_name, props, label, duration) => {
    const complete = vi.fn();
    const html = renderToStaticMarkup(<DamageNumber {...props} effectiveness={1}
      position={{ x: 100, y: 80 }} onComplete={complete} />);
    expect(html).toContain(label);
    const cleanup = harness.effects[0]();
    const tl = gsap.globalTimeline.getChildren(false, false, true)[0].pause();
    expect(tl.duration()).toBeCloseTo(duration);
    for (const tween of tl.getChildren()) {
      for (const prop of ['x', 'y', 'scale']) expect(tween.vars).not.toHaveProperty(prop);
      expect(tween.vars.repeat ?? 0).toBe(0);
    }
    tl.time(duration - 0.16);
    expect(harness.el.opacity).toBe(1);
    expect(complete).not.toHaveBeenCalled();
    tl.totalProgress(1);
    expect(complete).toHaveBeenCalledOnce();
    expect(harness.setVisible).toHaveBeenCalledExactlyOnceWith(false);
    cleanup();
  });

  it('cancels completion when unmounted during the reading window', () => {
    const complete = vi.fn();
    renderToStaticMarkup(<DamageNumber damage={10} hit effectiveness={1}
      position={{ x: 100, y: 80 }} onComplete={complete} />);
    const cleanup = harness.effects[0]();
    const tl = gsap.globalTimeline.getChildren(false, false, true)[0];
    const kill = vi.spyOn(tl, 'kill');
    cleanup();
    expect(kill).toHaveBeenCalledOnce();
    expect(gsap.globalTimeline.getChildren()).toHaveLength(0);
    expect(complete).not.toHaveBeenCalled();
  });
});
