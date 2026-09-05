import { beforeEach, describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import BattleScreen from './BattleScreen';
import BattleCues from './BattleCues';
import { getBattleCues } from './battleCueModel';
import { loadSave } from './persistence';
import { npcs } from './gameData';

const control = vi.hoisted(() => ({ overrides: {} }));
vi.mock('react', async importOriginal => {
  const react = await importOriginal();
  return { ...react, useReducer(...args) {
    const [state, dispatch] = react.useReducer(...args);
    return [state?.bossState ? { ...state, ...control.overrides } : state, dispatch];
  } };
});
beforeEach(() => { control.overrides = {}; });

function renderBattle() {
  return renderToStaticMarkup(<BattleScreen dragonId="fire" npcId="firewall_sentinel" save={loadSave()}
    refreshSave={() => {}} onBattleEnd={() => {}} />);
}

describe('battle cue rendering', () => {
  it('puts an actionable shield cue in the real opening battle', () => {
    const html = renderBattle();
    expect(html).toContain('aria-label="Enemy signals"');
    expect(html).toContain('Shield closed');
    expect(html).toContain('Defend, then strike');
  });

  it('renders a live mechanic counter with readable text and decorative pips', () => {
    const cues = getBattleCues({ phase: 'playerTurn', npc: npcs.buffer_overflow, npcHp: 100, npcMaxHp: 100,
      bossPatternId: 'buffer_overflow', bossState: { heatStacks: 4 } });
    const html = renderToStaticMarkup(<BattleCues cues={cues} />);
    expect(html).toContain('Heat 4/4');
    expect(html).toContain('aria-live="polite"');
    expect(html).toContain('aria-hidden="true"');
    expect((html.match(/class="filled"/g) || []).length).toBe(4);
  });

  it.each(['animating', 'phaseShift', 'victory', 'defeat'])('removes tactical advice during %s in the real screen', phase => {
    control.overrides = { phase, bossState: { heatStacks: 4 }, bossPatternId: 'buffer_overflow', npcChargedMove: 'blizzard' };
    const html = renderBattle();
    expect(html).not.toContain('data-cue=');
    expect(html).not.toContain('Charged: Blizzard');
  });
});
