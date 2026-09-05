import { beforeEach, describe, expect, it, vi } from 'vitest';
import ForgeScreen from './ForgeScreen';
import { FelixOverlay } from './forge/ForgeOverlays';
import { FELIX_FIRST_VISIT_LINE, STATION_IDS } from './forgeData';

const control = vi.hoisted(() => ({ states: [], refs: [], stateIndex: 0, refIndex: 0, handlers: null, enabled: true }));
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useState(initial) {
    const index = control.stateIndex++;
    if (!(index in control.states)) control.states[index] = typeof initial === 'function' ? initial() : initial;
    return [control.states[index], value => { control.states[index] = typeof value === 'function' ? value(control.states[index]) : value; }];
  },
  useRef(initial) { return control.refs[control.refIndex++] ||= { current: initial }; },
  useCallback: callback => callback,
  useEffect: () => {},
}));
vi.mock('./useGamepadController', () => ({ default: (handlers, enabled = true) => { control.handlers = handlers; control.enabled = enabled; } }));
vi.mock('./soundEngine', () => ({ playSound: vi.fn() }));
vi.mock('./persistence', () => ({ grantRelic: vi.fn(), setFlag: vi.fn(), unlockFragment: vi.fn() }));

function mount() {
  const props = { save: { flags: {}, skye: {}, dragons: {}, defeatedNpcs: [] }, onNavigate: vi.fn(), refreshSave: vi.fn() };
  function render() {
    control.stateIndex = 0;
    control.refIndex = 0;
    return ForgeScreen(props);
  }
  return { ...props, render };
}

beforeEach(() => Object.assign(control, { states: [], refs: [], stateIndex: 0, refIndex: 0, handlers: null, enabled: true }));

describe('Forge controller handoff', () => {
  it('disables the room controller while an overlay owns input and resumes on close', () => {
    const screen = mount();
    let tree = screen.render();
    expect(control.enabled).toBe(true);
    tree.props.children[0].props.onStationClick(STATION_IDS.FELIX);
    tree = screen.render();
    expect(control.enabled).toBe(false);
    const overlay = tree.props.children.find(child => child?.type === FelixOverlay);
    control.handlers.onButtonPress('B');
    expect(screen.onNavigate).not.toHaveBeenCalled();
    overlay.props.onClose();
    screen.render();
    expect(control.enabled).toBe(true);
    control.handlers.onButtonPress('B');
    expect(screen.onNavigate).toHaveBeenCalledExactlyOnceWith('map');
  });

  it('keeps Felix’s first greeting when duplicate interact inputs arrive together', () => {
    const screen = mount();
    const scene = screen.render().props.children[0];
    scene.props.onStationClick(STATION_IDS.FELIX);
    scene.props.onStationClick(STATION_IDS.FELIX);
    const overlay = screen.render().props.children.find(child => child?.type === FelixOverlay);
    expect(overlay.props.line).toBe(FELIX_FIRST_VISIT_LINE);
  });
});
