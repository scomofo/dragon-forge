// Weekly wanted dragon: one journal dragon per ISO week. Winning battles
// with the week's wanted dragon grants +WANTED_DRAGON_CORE_BONUS cores of
// its element, on top of the normal core drop.
// ECONOMY REVIEW (ADR-0006): this is an unthrottled core faucet — every win
// with the wanted dragon pays the bonus. Flagged per gameplay plan #7.
import { JOURNAL_DRAGON_IDS, dragons } from './gameData';
import { seededRandom, mixSeed, pickFrom } from './dailyChallenge';

export const WANTED_DRAGON_CORE_BONUS = 2;

export function getWeekSeed(dateOverride = null) {
  const now = dateOverride instanceof Date ? dateOverride : new Date();
  // ISO-8601 week: shift to the week's Thursday, then count weeks from Jan 1
  // of the Thursday's year (so Dec 29-31 can belong to week 1 of next year).
  const d = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
  return d.getUTCFullYear() * 100 + week;
}

export function getWantedDragon(dateOverride = null) {
  const rng = seededRandom(mixSeed(getWeekSeed(dateOverride)));
  return pickFrom(rng, JOURNAL_DRAGON_IDS);
}

// Core element for the wanted bonus. Synthesis has no core bucket of its own,
// so it maps to Void (the Synthesis Dragon's primary fusion material).
export function getWantedCoreElement(dragonId) {
  const dragon = dragons[dragonId];
  if (!dragon) return null;
  return dragon.element === 'synthesis' ? 'void' : dragon.element;
}
