import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { startScore } from './scorePlayer';
import { MUSIC_SCORES, getScoreDuration } from './musicScores';
import { createAudioContext } from './test/audioContext';

describe('score playback lifecycle', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => { vi.clearAllTimers(); vi.useRealTimers(); });

  it('schedules on the audio clock and disconnects every queued voice on stop', () => {
    const ctx = createAudioContext();
    ctx.currentTime = 12;
    const player = startScore(ctx, MUSIC_SCORES.mirrorAdmin, 0.5);
    const master = ctx.nodes[0];
    expect(master.gain.value).toBeCloseTo(0.17);
    const voices = ctx.nodes.filter(node => node.kind === 'oscillator');
    expect(voices.length).toBeGreaterThan(0);
    expect(voices.every(node => node.start.mock.calls[0][0] >= 12)).toBe(true);
    player.setVolume(0);
    expect(master.gain.value).toBe(0);
    player.stop();
    player.stop();
    expect(ctx.nodes.every(node => node.disconnect.mock.calls.length === 1)).toBe(true);
    expect(vi.getTimerCount()).toBe(0);
  });

  it('releases completed voices instead of retaining an entire play session', () => {
    const ctx = createAudioContext();
    const player = startScore(ctx, MUSIC_SCORES.heartforge, 0.5);
    const voice = ctx.nodes.find(node => node.kind === 'oscillator');
    voice.onended();
    expect(voice.disconnect).toHaveBeenCalledTimes(1);
    player.stop();
    expect(voice.disconnect).toHaveBeenCalledTimes(1);
  });

  it('crosses the loop boundary without double-playing the opening notes', () => {
    const ctx = createAudioContext();
    const score = { bpm: 60, beats: 1, gain: 1, loop: true,
      events: [{ beat: 0, pitch: 60, duration: 0.2, velocity: 1, voice: 'lead' }] };
    const player = startScore(ctx, score, 0.5);
    ctx.currentTime = 0.95;
    vi.advanceTimersByTime(25);
    ctx.currentTime = 1.05;
    vi.advanceTimersByTime(25);
    const starts = ctx.nodes.filter(node => node.kind === 'oscillator').map(node => node.start.mock.calls[0][0]);
    expect(starts).toEqual([0.03, 1.03]);
    player.stop();
  });

  it('skips missed music after a long background pause without a catch-up burst', () => {
    const ctx = createAudioContext();
    const score = MUSIC_SCORES.mirrorAdmin;
    const player = startScore(ctx, score, 0.5);
    const before = ctx.nodes.length;
    ctx.currentTime = 0.03 + getScoreDuration(score) * 10 + 16 * 60 / score.bpm;
    vi.advanceTimersByTime(25);
    const newVoices = ctx.nodes.slice(before).filter(node => node.kind === 'oscillator');
    expect(newVoices.length).toBeGreaterThan(0);
    expect(newVoices.length).toBeLessThanOrEqual(8);
    expect(newVoices.every(node => node.start.mock.calls[0][0] >= ctx.currentTime)).toBe(true);
    player.stop();
  });

  it('ends a one-shot score once and clears its scheduler', () => {
    const ctx = createAudioContext();
    const onEnded = vi.fn();
    const score = { ...MUSIC_SCORES.heartforge, loop: false };
    startScore(ctx, score, 0.5, { onEnded });
    ctx.currentTime = getScoreDuration(score) + 1;
    vi.advanceTimersByTime(50);
    expect(onEnded).toHaveBeenCalledTimes(1);
    expect(vi.getTimerCount()).toBe(0);
  });
});
