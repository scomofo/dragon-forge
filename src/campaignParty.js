// Controller cycling selects a slot directly. Pointer clicks retain the
// existing primary/reserve toggle rules in CampaignMapScreen.
export function cycleCampaignPrimary(ownedIds, primaryId, reserveId, direction) {
  if (!ownedIds.length) return { primaryId: null, reserveId: null };
  const index = ownedIds.indexOf(primaryId);
  const nextIndex = index < 0
    ? (direction > 0 ? 0 : ownedIds.length - 1)
    : (index + direction + ownedIds.length) % ownedIds.length;
  const nextPrimary = ownedIds[nextIndex];
  const nextReserve = nextPrimary === reserveId ? primaryId : reserveId;
  return {
    primaryId: nextPrimary,
    reserveId: nextReserve !== nextPrimary && ownedIds.includes(nextReserve) ? nextReserve : null,
  };
}

export function cycleCampaignReserve(ownedIds, primaryId, reserveId) {
  if (!ownedIds.includes(primaryId)) return null;
  const choices = [null, ...ownedIds.filter(id => id !== primaryId)];
  const index = Math.max(0, choices.indexOf(reserveId));
  return choices[(index + 1) % choices.length];
}
