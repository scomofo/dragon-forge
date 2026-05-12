# DragonVault Hidden Gallery

## Purpose

DragonVault is an optional hidden crossover layer for Dragon Forge. It should feel like a secret archive inside the Hardware Husk, not a required second economy.

The gallery turns the player's card-grading language into world lore: original crew members, analog relic condition, and stability bonuses for gear.

## Relic Gallery

The player can find crew trading cards in technical spaces:

- Chief Maintenance Officer: Hardware Husk
- Systems Botanist: Overgrown Buffer
- Simulation Harpist: Lunar Sector

These cards represent the original Astraeus crew and explain how the pastoral wrapper, MIDI communication, and maintenance culture survived after the crash.

## Stability Grading

Relics can be graded on:

- Surface
- Corners
- Edges
- Centering

A Gem Mint 10 analog relic provides a modest bonus without becoming mandatory.

Examples:

- Gem Mint 10 10mm Wrench: better torque and stronger final Hardware Override reliability.
- Gem Mint 10 Diagnostic Lens: better scan clarity and stronger filtered Restoration.

## Implementation Hooks

- `res://scripts/sim/dragon_vault_data.gd` owns crew cards, relic grading, relic grade bonuses, and gallery progress.
- The system should remain hidden/optional until the Hardware Husk or postgame archive can surface it cleanly.

## Design Rule

DragonVault should deepen Dragon Forge, not distract from it. Collecting and grading should reward lore curiosity and small optimization, never block main-story progress.
