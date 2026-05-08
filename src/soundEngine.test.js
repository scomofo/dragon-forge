import { describe, expect, test } from 'vitest';
import {
  getMusicDefinition,
  getMusicSchema,
  getMusicTrackUrl,
  getSoundDefinition,
  getSoundSchema,
  listSoundNames,
} from './soundEngine';

describe('sound effect schema', () => {
  test('groups combat command cues under the combat category', () => {
    expect(getSoundDefinition('commandSelect')).toMatchObject({
      name: 'combatCommandSelect',
      category: 'combat',
      role: 'command',
    });
    expect(getSoundDefinition('commandExecute')).toMatchObject({
      name: 'combatCommandExecute',
      category: 'combat',
      role: 'execute',
    });
  });

  test('keeps message and impact sounds discoverable', () => {
    const combatNames = listSoundNames('combat');

    expect(combatNames).toContain('combatFeedTick');
    expect(combatNames).toContain('criticalHit');
    expect(combatNames).toContain('victoryFanfare');
    expect(getSoundSchema().combat.combatFeedTick.cooldownMs).toBeGreaterThan(0);
  });

  test('defines explicit map wandering and tense battle music roles', () => {
    expect(getMusicDefinition('wandering')).toMatchObject({
      role: 'map-wandering',
      mood: 'wandering',
    });
    expect(getMusicDefinition('tenseBattle')).toMatchObject({
      role: 'battle-tense',
      mood: 'tense',
    });
    expect(getMusicDefinition('opening')).toMatchObject({
      role: 'opening-sequence',
      mood: 'tense',
    });
    expect(getMusicSchema().battleIntense.mood).toBe('danger');
  });

  test('resolves music tracks through the Vite base path', () => {
    expect(getMusicTrackUrl('title')).toBe('/dragon-forge/assets/music/theme.mp3');
    expect(getMusicTrackUrl('wandering')).toBe('/dragon-forge/assets/music/music_select.mp3');
  });
});
