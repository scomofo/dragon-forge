# Nox / Venom Resonance

Nox is the planned fifth owned guardian. The expedition still has exactly two live field slots.

The browser alchemy table is authoritative: `Ice + Venom = Venom`. Native Reconnection therefore bootstraps Venom from a preserved culture rather than inventing a Fire/Stone recipe.

1. Recover the preserved **Venom Culture** in Frozen Vault.
2. Own Rime and restore at least three sector cores.
3. At Resonance Fusion, stabilize the culture with Rime. Rime is retained; there is no RNG or salvage cost.
4. Awaken Nox, then use the Guardian Nursery to put Nox in the two-slot expedition.

## Combat identity

- **Toxin Fang** — fast heat-free close strike.
- **Acid Spit** — ranged Venom attack; intended to apply one Toxin stack on a landed, unshielded hit.
- **Toxic Cloud** — persistent caster-owned Venom field; intended to apply Toxin while dealing low tick damage.
- **Septic Bloom** — radial finisher. Its target-side damage multiplier is `+25%` per Toxin stack, maximum three stacks. A fully shield-blocked Bloom must not consume Toxin.

Toxin contract: maximum three stacks, five-second duration refreshed on application, four damage per second baseline. The target owns its stacks/timer; swapping guardians does not clear them. Shields block new applications. This status is deterministic and has no random proc chance.

Nox starts at 95% of Magma's base maximum HP before permanent plating. Current numbers are provisional until human balance review.

Save schema 7 adds `venom_culture_recovered` and `venom_forged`. Valid schema-6 saves migrate in memory with both false; loading alone never writes. Existing campaign milestones, guardians, evolutions, loadout and salvage remain intact. The roster order is Fire, Ice, Storm, Stone, Venom.
