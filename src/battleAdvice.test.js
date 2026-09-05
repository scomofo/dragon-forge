import { describe, expect, it } from 'vitest';
import { dragons } from './gameData';
import { getDefeatAdvice } from './battleAdvice';

const defeat = (overrides = {}) => ({
  phase: 'defeat', dragon: dragons.fire, dragonId: 'fire',
  npc: { id: 'test_enemy', element: 'storm' }, npcHp: 70, npcMaxHp: 100,
  playerMoveHistory: [], bossState: {}, battleLog: [], ...overrides,
});

describe('defeat advice', () => {
  it('does not coach unfinished or victorious battles', () => {
    expect(getDefeatAdvice(undefined)).toBeNull();
    expect(getDefeatAdvice(defeat({ phase: 'playerTurn' }))).toBeNull();
    expect(getDefeatAdvice(defeat({ phase: 'victory' }))).toBeNull();
  });

  it('prioritizes the sentinel shield over a resisted matchup', () => {
    const advice = getDefeatAdvice(defeat({ bossPatternId: 'firewall_sentinel',
      npc: { element: 'stone' }, playerMoveHistory: ['magma_breath'] }));
    expect(advice.title).toBe('Open the packet shield');
    expect(advice.detail).toContain('Defend first, then strike on the following turn');
  });

  it('explains cipher timing without prescribing an unowned element', () => {
    const state = defeat({ bossPatternId: 'crypto_crab', bossState: { decrypted: false } });
    expect(getDefeatAdvice(state).detail).toContain('damage opens on following attacks');
    expect(getDefeatAdvice(state).detail).toContain('Basic Attack');
    expect(getDefeatAdvice({ ...state, bossState: { decrypted: true } }).title).not.toBe('Crack the cipher');
  });

  it('explains only an unbroken hydra lock and allows repeated elements', () => {
    const state = defeat({ bossPatternId: 'glitch_hydra', bossState: { headsBroken: 2 } });
    expect(getDefeatAdvice(state).detail).toContain('Repeated elements count');
    expect(getDefeatAdvice({ ...state, bossState: { headsBroken: 3 } }).title).not.toBe('Break all three heads');
  });

  it('uses the actual late fuse counter without promising guaranteed detonation timing', () => {
    const state = defeat({ bossPatternId: 'logic_bomb', bossState: { fuseTurns: 0 } });
    expect(getDefeatAdvice(state).title).toBe('Watch the fuse');
    expect(getDefeatAdvice({ ...state, bossState: { fuseTurns: 5 } }).title).not.toBe('Watch the fuse');
  });

  it('uses a recorded wraith phase to avoid recommending an ineffective guard', () => {
    const advice = getDefeatAdvice(defeat({ bossPatternId: 'bit_wraith', bossState: { pierceNext: false },
      battleLog: ['Bit Wraith phases — its next hit ignores Defend!'] }));
    expect(advice.detail).toContain('Its next hit ignores Defend');
    expect(advice.detail).toContain('attack instead');
  });

  it('recommends the Ice reset only when the actual party has an Ice attack', () => {
    const state = defeat({ bossPatternId: 'memory_leak', bossState: { leakPips: 4 }, npc: { element: 'ice' } });
    expect(getDefeatAdvice(state).title).not.toBe('Clear the defense buildup');
    const advice = getDefeatAdvice({ ...state, bench: { dragon: dragons.ice, playerHp: 0 }, playerMoveHistory: ['frost_bite'] });
    expect(advice.title).toBe('Clear the defense buildup');
    expect(advice.detail).toContain('Frost Bite');
    expect(advice.detail).toContain('even when its damage is resisted');
  });

  it('reports the actual corrupted slot and an observed surge without claiming a loss cause', () => {
    expect(getDefeatAdvice(defeat({ bossPatternId: 'data_corruption',
      bossState: { garbledMoveKey: 'flame_wall', garbledTurnsLeft: 1 } })).detail).toContain('Flame Wall fires as Basic Attack');
    expect(getDefeatAdvice(defeat({ bossPatternId: 'stack_overflow', bossState: { surgeUsed: true } })).detail)
      .toContain('stored charge that can fire first');
  });

  it('reserves an owned reset counter for the next attempt even if already spent', () => {
    const state = defeat({ currentPhase: 2, bossState: { mirrorHealPunished: true }, dragon: dragons.light,
      playerSignatureUsed: { light: true } });
    const advice = getDefeatAdvice(state, { isMirrorAdmin: true });
    expect(advice.detail).toContain('Next attempt, save Restoration for phase 3');
    expect(getDefeatAdvice({ ...state, dragon: dragons.fire }, { isMirrorAdmin: true }).title).not.toBe('Seal the Great Reset');
    expect(getDefeatAdvice({ ...state, currentPhase: 1 }, { isMirrorAdmin: true }).title).not.toBe('Seal the Great Reset');
  });

  it('uses executed resisted moves, but never assumes a selected move or Recompile was resisted', () => {
    const state = defeat({ npc: { element: 'stone' } });
    expect(getDefeatAdvice(state).title).not.toBe('Try a neutral attack');
    expect(getDefeatAdvice({ ...state, playerMoveHistory: ['magma_breath'] }).detail).toContain('Magma Breath is resisted');
    expect(getDefeatAdvice({ ...state, npc: { element: 'synthesis' }, playerMoveHistory: ['recompile'] }).title).not.toBe('Try a neutral attack');
  });

  it('uses measured remaining HP and a repeatable accurate move without promising a finishing blow', () => {
    const advice = getDefeatAdvice(defeat({ npcHp: 8, dragon: dragons.storm,
      playerSignatureUsed: { storm: true }, dualTechUsed: true }));
    expect(advice.detail).toContain('8 HP left');
    expect(advice.detail).toContain('Basic Attack (100% base accuracy)');
    expect(advice.detail).toContain('Blind can still reduce accuracy');
    expect(advice.detail).not.toContain('Overclock');
  });

  it('returns one deterministic fallback tip without mutating the battle or requiring grind', () => {
    const state = defeat();
    const original = structuredClone(state);
    const advice = getDefeatAdvice(state);
    expect(Object.keys(advice)).toEqual(['title', 'detail']);
    expect(advice.detail).toContain('unless the signal says it ignores Defend');
    expect(advice.detail).not.toMatch(/level up|grind/i);
    expect(getDefeatAdvice(state)).toEqual(advice);
    expect(state).toEqual(original);
  });
});
