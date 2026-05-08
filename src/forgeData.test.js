import { describe, expect, it } from 'vitest';
import { getUsedRelicSlots, canEquipRelic } from './forgeData';

describe('Forge relic slot rules', () => {
  it('counts relic slotCost instead of only equipped relic count', () => {
    expect(getUsedRelicSlots(['iron_knuckle', 'phase_lens'])).toBe(3);
  });

  it('blocks equipping a relic whose slotCost exceeds remaining slots', () => {
    expect(canEquipRelic({
      relicId: 'phase_lens',
      owned: ['iron_knuckle', 'phase_lens'],
      equipped: ['iron_knuckle'],
      slots: 2,
    })).toBe(false);
  });
});
