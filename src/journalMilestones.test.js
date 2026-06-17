import { describe, it, expect } from 'vitest';
import { checkMilestones } from './journalMilestones';

// Minimal save shape sufficient for checkMilestones (all other reads are optional-chained).
function makeSave(dragons) {
  return { dragons, milestones: [] };
}

function dragon({ owned = false, discovered = owned, shiny = false } = {}) {
  return { level: 1, xp: 0, owned, discovered, shiny, fusedBaseStats: null };
}

const ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow', 'void', 'light'];

function rosterAll(props) {
  return Object.fromEntries(ELEMENTS.map(e => [e, dragon(props)]));
}

function get(results, id) {
  return results.find(m => m.id === id);
}

describe('collection milestones count discovered, not owned', () => {
  it('full_roster stays at 8/8 after fusion consumes parents (owned drops, discovered persists)', () => {
    // Simulate a post-fusion state: all 8 were discovered, but two parents are now unowned.
    const dragons = rosterAll({ owned: true, discovered: true });
    dragons.fire = dragon({ owned: false, discovered: true });   // consumed parent
    dragons.ice = dragon({ owned: false, discovered: true });    // consumed parent

    const results = checkMilestones(makeSave(dragons));
    const full = get(results, 'full_roster');
    expect(full.progress).toBe('8/8');
    expect(full.newlyClaimed).toBe(true);
  });

  it('elemental_trio does not regress when a discovered dragon is fused away', () => {
    const dragons = rosterAll({ owned: false, discovered: false });
    dragons.fire = dragon({ owned: true, discovered: true });
    dragons.ice = dragon({ owned: false, discovered: true }); // fused away but discovered
    dragons.storm = dragon({ owned: true, discovered: true });

    const trio = get(checkMilestones(makeSave(dragons)), 'elemental_trio');
    expect(trio.progress).toBe('3/3');
    expect(trio.newlyClaimed).toBe(true);
  });

  it('first_discovery stays met even if the only dragon was fused away', () => {
    const dragons = rosterAll({ owned: false, discovered: false });
    dragons.fire = dragon({ owned: false, discovered: true });

    const first = get(checkMilestones(makeSave(dragons)), 'first_discovery');
    expect(first.progress).toBe('1/1');
    expect(first.newlyClaimed).toBe(true);
  });

  it('an undiscovered roster reports zero progress', () => {
    const results = checkMilestones(makeSave(rosterAll({ owned: false, discovered: false })));
    expect(get(results, 'first_discovery').progress).toBe('0/1');
    expect(get(results, 'elemental_trio').progress).toBe('0/3');
    expect(get(results, 'full_roster').progress).toBe('0/8');
  });
});
