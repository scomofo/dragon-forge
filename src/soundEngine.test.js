import { existsSync, statSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, test } from 'vitest';
import {
  getMusicDefinition,
  getMusicSchema,
  getMusicTrackUrl,
  getSoundDefinition,
  getSoundSchema,
  listSoundNames,
  MUSIC_COMMISSION,
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
    // P2: the hatchery bed is replaced by the authored motif-major hub track.
    expect(getMusicTrackUrl('hatchery')).toBe('/dragon-forge/assets/music/music_hub.mp3');
    // P2: the map-wandering role is now an authored commission, not a bed.
    expect(getMusicTrackUrl('wandering')).toBe('/dragon-forge/assets/music/music_map_wander.mp3');
    // Utility hub screens keep procedural beds — no mp3, plays via WebAudio.
    expect(getMusicTrackUrl('forge')).toBe(null);
  });

  test('P2 music commission — all 12 tracks are authored files on disk', () => {
    // The code twin of design/gdd/music-identity.md: every commissioned track
    // maps to a real file under public/assets/music/.
    expect(Object.keys(MUSIC_COMMISSION).length).toBe(12);
    for (const [key, entry] of Object.entries(MUSIC_COMMISSION)) {
      const file = resolve(__dirname, '..', 'public', 'assets', 'music', entry.file);
      expect(existsSync(file), `${key} -> ${entry.file}`).toBe(true);
      expect(statSync(file).size, `${key} non-empty`).toBeGreaterThan(10000);
    }
  });
});
