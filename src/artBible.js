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

export function listBodyPlanIds() {
  return Object.keys(BODY_PLANS);
}

export function getBodyPlan(id) {
  return BODY_PLANS[id] || null;
}

export function uniqueSilhouettes(plans = BODY_PLANS) {
  return Object.values(plans).map((plan) => plan.silhouette);
}
