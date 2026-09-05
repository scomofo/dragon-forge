import { describe, expect, it } from 'vitest';
import { getBattleContactState, hasDamagingImpact } from './battlePresentation';
import { resolveBattlePose } from './battleSets';

const attack = { action: 'attack', attacker: 'player', hit: true, damage: 12, effectiveness: 1, targetHp: 20 };
const playerPose = state => resolveBattlePose({ spriteClass: state.playerSpriteClass });
const npcPose = state => resolveBattlePose({ spriteClass: state.npcSpriteClass, isAttacking: state.npcAttacking });

describe('contact pose handoff', () => {
  it('keeps the shipped player sheet attacking when its hit connects', () => {
    const state = getBattleContactState(attack);
    expect(playerPose(state)).toBe('attack');
    expect(npcPose(state)).toBe('hurt');
    expect(hasDamagingImpact(attack)).toBe(true);
    expect(state.playerForcedFrame).toBe(3);
  });

  it('recoils the player at contact for an enemy hit', () => {
    const state = getBattleContactState({ ...attack, attacker: 'npc' });
    expect(npcPose(state)).toBe('attack');
    expect(playerPose(state)).toBe('hurt');
  });

  it.each(['player', 'npc'])('recoils the source of a reflected %s attack', attacker => {
    const state = getBattleContactState({ ...attack, attacker, reflected: true });
    expect(attacker === 'player' ? playerPose(state) : npcPose(state)).toBe('hurt');
    expect(attacker === 'player' ? npcPose(state) : playerPose(state)).toBe('idle');
  });

  it.each([
    { hit: false, damage: 0 }, { blocked: true, damage: 0 }, { damage: 0 },
  ])('does not fake a hurt pose for %j', change => {
    const state = getBattleContactState({ ...attack, ...change });
    expect(hasDamagingImpact({ ...attack, ...change })).toBe(false);
    expect(playerPose(state)).toBe('attack');
    expect(npcPose(state)).toBe('idle');
  });

  it('starts the faint strip at a lethal contact', () => {
    expect(npcPose(getBattleContactState({ ...attack, targetHp: 0 }))).toBe('faint');
  });
});
