import { describe, expect, test } from 'vitest';
import { findDirectionalNode, getPressedGamepadInputs, normalizeAxis } from './gamepadInput';

describe('gamepad input helpers', () => {
  test('normalizes analog stick drift with a deadzone', () => {
    expect(normalizeAxis(0.2)).toBe(0);
    expect(normalizeAxis(-0.6)).toBe(-1);
    expect(normalizeAxis(0.7)).toBe(1);
  });

  test('reports button and axis edge presses', () => {
    const gamepad = {
      buttons: [{ pressed: true }, { pressed: false }],
      axes: [0.7, -0.8],
    };

    expect(getPressedGamepadInputs(gamepad).buttons).toContain('A');
    expect(getPressedGamepadInputs(gamepad).axisPresses).toEqual(['RIGHT', 'UP']);
  });

  test('finds the closest node in a requested direction', () => {
    const nodes = [
      { id: 'center', position: { x: 50, y: 50 } },
      { id: 'left', position: { x: 30, y: 54 } },
      { id: 'far-left', position: { x: 10, y: 20 } },
      { id: 'down', position: { x: 48, y: 72 } },
    ];

    expect(findDirectionalNode(nodes, 'center', 'LEFT').id).toBe('left');
    expect(findDirectionalNode(nodes, 'center', 'DOWN').id).toBe('down');
  });
});
