import { describe, expect, it } from 'vitest';
import { cycleBattleCommand, getBattleCommands, getBattleKeyboardCommand } from './battleCommands';

const moves = [
  { key: 'flame_wall' },
  { key: 'inferno', isSignature: true },
  { key: 'basic_attack' },
];

describe('battle command availability', () => {
  it('includes the living reserve in the visible order and directional cycle', () => {
    const commands = getBattleCommands({ moves, hasBench: true, benchHp: 24 });
    expect(commands.map(command => command.id)).toEqual(['flame_wall', 'inferno', 'basic_attack', 'defend', 'swap', 'speed', 'auto']);
    expect(cycleBattleCommand(commands, 'defend', 1)).toBe('swap');
    expect(cycleBattleCommand(commands, 'speed', -1)).toBe('swap');
  });

  it('skips spent signatures, fainted reserves and forbidden auto without losing their display slots', () => {
    const commands = getBattleCommands({ moves, signatureUsed: true, hasBench: true, benchHp: 0, autoBattleAllowed: false });
    expect(commands.filter(command => command.disabled).map(command => command.id)).toEqual(['inferno', 'swap', 'auto']);
    expect(cycleBattleCommand(commands, 'flame_wall', 1)).toBe('basic_attack');
    expect(cycleBattleCommand(commands, 'defend', 1)).toBe('speed');
    expect(cycleBattleCommand(commands, 'speed', 1)).toBe('flame_wall');
    expect(cycleBattleCommand(commands, 'flame_wall', -1)).toBe('speed');
  });

  it('blocks turn-spending actions while allowing tempo and permitted auto changes during animation', () => {
    const commands = getBattleCommands({ moves, hasBench: true, benchHp: 24, isResolving: true });
    expect(commands.filter(command => !command.disabled).map(command => command.id)).toEqual(['speed', 'auto']);
    expect(cycleBattleCommand(commands, 'basic_attack', 1)).toBe('speed');
  });

  it('keeps surviving IDs stable after a dual tech vanishes', () => {
    const withDual = getBattleCommands({ moves: [...moves, { key: 'dual_supernova' }], hasBench: true, benchHp: 24 });
    const withoutDual = getBattleCommands({ moves, hasBench: true, benchHp: 24 });
    expect(cycleBattleCommand(withDual, 'defend', 1)).toBe('swap');
    expect(cycleBattleCommand(withoutDual, 'defend', 1)).toBe('swap');
    expect(cycleBattleCommand(withoutDual, 'dual_supernova', 1)).toBe('flame_wall');
    expect(cycleBattleCommand(withoutDual, 'dual_supernova', -1)).toBe('auto');
  });

  it('omits an absent reserve and safely handles no enabled commands', () => {
    expect(getBattleCommands({ moves }).some(command => command.id === 'swap')).toBe(false);
    expect(cycleBattleCommand([], 'defend', 1)).toBeNull();
    expect(cycleBattleCommand([{ id: 'swap', disabled: true }], 'swap', -1)).toBeNull();
    expect(cycleBattleCommand([{ id: 'speed', disabled: false }], 'speed', 1)).toBe('speed');
  });
});

// A minimal ancestor model keeps these intent tests independent of a DOM/test
// renderer while representing nested labels inside real controls.
function element(selectors, parent = null) {
  const node = {
    closest(query) {
      if (query.split(',').some(selector => selectors.includes(selector.trim()))) return node;
      return parent?.closest(query) || null;
    },
  };
  return node;
}

describe('battle keyboard intent', () => {
  it.each(['Enter', ' '])('leaves %s to the native focused battle button', key => {
    const button = element(['button', '[data-battle-command]']);
    expect(getBattleKeyboardCommand({ key, target: element(['strong'], button) })).toBeNull();
    expect(getBattleKeyboardCommand({ key, target: element(['div']) })).toEqual({ type: 'activate' });
  });

  it('allows directional choices and shortcuts from a battle button', () => {
    const target = element(['span'], element(['button', '[data-battle-command]']));
    expect(getBattleKeyboardCommand({ key: 'ArrowRight', target })).toEqual({ type: 'cycle', direction: 1 });
    expect(getBattleKeyboardCommand({ key: 'ArrowUp', target })).toEqual({ type: 'cycle', direction: -1 });
    expect(getBattleKeyboardCommand({ key: 'D', target })).toEqual({ type: 'activate', id: 'defend' });
    expect(getBattleKeyboardCommand({ key: 's', target })).toEqual({ type: 'activate', id: 'speed' });
    expect(getBattleKeyboardCommand({ key: 'a', target })).toEqual({ type: 'activate', id: 'auto' });
  });

  it('does not fire battle commands while save recovery or sound controls have focus', () => {
    const target = element(['span'], element(['button']));
    for (const key of ['Enter', ' ', 'ArrowRight', 'd', 's', 'a']) {
      expect(getBattleKeyboardCommand({ key, target })).toBeNull();
    }
  });

  it.each(['input', 'select', 'textarea', '[contenteditable]', '[role="textbox"]'])('preserves editing and browser keys inside %s', selector => {
    const target = element(['span'], element([selector]));
    for (const key of ['ArrowDown', 'Enter', ' ', 'd', 's', 'a']) {
      expect(getBattleKeyboardCommand({ key, target })).toBeNull();
    }
  });

  it.each(['defaultPrevented', 'repeat', 'altKey', 'ctrlKey', 'metaKey', 'isComposing'])('ignores %s events to avoid repeated turns and browser shortcut conflicts', flag => {
    expect(getBattleKeyboardCommand({ key: 'd', [flag]: true })).toBeNull();
  });

  it('leaves tabbing, Escape and unassigned keys unchanged', () => {
    for (const key of ['Tab', 'Escape', 'x', undefined]) expect(getBattleKeyboardCommand({ key })).toBeNull();
  });
});
