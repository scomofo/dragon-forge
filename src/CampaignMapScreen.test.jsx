import { beforeEach, describe, expect, it, vi } from 'vitest';
import CampaignMapScreen from './CampaignMapScreen';

const control = vi.hoisted(() => ({ states: [], refs: [], stateIndex: 0, refIndex: 0, handlers: null }));
vi.mock('react', async importOriginal => ({
  ...await importOriginal(),
  useState(initial) {
    const index = control.stateIndex++;
    if (!(index in control.states)) control.states[index] = typeof initial === 'function' ? initial() : initial;
    return [control.states[index], value => { control.states[index] = typeof value === 'function' ? value(control.states[index]) : value; }];
  },
  useRef(initial) { return control.refs[control.refIndex++] ||= { current: initial }; },
  useMemo: factory => factory(),
}));
vi.mock('./useGamepadController', () => ({ default: handlers => { control.handlers = handlers; } }));
vi.mock('./soundEngine', () => ({ playSound: vi.fn() }));
vi.mock('./NavBar', () => ({ default: () => null }));
vi.mock('./DragonSprite', () => ({ default: () => null }));

function mount() {
  const props = {
    save: {
      defeatedNpcs: [],
      dragons: Object.fromEntries(['fire', 'ice', 'stone'].map(id => [id, { owned: true, level: 1, xp: 0 }])),
    },
    onNavigate: vi.fn(), onBeginCampaignBattle: vi.fn(),
  };
  function render() {
    control.stateIndex = 0;
    control.refIndex = 0;
    return CampaignMapScreen(props);
  }
  render();
  return { ...props, render, press(button) { control.handlers.onButtonPress(button); render(); } };
}

beforeEach(() => Object.assign(control, { states: [], refs: [], stateIndex: 0, refIndex: 0, handlers: null }));

describe('campaign controller party selection', () => {
  it('bumper presses change the primary and send it into the actual battle callback', () => {
    const screen = mount();
    screen.press('RB'); // fire, the first guardian
    screen.press('RB'); // ice
    screen.press('RB'); // stone
    screen.press('LB'); // ice
    screen.press('A');
    screen.press('START');
    expect(screen.onBeginCampaignBattle).toHaveBeenCalledExactlyOnceWith(expect.objectContaining({ dragonId: 'ice', benchDragonId: null }));
  });

  it('allows controller-only reserve selection and swaps roles when a bumper reaches the reserve', () => {
    const screen = mount();
    screen.press('A'); // choose first primary without immediately starting
    expect(screen.onBeginCampaignBattle).not.toHaveBeenCalled();
    screen.press('Y'); // ice reserve
    screen.press('RB'); // ice primary, fire reserve
    screen.press('START');
    expect(screen.onBeginCampaignBattle).toHaveBeenCalledExactlyOnceWith(expect.objectContaining({ dragonId: 'ice', benchDragonId: 'fire' }));
  });

  it('cycles the reserve back to none without disturbing the primary', () => {
    const screen = mount();
    screen.press('RB'); // fire
    screen.press('Y'); // ice
    screen.press('Y'); // stone
    screen.press('Y'); // none
    screen.press('A');
    expect(screen.onBeginCampaignBattle).toHaveBeenCalledExactlyOnceWith(expect.objectContaining({ dragonId: 'fire', benchDragonId: null }));
  });
});
