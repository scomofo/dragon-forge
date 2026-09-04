import { describe, expect, it } from 'vitest';
import { HEARTFORGE_MOTIF, MUSIC_SCORES, getScoreDuration, noteFrequency } from './musicScores';

describe('Heartforge arrangements', () => {
  it('preserves the documented melody, including the flattened sixth', () => {
    expect(HEARTFORGE_MOTIF.map(([, pitch]) => pitch)).toEqual([
      60, 63, 67, 68, 67, 65, 63, 62, 63, 65, 67, 72, 59, 60,
    ]);
    const lead = score => score.events.filter(event => event.voice === 'lead' && event.beat < 16);
    expect(lead(MUSIC_SCORES.mirrorAdmin)).toEqual(lead(MUSIC_SCORES.heartforge));
    expect(getScoreDuration(MUSIC_SCORES.mirrorAdmin)).toBeCloseTo(2 * getScoreDuration(MUSIC_SCORES.heartforge));
    expect(noteFrequency(69)).toBe(440);
  });

  it('grounds Mirror Admin in A-flat and leaves the percussion downbeat empty', () => {
    const events = MUSIC_SCORES.mirrorAdmin.events;
    expect(events.find(event => event.voice === 'bass').pitch).toBe(32);
    const percussion = events.filter(event => event.voice === 'tick');
    expect(percussion.length).toBeGreaterThan(0);
    expect(percussion.every(event => event.beat % 4 !== 0)).toBe(true);
  });

  it('fits four distinct sections into a clean loop with an eight-voice budget', () => {
    for (const score of Object.values(MUSIC_SCORES)) {
      expect(score.sections).toHaveLength(4);
      expect(score.beats).toBe(64);
      expect(score.events.map(event => event.beat)).toEqual(score.events.map(event => event.beat).sort((a, b) => a - b));
      for (const event of score.events) {
        expect(event.beat).toBeGreaterThanOrEqual(0);
        expect(event.duration).toBeGreaterThan(0);
        expect(event.beat + event.duration).toBeLessThanOrEqual(score.beats);
        expect(event.velocity).toBeGreaterThan(0);
        expect(event.velocity).toBeLessThanOrEqual(1);
        const concurrent = score.events.filter(note => note.beat <= event.beat && note.beat + note.duration > event.beat);
        expect(concurrent.length).toBeLessThanOrEqual(8);
      }
      const phrase = start => score.events.filter(event => event.voice === 'lead' && event.beat >= start && event.beat < start + 16).map(event => event.pitch);
      expect(phrase(0)).not.toEqual(phrase(16));
      expect(phrase(0)).not.toEqual(phrase(48));
    }
  });
});
