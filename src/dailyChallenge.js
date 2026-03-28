import { npcs, elementColors } from './gameData';

const NPC_IDS = Object.keys(npcs);

function getDailySeed() {
  const now = new Date();
  return now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
}

function seededRandom(seed) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) & 0xffffffff;
    return (s >>> 0) / 0xffffffff;
  };
}

export function getDailyChallenge() {
  const seed = getDailySeed();
  const rng = seededRandom(seed);

  // Pick today's NPC
  const npcIndex = Math.floor(rng() * NPC_IDS.length);
  const baseNpc = npcs[NPC_IDS[npcIndex]];

  // Boost stats by 30-60%
  const boostFactor = 1.3 + rng() * 0.3;
  const boostedStats = {};
  for (const key of Object.keys(baseNpc.stats)) {
    boostedStats[key] = Math.floor(baseNpc.stats[key] * boostFactor);
  }

  // Boost rewards
  const boostedXP = Math.floor(baseNpc.baseXP * 2);
  const boostedScraps = Math.floor(baseNpc.scrapsReward * 3);

  return {
    ...baseNpc,
    id: 'daily_challenge',
    name: `DAILY: ${baseNpc.name}`,
    stats: boostedStats,
    level: Math.floor(baseNpc.level * boostFactor),
    baseXP: boostedXP,
    scrapsReward: boostedScraps,
    difficulty: 'Daily',
    seed,
  };
}

export function isDailyChallengeCompleted(save) {
  const seed = getDailySeed();
  return save.lastDailyCompleted === seed;
}

export function getDateString() {
  const now = new Date();
  return now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}
