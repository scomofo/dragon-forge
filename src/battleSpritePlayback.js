import { normalizeBattlePose, POSE_FRAME_DURATIONS } from './battleSets';
import { scaleBattleDuration } from './battleSpeed';

// A sheet cell is square, even when its parent reserves a portrait-shaped slot.
export function getBattleSpriteSize(cell, width, height) {
  const bounds = [width, height].filter((value) => Number.isFinite(value) && value > 0);
  return bounds.length ? Math.min(...bounds) : cell * 2;
}

// One lifetime owns one image request and one frame clock. React replaces this
// lifetime on pose/source changes, so a delayed image can never revive an old
// pose or erase the next actor. Canvas/Image are the only browser dependencies.
export function startBattleSpritePlayback({ canvas, src, cell, frames, pose, flipX = false, battlePlayback = false }) {
  const ctx = canvas?.getContext('2d');
  if (!ctx) return () => {};

  const normalized = normalizeBattlePose(pose);
  const count = Math.max(1, Math.floor(Number(frames) || 1));
  const img = new Image();
  let active = true;
  let loaded = false;
  let frame = 0;
  let timer = null;

  function drawFrame() {
    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.save();
    if (flipX) {
      ctx.translate(canvas.width, 0);
      ctx.scale(-1, 1);
    }
    ctx.drawImage(img, frame * cell, 0, cell, cell, 0, 0, canvas.width, canvas.height);
    ctx.restore();
  }

  function scheduleFrame() {
    if (count === 1 || (normalized === 'faint' && frame === count - 1)) return;
    const duration = POSE_FRAME_DURATIONS[normalized];
    timer = setTimeout(() => {
      if (!active) return;
      frame = normalized === 'faint' ? Math.min(frame + 1, count - 1) : (frame + 1) % count;
      drawFrame();
      scheduleFrame();
    }, battlePlayback ? scaleBattleDuration(duration) : duration);
  }

  img.crossOrigin = 'anonymous';
  img.onload = () => {
    if (!active || loaded) return;
    loaded = true;
    drawFrame();
    scheduleFrame();
  };
  img.onerror = () => {
    if (!active) return;
    clearTimeout(timer);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  };
  img.src = src;

  return () => {
    active = false;
    img.onload = null;
    img.onerror = null;
    clearTimeout(timer);
  };
}
