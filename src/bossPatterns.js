// Authored encounter scripts. P4 executes all 13 from battleEngine — options-
// based engine hooks + per-boss screen state; mirror_admin_reset (the last
// deferral) lives on per-phase move history plus the player-faint punish hook.
// Docs: design/gdd/snes-aaa-roadmap.md

export const BOSS_PATTERNS = {
  firewall_sentinel: {
    id: 'firewall_sentinel',
    tell: 'Raises a packet shield. The enemy signal shows SHIELD CLOSED until you Defend.',
    rule: 'Incoming damage is 0 unless the hit is Phase Strike or the player Defended last turn (wait out the cycle).',
    executedByBattleEngine: true,
  },
  buffer_overflow: {
    id: 'buffer_overflow',
    tell: 'A live heat meter builds toward four stacks.',
    rule: 'After 4 stacks, Magma Breath becomes forced and burns the user for 10% max HP.',
    executedByBattleEngine: true,
  },
  bit_wraith: {
    id: 'bit_wraith',
    tell: 'After a miss, the wraith phases — next hit ignores Defend.',
    rule: 'A miss sets a one-turn pierce flag. Signature Void Unravel still waits for 50% HP.',
    executedByBattleEngine: true,
  },
  crypto_crab: {
    id: 'crypto_crab',
    tell: 'Type chip reads ENCRYPTED until you strike with the last element you used.',
    rule: 'Hides defender element. Reveals when the incoming element equals the previous incoming element.',
    executedByBattleEngine: true,
  },
  phishing_siren: {
    id: 'phishing_siren',
    tell: 'Lure pulse. Bench slot 1 flashes as if already swapped.',
    rule: 'On turn 2 and 5 the siren forces a bench swap if a reserve exists, then gets a free Toxic Cloud.',
    executedByBattleEngine: true,
  },
  glitch_hydra: {
    id: 'glitch_hydra',
    tell: 'Three heads. A live counter shows how many you have broken.',
    rule: 'Three super-effective strikes break the heads and release the 30% HP lock. Repeated elements count.',
    executedByBattleEngine: true,
  },
  logic_bomb: {
    id: 'logic_bomb',
    tell: 'A live fuse counts down from 6 beside the turn counter.',
    rule: 'If the fight reaches turn 7 with the bomb alive, Final Detonation hits and cannot miss.',
    executedByBattleEngine: true,
  },
  recursive_golem: {
    id: 'recursive_golem',
    tell: 'Harden loops. DEF stacks visible as nested brackets.',
    rule: 'Every other turn casts Harden. At 3 stacks Tectonic Rupture is forced and clears the stacks.',
    executedByBattleEngine: true,
  },
  protocol_vulture: {
    id: 'protocol_vulture',
    tell: 'At half HP the vulture perches — next action is Soul Drain.',
    rule: 'Signature still fires at 50%. Drain heals 40% of damage and applies Blind if it lands.',
    executedByBattleEngine: true,
  },
  data_corruption: {
    id: 'data_corruption',
    tell: 'The enemy signal names a corrupted move and its remaining uses.',
    rule: 'On turn 1 and after each Burn apply, a random non-signature move is replaced by basic_attack.',
    executedByBattleEngine: true,
  },
  memory_leak: {
    id: 'memory_leak',
    tell: 'DEF climbs a pip at the end of every enemy turn.',
    rule: 'Permanent +10% DEF per turn, cap +50%. Any landed Ice strike resets the leak, even when resisted.',
    executedByBattleEngine: true,
  },
  stack_overflow: {
    id: 'stack_overflow',
    tell: 'Speed doubles after the first Thunder Clap.',
    rule: 'Once per battle, after a Thunder Clap hits, SPD ×2 for two turns. Then it crashes and skips.',
    executedByBattleEngine: true,
  },
  mirror_admin_reset: {
    id: 'mirror_admin_reset',
    tell: 'Phase 3 whispers the Great Reset. A clean-save pip fills each KO.',
    rule: 'If the player faints a dragon in Phase 3 without having spent Restoration or Recompile this phase, Mirror Admin heals 25% max HP.',
    executedByBattleEngine: true,
  },
};

export function getBossPattern(id) {
  return BOSS_PATTERNS[id] || null;
}
