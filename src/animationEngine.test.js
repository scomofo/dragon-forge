import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import gsap from 'gsap';
import {
  prefersReducedMotion, criticalHit, zoomPunch, targetKnockback, npcLunge,
  playerLunge, hitSquash, shieldUp, shieldDeflect, shieldDismiss,
  shatterKO, statusAuraApply, eggBurst,
} from './animationEngine';

// Exercise real GSAP completion callbacks against small element stand-ins. No
// rendering is simulated: this verifies timing, target properties, and cleanup.
function element() {
  const node = {
    style: {
      opacity: '',
      setProperty(key, value) { this[key] = value; },
      getPropertyValue(key) { return this[key]; },
    },
    opacity: 1, filter: '', scale: 1, scaleX: 1, scaleY: 1,
    x: 0, y: 0, rotation: 0,
    children: [],
    appendChild(child) { this.children.push(child); child.parentElement = this; },
    querySelector: vi.fn(() => null),
    remove: vi.fn(),
  };
  return node;
}

function tweenVars() {
  return gsap.globalTimeline.getChildren(true, true, false).map(tween => tween.vars);
}

function expectStationary(vars = tweenVars()) {
  for (const value of vars) {
    for (const prop of ['x', 'y', 'scale', 'scaleX', 'scaleY', 'rotation']) {
      expect(value).not.toHaveProperty(prop);
    }
    expect(value.repeat ?? 0).toBeGreaterThanOrEqual(0);
  }
}

beforeEach(() => {
  vi.stubGlobal('window', { matchMedia: vi.fn(() => ({ matches: true })) });
  vi.stubGlobal('document', { createElement: vi.fn(element) });
});

afterEach(() => {
  gsap.globalTimeline.getChildren().forEach(animation => animation.kill());
  gsap.ticker.sleep();
  vi.unstubAllGlobals();
});

describe('reduced-motion animation contracts', () => {
  it('handles SSR and browsers without matchMedia', () => {
    vi.stubGlobal('window', undefined);
    expect(prefersReducedMotion()).toBe(false);
    vi.stubGlobal('window', {});
    expect(prefersReducedMotion()).toBe(false);
  });

  it.each([
    ['zoom punch', zoomPunch, 0.3],
    ['knockback', targetKnockback, 0.28],
    ['NPC lunge', npcLunge, 0.56],
    ['player lunge', playerLunge, 0.35],
    ['hit squash', hitSquash, 0.15],
  ])('keeps %s awaitable without moving the target', (_name, animate, duration) => {
    const target = element();
    const complete = vi.fn();
    const tl = animate(target).pause();
    tl.eventCallback('onComplete', complete);
    expect(tl.duration()).toBeCloseTo(duration);
    expectStationary();
    expect(complete).not.toHaveBeenCalled();
    tl.totalProgress(1);
    expect(complete).toHaveBeenCalledOnce();
    expect(target.x).toBe(0);
    expect(target.scale).toBe(1);
  });

  it('keeps critical-hit completion and its contact pause without arena flash or zoom', () => {
    const complete = vi.fn();
    const tl = criticalHit(element(), element()).pause();
    tl.eventCallback('onComplete', complete);
    expect(tl.duration()).toBeCloseTo(0.4);
    expect(tl.getChildren().some(child => child.data === 'isPause')).toBe(true);
    expectStationary();
    expect(tweenVars().some(vars => 'filter' in vars)).toBe(false);
    tl.totalProgress(1);
    expect(complete).toHaveBeenCalledOnce();
    expect(document.createElement).not.toHaveBeenCalled();
  });

  it('keeps the visible shield and dismisses it without perpetual breathing, sparks, or distortion', () => {
    const target = element();
    const shield = shieldUp(target, 'fire');
    expect(shield.element.className).toBe('shield-aegis');
    expect(shield.element.innerHTML).toContain('shield-dome');
    expect(shield.timeline.totalDuration()).toBeCloseTo(0.28);
    shield.timeline.totalProgress(1);
    expect(shield.element.opacity).toBeCloseTo(0.82);
    shieldDeflect(shield.element, target).totalProgress(1);
    expect(target.children).toHaveLength(1);
    expect(shield.element.children).toHaveLength(0);
    expectStationary();
    const kill = vi.spyOn(shield.timeline, 'kill');
    const dismiss = shieldDismiss(shield.element, shield.timeline);
    expect(kill).toHaveBeenCalledOnce();
    expect(dismiss.vars).not.toHaveProperty('scale');
    dismiss.totalProgress(1);
    expect(shield.element.remove).toHaveBeenCalledOnce();
  });

  it('fades a KO to the same hidden state and restores its prior inline opacity', () => {
    const sprite = element();
    sprite.style.opacity = '0.9';
    const complete = vi.fn();
    const tl = shatterKO(sprite, 'fire').pause();
    tl.eventCallback('onComplete', complete);
    expect(sprite.style.visibility).toBeUndefined();
    expectStationary();
    tl.totalProgress(1);
    expect(sprite.style.visibility).toBe('hidden');
    expect(sprite.style.opacity).toBe('0.9');
    expect(complete).toHaveBeenCalledOnce();
    expect(document.createElement).not.toHaveBeenCalled();
  });

  it.each(['fire', 'storm', 'venom'])('preserves the %s status tint without looping particles or pulses', status => {
    const aura = statusAuraApply(element(), status);
    expect(aura.timelines).toHaveLength(1);
    expect(aura.timelines[0].vars.filter).toBeTruthy();
    expect(aura.particles).toHaveLength(0);
    expectStationary();
    expect(document.createElement).not.toHaveBeenCalled();
    const kill = vi.spyOn(aura.timelines[0], 'kill');
    aura.kill();
    expect(kill).toHaveBeenCalledOnce();
  });

  it('marks a hatch with one local colored halo that cleans itself up, leaving reveal timing to the caller', () => {
    const container = element();
    expect(eggBurst(container, 'fire')).toBeUndefined();
    expect(container.children).toHaveLength(1);
    const halo = container.children[0];
    expect(halo.style.border).toContain('solid');
    expect(halo.style.background).toBeUndefined();
    expect(container.querySelector).not.toHaveBeenCalled();
    expectStationary();
    gsap.getTweensOf(halo)[0].totalProgress(1);
    expect(halo.remove).not.toHaveBeenCalled();
    expectStationary();
    gsap.getTweensOf(halo)[0].totalProgress(1);
    expect(halo.remove).toHaveBeenCalledOnce();
  });

  it('keeps the normal zoom when the preference is off', () => {
    window.matchMedia.mockReturnValue({ matches: false });
    const tl = zoomPunch(element()).pause();
    expect(tl.getChildren()[0].vars.scale).toBe(1.06);
    expect(tl.getChildren()[0].vars.x).toBe(-15);
    expect(tl.duration()).toBeCloseTo(0.3);
  });
});
