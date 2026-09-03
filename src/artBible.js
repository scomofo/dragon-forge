// Binding art-register data. Docs: design/gdd/art-bible.md
// Portraits (journal) may stay painted. Battle actors must share a body plan.

export const BATTLE_CELL = {
  small: 64,
  mid: 96,
  large: 128,
  arenaWidth: 320,
  arenaHeight: 176,
};

export const BATTLE_FRAME_COUNTS = {
  idle: 4,
  attack: 6,
  hurt: 2,
  faint: 3,
};

export const BODY_PLANS = {
  fire: {
    name: 'Magma Dragon',
    plan: 'hex-scale biped',
    silhouette: 'wide-diamond-horns',
    notes: 'Barrel chest, lava-plate shoulders. Hatchling is the same plan, smaller.',
  },
  ice: {
    name: 'Ice Dragon',
    plan: 'faceted quadruped',
    silhouette: 'long-low-spike-row',
    notes: 'Crystal ridge spine, low center of gravity.',
  },
  storm: {
    name: 'Storm Dragon',
    plan: 'ribbon serpentine',
    silhouette: 'thin-s-curve',
    notes: 'One continuous S. No walking legs.',
  },
  stone: {
    name: 'Stone Dragon',
    plan: 'block golem',
    silhouette: 'square-stack',
    notes: 'Right angles, tiny head, weight in the torso.',
  },
  venom: {
    name: 'Venom Dragon',
    plan: 'frilled wyrm',
    silhouette: 'hood-triangle-whip',
    notes: 'Hood plus trailing tail. Not a biped.',
  },
  shadow: {
    name: 'Shadow Dragon',
    plan: 'negative-space gap',
    silhouette: 'holed-wolf',
    notes: 'Broken contour, missing chunks. Reads as a hole.',
  },
  void: {
    name: 'Void Dragon',
    plan: 'hollow crystal tetra',
    silhouette: 'empty-diamond',
    notes: 'Frame only, inner glow, no flesh.',
  },
  light: {
    name: 'Light Dragon',
    plan: 'stained-glass winged biped',
    silhouette: 'wing-chevron-panes',
    notes: 'Hard panes. Gold/white only — no storm-violet.',
  },
  synthesis: {
    name: 'Synthesis',
    plan: 'void frame filled with light panes',
    silhouette: 'diamond-frame-pane-fill',
    notes: 'Must read as void + light combined, not a tenth animal.',
  },
};

export const BANNED_ART_SUBSTRINGS = ['404', 'error', 'gemini', 'watermark'];

// P1.1 — leftover arena files that must never be referenced by battle code.
// `fire.webp` carries baked-in type labels; the gravity-chamber grid paper is
// tracked separately as the one known placeholder (see KNOWN_PLACEHOLDER_ARENAS).
export const BANNED_ARENA_SUBSTRINGS = ['arenas/fire.webp', 'arenas/fire.png'];

export function isBannedArtUrl(url) {
  const haystack = String(url || '').toLowerCase();
  return BANNED_ART_SUBSTRINGS.some((banned) => haystack.includes(banned))
    || BANNED_ARENA_SUBSTRINGS.some((banned) => haystack.includes(banned));
}

// P1.1 — arenas ship at 320×176 logical from 1024² sources. The final-boss
// chamber is still the 696×344 grid-paper placeholder; it stays referenced
// until the authored replacement lands, and this list keeps it honest.
export const KNOWN_PLACEHOLDER_ARENAS = ['gravity_chamber'];

export function isKnownPlaceholderArena(url) {
  return KNOWN_PLACEHOLDER_ARENAS.some((slug) => String(url || '').includes(slug));
}

// Hue-rotate / grayscale CSS filters are juice, not content. A new actor or
// arena must ship its own cells — never a filter over another sprite.
export const BANNED_FILTER_SUBSTRINGS = ['hue-rotate', 'grayscale'];

export function hasBannedFilter(filter) {
  const haystack = String(filter || '').toLowerCase();
  return BANNED_FILTER_SUBSTRINGS.some((banned) => haystack.includes(banned));
}

// P1.3–P1.5 — battle frame-set contract. Real sets ship idle 4 / attack 6 /
// hurt 2 / faint 3 at one shared cell (96 mid, 64 small, 128 final only).
// Everything below is honestly `portrait-only` until the sheets land; the
// loader falls back to the painted stage portrait and the tests enforce that
// no entry claims `shipped` without meeting the counts + cell + path rules.
export const BATTLE_SET_STATUS = {
  PORTRAIT_ONLY: 'portrait-only',
  SHIPPED: 'shipped',
};

const battleSetEntry = (actorId, kind) => ({
  actorId,
  kind,
  status: BATTLE_SET_STATUS.PORTRAIT_ONLY,
  cell: BATTLE_CELL.mid,
  frames: { ...BATTLE_FRAME_COUNTS },
});

// Stage-3 battle sets for the 9 journal dragons (P1.3).
export const DRAGON_BATTLE_SETS = Object.fromEntries(
  listBodyPlanIds().map((id) => [id, battleSetEntry(id, 'dragon-stage3')]),
);

// NPC battle sets at the same cell size (P1.4).
export const NPC_BATTLE_SET_IDS = [
  'firewall_sentinel',
  'bit_wraith',
  'glitch_hydra',
  'recursive_golem',
  'buffer_overflow',
  'crypto_crab',
  'logic_bomb',
  'phishing_siren',
  'protocol_vulture',
];

export const NPC_BATTLE_SETS = Object.fromEntries(
  NPC_BATTLE_SET_IDS.map((id) => [id, battleSetEntry(id, 'npc')]),
);

export function getBattleSet(actorId) {
  return DRAGON_BATTLE_SETS[actorId] || NPC_BATTLE_SETS[actorId] || null;
}

export function isBattleSetShipped(actorId) {
  return getBattleSet(actorId)?.status === BATTLE_SET_STATUS.SHIPPED;
}

export function validateBattleSetSpec(spec) {
  if (!spec) return 'missing spec';
  if (![BATTLE_CELL.small, BATTLE_CELL.mid, BATTLE_CELL.large].includes(spec.cell)) {
    return `bad cell ${spec.cell}`;
  }
  for (const [pose, count] of Object.entries(BATTLE_FRAME_COUNTS)) {
    if (spec.frames?.[pose] !== count) return `bad ${pose} count`;
  }
  return null;
}

export function listBodyPlanIds() {
  return Object.keys(BODY_PLANS);
}

export function getBodyPlan(id) {
  return BODY_PLANS[id] || null;
}

export function uniqueSilhouettes(plans = BODY_PLANS) {
  return Object.values(plans).map((plan) => plan.silhouette);
}
