export const FORGE_STEP = 2;
export const FORGE_BOUNDS = {
  minX: 4,
  maxX: 96,
  minY: 20,
  maxY: 92,
};

const KEY_DIRECTIONS = {
  arrowup: 'up',
  w: 'up',
  arrowdown: 'down',
  s: 'down',
  arrowleft: 'left',
  a: 'left',
  arrowright: 'right',
  d: 'right',
};

const GAMEPAD_DIRECTIONS = {
  UP: 'up',
  DOWN: 'down',
  LEFT: 'left',
  RIGHT: 'right',
};

export function clampSkyePos(pos) {
  return {
    x: Math.max(FORGE_BOUNDS.minX, Math.min(FORGE_BOUNDS.maxX, pos.x)),
    y: Math.max(FORGE_BOUNDS.minY, Math.min(FORGE_BOUNDS.maxY, pos.y)),
  };
}

export function moveSkye(pos, direction, step = FORGE_STEP) {
  const delta = {
    up: { x: 0, y: -step },
    down: { x: 0, y: step },
    left: { x: -step, y: 0 },
    right: { x: step, y: 0 },
  }[direction] || { x: 0, y: 0 };

  return clampSkyePos({ x: pos.x + delta.x, y: pos.y + delta.y });
}

export function getMovementDirection(key) {
  return KEY_DIRECTIONS[String(key).toLowerCase()] || null;
}

export function getGamepadMovementDirection(direction) {
  return GAMEPAD_DIRECTIONS[direction] || null;
}

export function isForgeInteractKey(key) {
  return key === 'Enter' || key === ' ' || String(key).toLowerCase() === 'e';
}

export function isForgeCancelKey(key) {
  return key === 'Escape' || key === 'Backspace';
}
