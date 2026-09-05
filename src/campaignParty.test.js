import { describe, expect, it } from 'vitest';
import { cycleCampaignPrimary, cycleCampaignReserve } from './campaignParty';

const owned = ['fire', 'ice', 'stone'];

describe('campaign party cycling', () => {
  it('starts from the first or last owned guardian instead of skipping the first', () => {
    expect(cycleCampaignPrimary(owned, null, null, 1)).toEqual({ primaryId: 'fire', reserveId: null });
    expect(cycleCampaignPrimary(owned, null, null, -1)).toEqual({ primaryId: 'stone', reserveId: null });
  });

  it('changes the primary on every bumper press and wraps in both directions', () => {
    expect(cycleCampaignPrimary(owned, 'fire', null, 1)).toEqual({ primaryId: 'ice', reserveId: null });
    expect(cycleCampaignPrimary(owned, 'stone', null, 1)).toEqual({ primaryId: 'fire', reserveId: null });
    expect(cycleCampaignPrimary(owned, 'fire', null, -1)).toEqual({ primaryId: 'stone', reserveId: null });
  });

  it('keeps the reserve and swaps party roles when cycling onto it', () => {
    expect(cycleCampaignPrimary(owned, 'fire', 'stone', 1)).toEqual({ primaryId: 'ice', reserveId: 'stone' });
    expect(cycleCampaignPrimary(owned, 'fire', 'ice', 1)).toEqual({ primaryId: 'ice', reserveId: 'fire' });
  });

  it('never duplicates the sole guardian or carries an unavailable reserve', () => {
    expect(cycleCampaignPrimary(['fire'], 'fire', 'fire', 1)).toEqual({ primaryId: 'fire', reserveId: null });
    expect(cycleCampaignPrimary(owned, 'fire', 'void', 1)).toEqual({ primaryId: 'ice', reserveId: null });
    expect(cycleCampaignPrimary([], 'fire', 'ice', 1)).toEqual({ primaryId: null, reserveId: null });
  });

  it('cycles every eligible reserve and allows returning to a solo party', () => {
    expect(cycleCampaignReserve(owned, 'fire', null)).toBe('ice');
    expect(cycleCampaignReserve(owned, 'fire', 'ice')).toBe('stone');
    expect(cycleCampaignReserve(owned, 'fire', 'stone')).toBeNull();
  });

  it('requires a primary and handles an empty or single-guardian roster', () => {
    expect(cycleCampaignReserve(owned, null, null)).toBeNull();
    expect(cycleCampaignReserve([], null, null)).toBeNull();
    expect(cycleCampaignReserve(['fire'], 'fire', null)).toBeNull();
  });
});
