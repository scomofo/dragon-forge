import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { OverlayShell } from './ForgeOverlays';

const control = vi.hoisted(() => ({ refs: [], effects: [], handlers: null }));
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useRef(initial) { const ref = { current: initial }; control.refs.push(ref); return ref; },
  useEffect(effect) { control.effects.push(effect); },
}));
vi.mock('../useGamepadController', () => ({ default: handlers => { control.handlers = handlers; return { id: 'Test controller' }; } }));
vi.mock('../soundEngine', () => ({ playSound: vi.fn() }));

function button(name, disabled = false) {
  const element = {
    name, disabled,
    focus: vi.fn(() => { document.activeElement = element; }),
    click: vi.fn(),
    scrollIntoView: vi.fn(),
  };
  return element;
}

function mount(buttons) {
  const onClose = vi.fn();
  const tree = OverlayShell({ title: 'ANVIL', onClose, children: null });
  const section = tree.props.children;
  const shell = {
    querySelectorAll: () => buttons.filter(item => !item.disabled), scrollTop: 0, clientHeight: 400,
    focus() { document.activeElement = shell; },
  };
  section.ref.current = shell;
  control.refs[0].current = buttons[0];
  const cleanups = control.effects.map(effect => effect());
  return { onClose, shell, section, unmount: () => cleanups.forEach(cleanup => cleanup?.()) };
}

beforeEach(() => {
  Object.assign(control, { refs: [], effects: [], handlers: null });
  vi.stubGlobal('document', { activeElement: button('station') });
});
afterEach(() => vi.unstubAllGlobals());

describe('Forge overlay controller interaction', () => {
  it('focuses and confirms enabled actions while skipping an unaffordable upgrade', () => {
    const close = button('close');
    const upgrade = button('upgrade', true);
    const equip = button('equip');
    mount([close, upgrade, equip]);
    expect(document.activeElement).toBe(close);
    control.handlers.onDirectionPress('DOWN');
    expect(document.activeElement).toBe(equip);
    expect(equip.scrollIntoView).toHaveBeenCalledWith(expect.objectContaining({ block: 'nearest' }));
    control.handlers.onButtonPress('A');
    control.handlers.onButtonPress('START');
    expect(equip.click).toHaveBeenCalledTimes(1);
    expect(upgrade.click).not.toHaveBeenCalled();
    control.handlers.onDirectionPress('RIGHT');
    expect(document.activeElement).toBe(close);
  });

  it('recovers focus without activating another action when the focused control disappears or disables', async () => {
    const close = button('close');
    const upgrade = button('upgrade');
    mount([close, upgrade]);
    upgrade.focus();
    upgrade.disabled = true;
    control.handlers.onButtonPress('A');
    expect(document.activeElement).toBe(close);
    expect(close.click).not.toHaveBeenCalled();
    expect(upgrade.click).not.toHaveBeenCalled();
    await Promise.resolve();
    control.handlers.onButtonPress('START');
    expect(close.click).toHaveBeenCalledTimes(1);
  });

  it('closes once and ignores a same-poll confirmation of a stale purchase button', () => {
    const close = button('close');
    const upgrade = button('upgrade');
    const overlay = mount([close, upgrade]);
    upgrade.focus();
    control.handlers.onButtonPress('B');
    control.handlers.onButtonPress('SELECT');
    control.handlers.onButtonPress('A');
    expect(overlay.onClose).toHaveBeenCalledTimes(1);
    expect(upgrade.click).not.toHaveBeenCalled();
  });

  it('scrolls long Captain logs in both directions without activating a button', () => {
    const close = button('close');
    const overlay = mount([close]);
    control.handlers.onButtonPress('RB');
    expect(overlay.shell.scrollTop).toBe(280);
    control.handlers.onButtonPress('LB');
    expect(overlay.shell.scrollTop).toBe(0);
    control.handlers.onButtonPress('A');
    expect(document.activeElement).toBe(close);
    expect(close.click).not.toHaveBeenCalled();
  });

  it('keeps Tab within the dialog and restores the prior station focus on close', () => {
    const previous = document.activeElement;
    const close = button('close');
    const action = button('open hatchery');
    const overlay = mount([close, action]);
    const event = { key: 'Tab', shiftKey: true, preventDefault: vi.fn() };
    overlay.section.props.onKeyDown(event);
    expect(event.preventDefault).toHaveBeenCalled();
    expect(document.activeElement).toBe(action);
    overlay.unmount();
    expect(document.activeElement).toBe(previous);
  });
});
