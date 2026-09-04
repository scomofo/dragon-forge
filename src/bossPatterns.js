// Authored encounter scripts. P4 executes 12 of 13 from battleEngine via the
// options/plumbing layer (packet-shield, encryption, pierce, head-lock, fuse,
// harden stacks, drain, garble, leak pips, surge/crash, force-swaps, forced
// moves). mirror_admin_reset needs cross-phase move tracking and is deferred.
// Docs: design/gdd/snes-aaa-roadmap.md

export const BOSS_PATTERNS = {
  firewall_sentinel: {
    id: 'firewall_sentinel',
    tell: 'Raises a packet-shield for two turns. EDGE reads BLOCKED.',
    rule: 'Incoming damage is 0 unless the hit is Phase Strike or the player Defended last turn (wait out the cycle).',
    executedByBattleEngine: true,
  },
  buffer_overflow: {
    id: 'buffer_overflow',
    tell: 'Heat stack ticks up in the combat feed each turn.',
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
    tell: 'Three heads. Each head falls only to a different element.',
    rule: 'Requires three super-effective hits of three distinct elements before HP can drop below 30%.',
    executedByBattleEngine: true,
  },
  logic_bomb: {
    id: 'logic_bomb',
    tell: 'A turn fuse counts down from 6 in the feed.',
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
    tell: 'One player move slot garbles into BASIC for two turns.',
    rule: 'On turn 1 and after each Burn apply, a random non-signature move is replaced by basic_attack.',
    executedByBattleEngine: true,
  },
  memory_leak: {
    id: 'memory_leak',
    tell: 'DEF climbs a pip at the end of every enemy turn.',
    rule: 'Permanent +10% DEF per turn, cap +50%. Ice super-effective hits reset the leak.',
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
    executedByBattleEngine: false,
  },
};

export function getBossPattern(id) {
  return BOSS_PATTERNS[id] || null;
}
