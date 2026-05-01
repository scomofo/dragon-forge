export const GAMEPAD_BUTTONS = {
  A: 0,
  B: 1,
  X: 2,
  Y: 3,
  LB: 4,
  RB: 5,
  SELECT: 8,
  START: 9,
  DPAD_UP: 12,
  DPAD_DOWN: 13,
  DPAD_LEFT: 14,
  DPAD_RIGHT: 15,
};

export function normalizeAxis(value, deadzone = 0.45) {
  if (Math.abs(value) < deadzone) return 0;
  return value > 0 ? 1 : -1;
}

export function getPressedGamepadInputs(gamepad, previousButtons = {}, previousAxes = { x: 0, y: 0 }) {
  if (!gamepad) return { buttons: [], axes: { x: 0, y: 0 }, axisPresses: [] };

  const buttons = [];
  Object.entries(GAMEPAD_BUTTONS).forEach(([name, index]) => {
    const pressed = Boolean(gamepad.buttons?.[index]?.pressed);
    if (pressed && !previousButtons[name]) buttons.push(name);
  });

  const axes = {
    x: normalizeAxis(gamepad.axes?.[0] || 0),
    y: normalizeAxis(gamepad.axes?.[1] || 0),
  };
  const axisPresses = [];
  if (axes.x !== 0 && axes.x !== previousAxes.x) axisPresses.push(axes.x > 0 ? 'RIGHT' : 'LEFT');
  if (axes.y !== 0 && axes.y !== previousAxes.y) axisPresses.push(axes.y > 0 ? 'DOWN' : 'UP');

  return { buttons, axes, axisPresses };
}

export function snapshotGamepadButtons(gamepad) {
  return Object.fromEntries(
    Object.entries(GAMEPAD_BUTTONS).map(([name, index]) => [name, Boolean(gamepad?.buttons?.[index]?.pressed)])
  );
}

export function findDirectionalNode(nodes, selectedNodeId, direction) {
  const selected = nodes.find((node) => node.id === selectedNodeId);
  if (!selected) return nodes[0] || null;

  const candidates = nodes
    .filter((node) => node.id !== selectedNodeId)
    .map((node) => ({
      node,
      dx: node.position.x - selected.position.x,
      dy: node.position.y - selected.position.y,
    }))
    .filter(({ dx, dy }) => {
      if (direction === 'LEFT') return dx < -1;
      if (direction === 'RIGHT') return dx > 1;
      if (direction === 'UP') return dy < -1;
      if (direction === 'DOWN') return dy > 1;
      return false;
    })
    .map((entry) => {
      const primary = direction === 'LEFT' || direction === 'RIGHT' ? Math.abs(entry.dx) : Math.abs(entry.dy);
      const secondary = direction === 'LEFT' || direction === 'RIGHT' ? Math.abs(entry.dy) : Math.abs(entry.dx);
      return { ...entry, score: primary + secondary * 1.85 };
    })
    .sort((a, b) => a.score - b.score);

  return candidates[0]?.node || selected;
}
