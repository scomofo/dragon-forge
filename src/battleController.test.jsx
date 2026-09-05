import { beforeEach, describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import BattleScreen from './BattleScreen';
import CampaignMapScreen from './CampaignMapScreen';
import { loadSave } from './persistence';

const control = vi.hoisted(() => ({ phase: null, handlers: null }));

vi.mock('./useGamepadController', () => ({
  default: handlers => { control.handlers = handlers; },
}));

// Render the real screen and exercise the handler it registers. Seed only the
// terminal phase; keep initBattle's real stats, party, and rendering data.
vi.mock('react', async importOriginal => {
  const react = await importOriginal();
  return {
    ...react,
    useReducer(...args) {
      const [state, dispatch] = react.useReducer(...args);
      return [control.phase && state?.phase ? { ...state, phase: control.phase } : state, dispatch];
    },
  };
});

beforeEach(() => { control.phase = null; control.handlers = null; });

describe('battle controller result flow', () => {
  it.each([['victory', true], ['defeat', false], ['epilogue', true]])('lets A and Start leave %s with the actual outcome', (phase, won) => {
    control.phase = phase;
    const onBattleEnd = vi.fn();
    const html = renderToStaticMarkup(<BattleScreen dragonId="fire" npcId="firewall_sentinel" save={loadSave()}
      refreshSave={() => {}} onBattleEnd={onBattleEnd} battleConfig={{ returnScreen: 'outerGrid' }} />);
    for (const button of ['A', 'START']) {
      onBattleEnd.mockClear();
      control.handlers.onButtonPress(button);
      expect(onBattleEnd).toHaveBeenCalledExactlyOnceWith(won);
    }
    onBattleEnd.mockClear();
    control.handlers.onButtonPress('Y');
    control.handlers.onButtonPress('B');
    expect(onBattleEnd).not.toHaveBeenCalled();
    if (!won) expect(html).toContain('Return to this room to retry');
  });

  it.each(['animating', 'phaseShift'])('does not leave the battle during %s', phase => {
    control.phase = phase;
    const onBattleEnd = vi.fn();
    renderToStaticMarkup(<BattleScreen dragonId="fire" npcId="firewall_sentinel" save={loadSave()}
      refreshSave={() => {}} onBattleEnd={onBattleEnd} battleConfig={{ returnScreen: 'outerGrid' }} />);
    control.handlers.onButtonPress('A');
    control.handlers.onButtonPress('START');
    expect(onBattleEnd).not.toHaveBeenCalled();
  });

  it('enters Outer Grid from the map with X', () => {
    const onNavigate = vi.fn();
    renderToStaticMarkup(<CampaignMapScreen save={loadSave()} onNavigate={onNavigate} onBeginCampaignBattle={() => {}} />);
    control.handlers.onButtonPress('X');
    expect(onNavigate).toHaveBeenCalledExactlyOnceWith('outerGrid');
  });
});
