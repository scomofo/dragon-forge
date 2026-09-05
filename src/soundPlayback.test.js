import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { createAudioContext } from './test/audioContext';

let engine;
let audios;
let ctx;

beforeEach(async () => {
  vi.resetModules();
  vi.useFakeTimers();
  audios = [];
  ctx = createAudioContext();
  vi.stubGlobal('localStorage', { getItem: vi.fn().mockReturnValue(null), setItem: vi.fn() });
  vi.stubGlobal('window', { AudioContext: function () { return ctx; } });
  vi.stubGlobal('Audio', class {
    constructor(src) { this.src = src; this.volume = 1; this.paused = true; audios.push(this); }
    play() { this.paused = false; return Promise.resolve(); }
    pause() { this.paused = true; }
  });
  engine = await import('./soundEngine');
});

afterEach(() => {
  engine.stopMusic();
  vi.clearAllTimers();
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe('music controls', () => {
  it('updates a playing MP3 immediately and cancels a fade that could undo volume zero', () => {
    engine.playMusic('title');
    vi.advanceTimersByTime(70);
    engine.setMusicVolume(0);
    vi.advanceTimersByTime(1000);
    expect(audios[0].volume).toBe(0);
    engine.setMusicVolume(0.8);
    expect(audios[0].volume).toBe(0.8);
  });

  it('does not let an old fade-out pause a cached track that was selected again', () => {
    engine.playMusic('title', true);
    engine.playMusic('battle');
    vi.advanceTimersByTime(100);
    engine.playMusic('title');
    vi.advanceTimersByTime(1000);
    expect(audios).toHaveLength(2);
    expect(audios[0].paused).toBe(false);
    expect(audios[0].volume).toBe(0.5);
    expect(audios[1].paused).toBe(true);
    expect(engine.getCurrentTrack()).toBe('title');
  });

  it('mutes immediately, remembers navigation while muted, and resumes the destination', () => {
    engine.playMusic('title');
    engine.toggleMute();
    expect(audios[0].paused).toBe(true);
    expect(vi.getTimerCount()).toBe(0);
    engine.playMusic('battle');
    expect(audios).toHaveLength(1);
    engine.toggleMute();
    expect(audios[1].paused).toBe(false);
    expect(engine.getCurrentTrack()).toBe('battle');
    expect(engine.getSoundPreferences().musicVolume).toBe(0.5);
  });

  it('does not revive battle music after a victory stopped it while muted', () => {
    engine.playMusic('battle', true);
    engine.toggleMute();
    engine.stopMusic();
    engine.toggleMute();
    expect(engine.getCurrentTrack()).toBe(null);
    expect(audios.every(audio => audio.paused)).toBe(true);
  });

  it('ends all outgoing fades on an immediate switch', () => {
    engine.playMusic('title');
    engine.playMusic('battle');
    engine.playMusic('select', true);
    vi.advanceTimersByTime(1000);
    expect(audios.map(audio => audio.paused)).toEqual([true, true, false]);
    expect(vi.getTimerCount()).toBe(0);
  });

  it('drives procedural beds with live volume and mute/resume', () => {
    // P2: mirrorAdmin is now an authored asset; forge remains the canonical
    // procedural bed for exercising the WebAudio path.
    engine.playMusic('forge', true);
    expect(engine.getMusicDefinition('forge').source).toBe('procedural');
    expect(ctx.nodes.filter(node => node.kind === 'oscillator').map(node => node.frequency.value)).toEqual([55, 82, 110]);
    engine.setMusicVolume(0.8);
    expect(ctx.nodes[0].gain.value).toBeCloseTo(0.16);
    const nodeCount = ctx.nodes.length;
    engine.playMusic('forge');
    expect(ctx.nodes).toHaveLength(nodeCount);
    engine.toggleMute();
    expect(ctx.nodes.every(node => node.disconnect.mock.calls.length === 1)).toBe(true);
    expect(vi.getTimerCount()).toBe(0);
    engine.toggleMute();
    expect(ctx.nodes.length).toBeGreaterThan(nodeCount);
    engine.stopMusic();
    expect(vi.getTimerCount()).toBe(0);
  });

  it('cleans up procedural pads and pending arpeggio notes on a screen change', () => {
    engine.playMusic('forge');
    vi.advanceTimersByTime(1400);
    const procNodes = [...ctx.nodes];
    engine.playMusic('battle', true);
    expect(procNodes.every(node => node.disconnect.mock.calls.length === 1)).toBe(true);
    expect(vi.getTimerCount()).toBe(0);
  });

  it('ignores unknown track names without interrupting the current track', () => {
    engine.playMusic('title', true);
    engine.playMusic('typo');
    expect(engine.getCurrentTrack()).toBe('title');
    expect(audios[0].paused).toBe(false);
  });

  it('keeps preference subscribers in sync even when storage is unavailable', () => {
    const listener = vi.fn();
    const unsubscribe = engine.subscribeSoundPreferences(listener);
    localStorage.setItem.mockImplementation(() => { throw new Error('Storage disabled'); });
    engine.setSfxVolume(0.2);
    engine.setMusicVolume(Number.NaN);
    expect(engine.getSoundPreferences()).toEqual({ muted: false, sfxVolume: 0.2, musicVolume: 0.5 });
    expect(listener).toHaveBeenCalledTimes(2);
    unsubscribe();
    engine.setMusicVolume(1);
    expect(listener).toHaveBeenCalledTimes(2);
  });

  it.each(['null', '{"musicVolume":9,"sfxVolume":-2,"muted":"false"}'])('sanitizes malformed saved preferences: %s', async raw => {
    vi.resetModules();
    localStorage.getItem.mockReturnValue(raw);
    const restored = await import('./soundEngine');
    const prefs = restored.getSoundPreferences();
    expect(prefs.muted).toBe(false);
    expect(prefs.musicVolume).toBeGreaterThanOrEqual(0);
    expect(prefs.musicVolume).toBeLessThanOrEqual(1);
    expect(prefs.sfxVolume).toBeGreaterThanOrEqual(0);
    expect(prefs.sfxVolume).toBeLessThanOrEqual(1);
  });
});
