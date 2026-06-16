import { describe, it, expect } from 'vitest';
import { getReplayReward } from './persistence';

// Endgame: every 5th total clear of a Singularity boss grants a core cache so
// the harder replays (rising REPLAY_CAP) stay worth repeating.
describe('endgame replay reward', () => {
  it('grants nothing on non-multiples of 5', () => {
    for (const n of [0, 1, 2, 3, 4, 6, 7, 9, 11, 14]) {
      expect(getReplayReward(n)).toBeNull();
    }
  });

  it('grants a 5-core cache on every 5th clear', () => {
    expect(getReplayReward(5)).toEqual({ element: 'fire', count: 5 });
    expect(getReplayReward(10)).toEqual({ element: 'ice', count: 5 });
    expect(getReplayReward(15)).toEqual({ element: 'storm', count: 5 });
  });

  it('cycles the reward element across the six core elements', () => {
    const els = [5, 10, 15, 20, 25, 30, 35].map((n) => getReplayReward(n).element);
    expect(els).toEqual(['fire', 'ice', 'storm', 'stone', 'venom', 'shadow', 'fire']);
  });
});
