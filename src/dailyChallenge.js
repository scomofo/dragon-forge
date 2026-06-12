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

function getYesterdaySeed() {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
}

// The stored dailyStreak never decays — it only counts toward today's
// multiplier if yesterday's daily was completed. Display sites must use
// this gated value, not raw save.dailyStreak.
export function getEffectiveStreak(save) {
  const yesterdaySeed = getYesterdaySeed();
  return save?.lastDailyCompleted === yesterdaySeed ? (save.dailyStreak || 0) : 0;
}

export function getDailyStreakMultiplier(save) {
  const currentStreak = getEffectiveStreak(save) + 1;
  if (currentStreak <= 1) return 1.0;
  return Math.min(1.5, 1.0 + (currentStreak - 1) * 0.1);
}

export function getDateString() {
  const now = new Date();
  return now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}
