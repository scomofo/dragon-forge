# Cairn / Stone Resonance

Cairn is the fourth owned guardian. The expedition still has exactly two live slots.

1. Reach Admin Vault and recover the **Stone Imprint** from the right-hand plinth. It is independent of the salvage cache.
2. Restore at least three sector cores and return to the Forge.
3. At **Resonance Fusion** choose **Temper Stone imprint / keep Magma**, then **Awaken Cairn / free**.
4. Visit the Guardian Nursery to equip Cairn as the reserve of the current active guardian; Tab swaps the selected pair.

This adapts the browser alchemy law `Fire + Stone = Stone`. The imprint supplies the Stone side of the recipe; Magma is not consumed. No RNG or salvage cost is involved.

## Cairn combat

- Granite Knuckle: heat-free close strike.
- Fault Line: medium-range Stone rupture.
- Bulwark Field: persistent caster-owned Stone field; swapping does not reassign it.
- Earthshatter: radial finisher.

Cairn builds one Resolve (maximum 3) when a real incoming hit lands while Cairn is guarding. Earthshatter gains +20% technique damage per stored Resolve. Resolve is consumed only if Earthshatter actually damages an enemy. A closed shield therefore preserves it. Dodging, swapping and failed casts do not generate Resolve.

Cairn has 15% higher base maximum health than Magma before permanent plating. Existing modules/upgrades apply. Current numbers are provisional until human balance review.

Save schema 6 adds `stone_imprint_recovered` and `stone_forged`. Valid schema-5 saves migrate in memory with both false; load does not write. The next normal write uses the existing backup behavior. Existing guardians, evolutions, loadout, salvage and milestones are retained.
