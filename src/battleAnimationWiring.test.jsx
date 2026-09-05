import { beforeEach, describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import BattleScreen from './BattleScreen';
import { loadSave } from './persistence';

const control = vi.hoisted(() => ({ overlay: null, reducer: null, vfx: null }));
vi.mock('react', async importOriginal => {
  const react = await importOriginal();
  return { ...react, useReducer(reducer, ...args) {
    control.reducer = reducer;
    const [state, dispatch] = react.useReducer(reducer, ...args);
    return [{ ...state, phase: 'animating', vfxActive: control.vfx }, dispatch];
  } };
});
vi.mock('./VfxOverlay', async importOriginal => {
  const { default: Overlay } = await importOriginal();
  return { default: props => { control.overlay = props; return <Overlay {...props} />; } };
});

beforeEach(() => { control.overlay = null; control.reducer = null; control.vfx = null; });
function renderBattle() {
  return renderToStaticMarkup(<BattleScreen dragonId="fire" npcId="firewall_sentinel" save={loadSave()}
    refreshSave={() => {}} onBattleEnd={() => {}} />);
}

describe('battle animation wiring', () => {
  it('delivers scaled timing and the contact callback to the real VFX overlay', () => {
    control.vfx = { id: 1, vfxKey: 'BASIC_ATTACK', element: 'neutral', direction: 'left-to-right',
      targetSide: 'left', travelMs: 135, impactMs: 110, onImpact: vi.fn(), onComplete: vi.fn() };
    const html = renderBattle();
    expect(control.overlay.travelMs).toBe(135);
    expect(control.overlay.impactMs).toBe(110);
    expect(control.overlay.onImpact).toBe(control.vfx.onImpact);
    expect(control.overlay.onComplete).toBe(control.vfx.onComplete);
    expect(html).toContain('animation-duration:135ms');
  });

  it('ignores a late completion from an older projectile', () => {
    renderBattle();
    const state = { vfxActive: { id: 2 } };
    expect(control.reducer(state, { type: 'CLEAR_VFX', id: 1 })).toBe(state);
    expect(control.reducer(state, { type: 'CLEAR_VFX', id: 2 }).vfxActive).toBeNull();
  });
});
