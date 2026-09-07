# Nox / Venom Resonance

Nox is the fifth owned guardian. Expeditions still contain exactly two live guardians.

The native bootstrap preserves the browser alchemy result **Ice + Venom = Venom**. A preserved Venom culture supplies the Venom parent; Rime stabilizes it without being consumed.

1. Rescue and hatch Rime, restore at least three sector cores, and revisit Frozen Vault.
2. Recover the **Venom Culture** from its separate preservation plinth. This does not consume the Ice egg or cache reward.
3. Return to Resonance Fusion and stabilize the culture with Rime.
4. Awaken Nox, then equip Nox at the Guardian Nursery. Existing guardians and progression remain owned.

## Combat

- **Toxin Fang** — quick heat-free bite; a landed hit applies one Toxin stack.
- **Acid Spit** — ranged acid; a landed hit applies one Toxin stack.
- **Toxic Cloud** — persistent Venom field; each damaging tick can build Toxin, capped at three.
- **Septic Bloom** — radial finisher; +25% damage per Toxin stack on that target, up to +75%.

Toxin lasts five seconds from the most recent successful application and ticks once per second for 4 damage per stack. A shield blocks the original Venom hit and therefore blocks new Toxin. Once applied, Toxin damage continues through a re-closed shield because the status is already inside the target. Septic Bloom consumes that target's Toxin only when the Bloom itself deals damage; a shield-blocked Bloom preserves the stacks.

These numbers are deterministic provisional balance values. They require human balance review after the automated acceptance gates.

Save schema 7 adds `venom_culture_recovered` and `venom_forged`. Valid schema-6 saves migrate in memory with both false. Loading alone never writes; the next successful campaign write retains the existing exact previous-byte backup behavior.
