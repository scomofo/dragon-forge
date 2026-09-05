import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import gsap from 'gsap';
import { battleWait, getBattleSpeed, scaleBattleDuration, setBattleSpeed } from './battleSpeed';
import { getBattlePresentationProfile } from './battlePresentation';

beforeEach(() => { setBattleSpeed(1); vi.useFakeTimers(); });
afterEach(() => { vi.useRealTimers(); setBattleSpeed(1); });

describe('battle clock boundaries', () => {
  it.each(['anticipationMs', 'recoveryMs'])('runs a real profile %s at half time, not quarter time', async key => {
    const event = { action: 'attack', hit: true, damage: 20, effectiveness: 1, targetHp: 40 };
    const normal = getBattlePresentationProfile(event, { power: 40 });
    setBattleSpeed(2);
    const profile = getBattlePresentationProfile(event, { power: 40 });
    const done = vi.fn();
    const wait = battleWait(profile[key]).then(done);
    await vi.advanceTimersByTimeAsync(normal[key] / 4);
    expect(done).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(normal[key] / 4);
    await wait;
    expect(done).toHaveBeenCalledOnce();
  });

  it('scales VFX wall time and leaves GSAP hit-stop with one global speed factor', () => {
    const event = { action: 'attack', hit: true, isCritical: true, damage: 20, effectiveness: 1, targetHp: 40 };
    const normal = getBattlePresentationProfile(event, { power: 80 });
    setBattleSpeed(2);
    const profile = getBattlePresentationProfile(event, { power: 80 });
    expect(scaleBattleDuration(profile.vfxTravelMs)).toBe(normal.vfxTravelMs / 2);
    expect(scaleBattleDuration(profile.vfxImpactMs)).toBe(normal.vfxImpactMs / 2);
    expect(profile.impactPauseMs / gsap.globalTimeline.timeScale()).toBe(normal.impactPauseMs / 2);
  });

  it('keeps fixed waits consistent with profile waits', async () => {
    setBattleSpeed(2);
    const done = vi.fn();
    const wait = battleWait(400).then(done);
    await vi.advanceTimersByTimeAsync(199);
    expect(done).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(1);
    await wait;
    expect(done).toHaveBeenCalledOnce();
  });

  it('normalizes unsupported speed settings and restores normal timing', () => {
    setBattleSpeed(2);
    setBattleSpeed(8);
    expect(getBattleSpeed()).toBe(1);
    expect(scaleBattleDuration(400)).toBe(400);
    expect(gsap.globalTimeline.timeScale()).toBe(1);
  });
});
