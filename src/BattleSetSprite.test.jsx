import { renderToStaticMarkup } from 'react-dom/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import BattleSetSprite from './BattleSetSprite';
import { setBattleSpeed } from './battleSpeed';
import { startBattleSpritePlayback } from './battleSpritePlayback';

let images;

beforeEach(() => {
  vi.useFakeTimers();
  images = [];
  vi.stubGlobal('Image', class {
    constructor() { images.push(this); }
  });
});

afterEach(() => {
  setBattleSpeed(1);
  vi.clearAllTimers();
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

function makeCanvas() {
  const ctx = {
    clearRect: vi.fn(), save: vi.fn(), restore: vi.fn(),
    translate: vi.fn(), scale: vi.fn(), drawImage: vi.fn(),
  };
  return { width: 192, height: 192, getContext: () => ctx, ctx };
}

function start(canvas, options = {}) {
  return startBattleSpritePlayback({
    canvas, src: 'fire_idle.webp', cell: 96, frames: 4, pose: 'idle', battlePlayback: true, ...options,
  });
}

function drawnFrames(canvas) {
  return canvas.ctx.drawImage.mock.calls.map((call) => call[1] / 96);
}

describe('battle sheet playback lifecycle', () => {
  it('ignores old load and error callbacks after a different pose is ready', () => {
    const canvas = makeCanvas();
    const stopIdle = start(canvas);
    const oldImage = images[0];
    const staleLoad = oldImage.onload;
    const staleError = oldImage.onerror;
    stopIdle();
    expect(oldImage.onload).toBeNull();
    expect(oldImage.onerror).toBeNull();

    const stopHurt = start(canvas, { src: 'fire_hurt.webp', pose: 'hurt', frames: 2 });
    const hurtImage = images[1];
    hurtImage.onload();
    vi.advanceTimersByTime(120);
    const clearCount = canvas.ctx.clearRect.mock.calls.length;
    staleLoad();
    staleError();
    expect(canvas.ctx.clearRect).toHaveBeenCalledTimes(clearCount);
    expect(canvas.ctx.drawImage.mock.calls.every((call) => call[0] === hurtImage)).toBe(true);
    expect(drawnFrames(canvas)).toEqual([0, 1]);
    vi.advanceTimersByTime(120);
    expect(drawnFrames(canvas)).toEqual([0, 1, 0]);
    stopHurt();
  });

  it('restarts a new pose at frame zero even when its URL stays the same', () => {
    const canvas = makeCanvas();
    const stopAttack = start(canvas, { src: 'shared.webp', pose: 'attack', frames: 6 });
    images[0].onload();
    vi.advanceTimersByTime(360);
    expect(drawnFrames(canvas).at(-1)).toBe(4);
    stopAttack();

    const stopHurt = start(canvas, { src: 'shared.webp', pose: 'hurt', frames: 2 });
    images[1].onload();
    expect(drawnFrames(canvas).at(-1)).toBe(0);
    vi.advanceTimersByTime(120);
    expect(drawnFrames(canvas).at(-1)).toBe(1);
    stopHurt();
  });

  it('cancels pending playback and callbacks when the canvas unmounts', () => {
    const canvas = makeCanvas();
    const stop = start(canvas);
    const image = images[0];
    const lateLoad = image.onload;
    image.onload();
    vi.advanceTimersByTime(160);
    stop();
    const drawsBeforeUnmount = canvas.ctx.drawImage.mock.calls.length;
    lateLoad();
    vi.advanceTimersByTime(5000);
    expect(canvas.ctx.drawImage).toHaveBeenCalledTimes(drawsBeforeUnmount);
    expect(vi.getTimerCount()).toBe(0);
  });

  it('clears a failed current strip without starting an animation', () => {
    const canvas = makeCanvas();
    const stop = start(canvas);
    images[0].onerror();
    expect(canvas.ctx.clearRect).toHaveBeenCalledWith(0, 0, 192, 192);
    vi.advanceTimersByTime(1000);
    expect(canvas.ctx.drawImage).not.toHaveBeenCalled();
    stop();
  });

  it.each([1, 2])('loops the complete attack strip at %i× battle speed', (speed) => {
    setBattleSpeed(speed);
    const canvas = makeCanvas();
    const stop = start(canvas, { pose: 'attack', frames: 6 });
    images[0].onload();
    vi.advanceTimersByTime(540 / speed - 1);
    expect(drawnFrames(canvas)).toEqual([0, 1, 2, 3, 4, 5]);
    vi.advanceTimersByTime(1);
    expect(drawnFrames(canvas)).toEqual([0, 1, 2, 3, 4, 5, 0]);
    stop();
  });

  it('uses the new speed when scheduling the next frame during playback', () => {
    const canvas = makeCanvas();
    const stop = start(canvas, { pose: 'hurt', frames: 2 });
    images[0].onload();
    setBattleSpeed(2);
    vi.advanceTimersByTime(120);
    expect(drawnFrames(canvas)).toEqual([0, 1]);
    vi.advanceTimersByTime(59);
    expect(drawnFrames(canvas)).toEqual([0, 1]);
    vi.advanceTimersByTime(1);
    expect(drawnFrames(canvas)).toEqual([0, 1, 0]);
    stop();
  });

  it('keeps exploration and preview sprites at normal speed after a fast battle', () => {
    setBattleSpeed(2);
    const canvas = makeCanvas();
    const stop = start(canvas, { battlePlayback: false });
    images[0].onload();
    vi.advanceTimersByTime(159);
    expect(drawnFrames(canvas)).toEqual([0]);
    vi.advanceTimersByTime(1);
    expect(drawnFrames(canvas)).toEqual([0, 1]);
    stop();
  });

  it.each([1, 2])('plays faint once and holds the last frame at %i× speed', (speed) => {
    setBattleSpeed(speed);
    const canvas = makeCanvas();
    const stop = start(canvas, { pose: 'faint', frames: 3 });
    images[0].onload();
    vi.advanceTimersByTime(400 / speed);
    expect(drawnFrames(canvas)).toEqual([0, 1, 2]);
    vi.advanceTimersByTime(2000);
    expect(drawnFrames(canvas)).toEqual([0, 1, 2]);
    expect(vi.getTimerCount()).toBe(0);
    stop();
  });

  it('draws crisp square source cells with the requested horizontal flip', () => {
    const canvas = makeCanvas();
    const stop = start(canvas, { flipX: true });
    images[0].onload();
    expect(canvas.ctx.imageSmoothingEnabled).toBe(false);
    expect(canvas.ctx.translate).toHaveBeenCalledWith(192, 0);
    expect(canvas.ctx.scale).toHaveBeenCalledWith(-1, 1);
    expect(canvas.ctx.drawImage).toHaveBeenCalledWith(images[0], 0, 0, 96, 96, 0, 0, 192, 192);
    stop();
  });
});

describe('battle sheet display bounds', () => {
  it.each([
    [320, 250, 250], [192, 150, 150], [448, 350, 350],
    [160, 160, 160], [80, 120, 80], [null, null, 192],
  ])('fits the square strip inside a %s×%s slot', (width, height, expected) => {
    const html = renderToStaticMarkup(<BattleSetSprite src="fire_idle.webp" width={width} height={height} />);
    expect(html).toContain(`width:${expected}px;height:${expected}px`);
    expect(html).toContain('width="192" height="192"');
  });
});
