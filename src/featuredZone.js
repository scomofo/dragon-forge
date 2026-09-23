// Daily featured zone: one of the four world zones pays DOUBLE DataScraps
// on its cache + clear rewards for the calendar day. Deterministic per day —
// everyone sees the same featured zone — via the shared daily seed.
import { WORLD_ZONE_IDS } from './worldZones';
import { getDailySeed, seededRandom, mixSeed, pickFrom } from './dailyChallenge';

export const FEATURED_ZONE_SCRAP_MULTIPLIER = 2;

export function getFeaturedZoneSeed() {
  return getDailySeed();
}

export function getFeaturedZone(seedOverride = null) {
  const seed = seedOverride ?? getFeaturedZoneSeed();
  const rng = seededRandom(mixSeed(seed));
  return pickFrom(rng, WORLD_ZONE_IDS);
}

export function isFeaturedZone(zoneId, seedOverride = null) {
  return getFeaturedZone(seedOverride) === zoneId;
}

// Apply the featured multiplier to a base scrap reward for a zone action.
// Pure: pass an explicit seed in tests; production call sites default to
// today's seed.
export function applyFeaturedMultiplier(zoneId, baseReward, seedOverride = null) {
  if (isFeaturedZone(zoneId, seedOverride)) return baseReward * FEATURED_ZONE_SCRAP_MULTIPLIER;
  return baseReward;
}
