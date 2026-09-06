import { describe, expect, it } from 'vitest';
import { getBattleCues } from './battleCueModel';
import { dragons, npcs } from './gameData';
import { BOSS_PATTERNS } from './bossPatterns';
import { MIRROR_ADMIN, SINGULARITY_BOSSES } from './singularityBosses';

function stateFor(id, extra = {}) {
  const npc = npcs[id] || SINGULARITY_BOSSES.find(boss => boss.id === id) || { ...MIRROR_ADMIN, ...MIRROR_ADMIN.phases[2] };
  return { phase: 'playerTurn', bossPatternId: id, bossState: {}, npc, npcHp: npc.stats.hp, npcMaxHp: npc.stats.hp,
    dragon: dragons.fire, dragonId: 'fire', turnCount: 0, currentPhase: id === 'mirror_admin' ? 2 : 0, ...extra };
}
const byId = (state, id, options) => getBattleCues(state, options).find(cue => cue.id === id);

describe('decision-time enemy signals', () => {
  it.each(Object.keys(BOSS_PATTERNS))('covers the authored %s encounter using shipped data', pattern => {
    const mirror = pattern === 'mirror_admin_reset';
    const cues = getBattleCues(stateFor(mirror ? 'mirror_admin' : pattern), { isMirrorAdmin: mirror });
    expect(cues.length).toBeGreaterThan(0);
    for (const cue of cues) {
      expect(cue.title).not.toMatch(/undefined|NaN/);
      expect(cue.detail).not.toMatch(/undefined|NaN/);
    }
  });

  it.each(['animating', 'phaseShift', 'victory', 'defeat', 'epilogue'])('does not expose advanced counters in %s', phase => {
    expect(getBattleCues(stateFor('buffer_overflow', { phase, bossState: { heatStacks: 4 }, npcChargedMove: 'blizzard' }))).toEqual([]);
  });

  it('shows the shield opening only after Defend, without advertising a spent Phase Strike', () => {
    const state = stateFor('firewall_sentinel', { dragon: dragons.shadow, dragonId: 'shadow' });
    expect(byId(state, 'shield').detail).toContain('Phase Strike');
    expect(byId({ ...state, playerSignatureUsed: { shadow: true } }, 'shield').detail).not.toContain('Phase Strike');
    expect(byId(state, 'shield', { playerDefendedLastTurn: true }).tone).toBe('opening');
    expect(byId(state, 'shield', { playerDefendedLastTurn: false }).title).toBe('Shield closed');
  });

  it('prioritizes a stored charge over a threshold signature, retaining the mechanic counter', () => {
    const state = stateFor('recursive_golem', { npcHp: 1, bossState: { hardenStacks: 3 }, npcChargedMove: 'earthquake' });
    const cues = getBattleCues(state);
    expect(cues.map(cue => cue.id)).toEqual(['charge', 'harden']);
    expect(cues[0].detail).toContain('40%');
    expect(cues[1].meter).toEqual({ value: 3, max: 3 });
  });

  it('does not advise Defend when a charged Wraith hit pierces it', () => {
    const cue = byId(stateFor('bit_wraith', { npcChargedMove: 'blizzard', bossState: { pierceNext: true } }), 'charge');
    expect(cue.detail).toContain('ignores Defend');
    expect(cue.detail).not.toContain('Defend to reduce');
  });

  it('offers a swap only when there is a living reserve', () => {
    const state = stateFor('bit_wraith', { bossState: { pierceNext: true } });
    expect(byId(state, 'phase').detail).not.toContain('swap');
    expect(byId({ ...state, bench: { playerHp: 20 } }, 'phase').detail).toContain('swap');
  });

  it('shows an eligible signature once, without predicting random ordinary attacks', () => {
    const state = stateFor('bit_wraith');
    expect(byId(state, 'signature')).toBeUndefined();
    expect(byId({ ...state, npcHp: state.npcMaxHp * 0.5 }, 'signature')).toBeDefined();
    expect(byId({ ...state, npcHp: 1, signatureMoveUsed: true }, 'signature')).toBeUndefined();
  });

  it('tracks encryption progress through neutral hits and the revealed state', () => {
    expect(byId(stateFor('crypto_crab', { bossState: { prevElement: 'neutral' } }), 'cipher').detail).toContain('Repeat Neutral');
    expect(byId(stateFor('crypto_crab', { bossState: { decrypted: true } }), 'cipher').tone).toBe('opening');
  });

  it('warns only about upcoming lure windows and a living reserve', () => {
    const state = stateFor('phishing_siren', { turnCount: 1, bench: { playerHp: 25 } });
    expect(byId(state, 'lure').title).toBe('Lure this turn');
    expect(byId({ ...state, turnCount: 2 }, 'lure').title).toBe('Lure on turn 5');
    expect(byId({ ...state, turnCount: 5 }, 'lure').title).toBe('Lure spent');
    expect(byId({ ...state, bench: { playerHp: 0 } }, 'lure').title).toBe('No reserve to lure');
  });

  it('shows the Hydra lock until all three heads are broken', () => {
    const state = stateFor('glitch_hydra', { bossState: { headsBroken: 2 } });
    expect(byId(state, 'heads').detail).toContain('Ice / Shadow');
    expect(byId(state, 'heads').meter.value).toBe(2);
    expect(byId({ ...state, bossState: { headsBroken: 3 } }, 'heads').tone).toBe('opening');
  });

  it('distinguishes one remaining fuse tick from an armed detonation', () => {
    expect(byId(stateFor('logic_bomb', { bossState: { fuseTurns: 1 } }), 'fuse').title).toBe('Fuse 1/6');
    expect(byId(stateFor('logic_bomb', { bossState: { fuseTurns: 0 } }), 'fuse').title).toBe('Detonation armed');
  });

  it('shows the expired fuse instead of a stored charge or threshold signature', () => {
    const state = stateFor('logic_bomb', {
      npcHp: 1, npcChargedMove: 'earthquake', bossState: { fuseTurns: 0 },
    });
    for (const signatureMoveUsed of [false, true]) {
      const cues = getBattleCues({ ...state, signatureMoveUsed });
      expect(cues.map(cue => cue.id)).toEqual(['fuse']);
      expect(cues[0].detail).toContain('cannot miss');
      expect(cues[0].detail).toContain('stopped by status');
      expect(cues[0].detail).toContain('Defend');
      expect(cues[0].detail).not.toContain('40%');
    }
  });

  it('retains the charge warning before the fuse expires', () => {
    const cues = getBattleCues(stateFor('logic_bomb', {
      npcChargedMove: 'earthquake', bossState: { fuseTurns: 1 },
    }));
    expect(cues.map(cue => cue.id)).toEqual(['charge', 'fuse']);
    expect(cues[0].detail).toContain('40%');
    expect(cues.some(cue => cue.detail.includes('cannot miss'))).toBe(false);
  });

  it('does not promise the early low-HP detonation is guaranteed', () => {
    const cues = getBattleCues(stateFor('logic_bomb', {
      npcHp: 1, bossState: { fuseTurns: 4 },
    }));
    expect(cues.map(cue => cue.id)).toEqual(['signature', 'fuse']);
    expect(cues[0].title).toContain('Final Detonation');
    expect(cues.some(cue => cue.detail.includes('cannot miss'))).toBe(false);
  });

  it('marks the fuse detonation spent and resumes ordinary charge warnings', () => {
    const cues = getBattleCues(stateFor('logic_bomb', {
      signatureMoveUsed: true, npcChargedMove: 'earthquake', bossState: { fuseTurns: 0, fuseDetonated: true },
    }));
    expect(cues.map(cue => cue.id)).toEqual(['charge', 'fuse']);
    expect(cues[1].title).toBe('Detonation spent');
    expect(cues[1].tone).toBe('opening');
    expect(cues[1].detail).not.toContain('Defend');
  });

  it('describes corruption duration as uses, since unused slots do not expire', () => {
    const state = stateFor('data_corruption', { turnCount: 8, bossState: { garbledDragonId: 'fire', garbledMoveKey: 'flame_wall', garbledTurnsLeft: 2 } });
    expect(byId(state, 'garble').title).toContain('Flame Wall');
    expect(byId(state, 'garble').detail).toContain('2 more uses');
    expect(byId({ ...state, bossState: { ...state.bossState, garbledTurnsLeft: 1 } }, 'garble').detail).toContain('1 more use.');
  });

  it('shows the initialized corruption before the first command', () => {
    const state = stateFor('data_corruption', { bossState: { garbledDragonId: 'fire', garbledMoveKey: 'magma_breath', garbledTurnsLeft: 2 } });
    expect(byId(state, 'garble').title).toBe('Magma Breath corrupted');
    expect(byId(state, 'garble').detail).toContain('2 more uses');
  });

  it('does not attribute the other dragon\'s corruption to the active kit', () => {
    const state = stateFor('data_corruption', { bossState: { garbledDragonId: 'ice', garbledMoveKey: 'blizzard', garbledTurnsLeft: 2 } });
    expect(byId(state, 'garble').title).toBe('Slots clear');
    expect(byId(state, 'garble').detail).toContain('Burn');
    expect(byId(state, 'garble').detail).not.toContain('Basic Attack');
    // Fused dragons can share a technique with its owner; a matching move key
    // alone must not make the incoming dragon's command appear corrupted.
    expect(byId({ ...state, bossState: { ...state.bossState, garbledDragonId: 'fused_fire', garbledMoveKey: 'flame_wall' } }, 'garble').title).toBe('Slots clear');
  });

  it('warns that new Burn can corrupt a move again after both uses clear', () => {
    const state = stateFor('data_corruption', { turnCount: 8, bossState: { garbledDragonId: 'fire', garbledMoveKey: 'flame_wall', garbledTurnsLeft: 0 } });
    expect(byId(state, 'garble').title).toBe('Slots clear');
    expect(byId(state, 'garble').detail).toContain('A new Burn');
  });

  it('distinguishes a speed surge from guard recovery and the spent burst', () => {
    const state = stateFor('stack_overflow', { bossState: { spdDoubleTurnsLeft: 1, crashTurnsLeft: 2, surgeUsed: true } });
    expect(byId(state, 'surge').tone).toBe('danger');
    expect(byId({ ...state, bossState: { ...state.bossState, spdDoubleTurnsLeft: 0 } }, 'surge').detail).toContain('guards');
    expect(byId({ ...state, bossState: { surgeUsed: true } }, 'surge').title).toBe('Surge spent');
  });

  it('uses only this phase’s healing history for the Great Reset', () => {
    const state = stateFor('mirror_admin', { playerMoveHistory: ['restoration'], phaseMoveHistory: [] });
    const options = { isMirrorAdmin: true };
    expect(byId(state, 'reset', options).title).toBe('Great Reset armed');
    expect(byId({ ...state, phaseMoveHistory: ['recompile'] }, 'reset', options).tone).toBe('opening');
    expect(byId({ ...state, currentPhase: 1 }, 'reset', options)).toBeUndefined();
    expect(byId({ ...state, bossState: { mirrorHealPunished: true } }, 'reset', options).title).toBe('Great Reset spent');
  });
});
