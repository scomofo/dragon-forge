// P1 battle-set loader — pose-driven sprite resolution with honest fallback.
//
// Every battle actor resolves (actorId, pose) to either a shipped sheet strip
// or the painted portrait it uses today. Nothing claims `sheet` until the art
// lands; the overlay components keep rendering portraits until then, so this
// pipeline ships with zero visual change and activates automatically per
// actor the moment its four strips exist under public/assets/battle-sets/.
//
// Sheet contract (art bible): one horizontal strip per pose,
// `<actorId>_<pose>.webp`, `frames` cells of `cell`×`cell` px (96 mid,
// 64 small, 128 final-only), 16-bit pixel grammar, transparent background.
// Frame counts come from BATTLE_FRAME_COUNTS (idle 4 / attack 6 / hurt 2 /
// faint 3). Playback timing lives in BattleSetSprite.jsx.
import { assetUrl } from './utils';
import {
  BATTLE_CELL,
  BATTLE_FRAME_COUNTS,
  BATTLE_SET_STATUS,
  DRAGON_BATTLE_SETS,
  NPC_BATTLE_SETS,
  getBattleSet,
  isBannedArtUrl,
} from './artBible';

export const BATTLE_POSES = ['idle', 'attack', 'hurt', 'faint'];

export const POSE_FRAME_DURATIONS = {
  idle: 160,
  attack: 90,
  hurt: 120,
  faint: 200,
};

const FAINT_RE = /ko|defeated|faint/;
const HURT_RE = /recoil|critical-hit|status-hit|reflect-hit/;
const ATTACK_RE = /telegraph|guard|lunge/;

export function isBattlePose(pose) {
  return BATTLE_POSES.includes(pose);
}

export function normalizeBattlePose(pose) {
  return isBattlePose(pose) ? pose : 'idle';
}

// Map live battle state onto one of the four authored poses. Precedence:
// faint > hurt > attack > idle. A miss/dodge (`whiff`) and victory
// (`celebrate`) both fall through to idle — neither is a hit reaction.
export function resolveBattlePose({ spriteClass = '', isAttacking = false, fainted = false, hp = 1, maxHp = 1 } = {}) {
  if (fainted || (maxHp > 0 && hp <= 0)) return 'faint';
  const cls = String(spriteClass || '');
  if (FAINT_RE.test(cls)) return 'faint';
  if (HURT_RE.test(cls)) return 'hurt';
  if (ATTACK_RE.test(cls)) return 'attack';
  if (isAttacking) return 'attack';
  return 'idle';
}

export function getBattleSetSheetUrl(actorId, pose) {
  return assetUrl(`/assets/battle-sets/${actorId}_${normalizeBattlePose(pose)}.png`);
}

// Resolve what to render for an actor+pose. `kind: 'portrait'` means keep
// drawing the painted still; `kind: 'sheet'` carries a shippable strip.
export function resolveBattleSprite(actorId, pose) {
  const normalized = normalizeBattlePose(pose);
  const spec = actorId ? getBattleSet(actorId) : null;
  const frames = BATTLE_FRAME_COUNTS[normalized];
  if (!spec || spec.status !== BATTLE_SET_STATUS.SHIPPED) {
    return { kind: 'portrait', actorId: actorId || null, pose: normalized, cell: spec?.cell || BATTLE_CELL.mid, frames, src: null };
  }
  return { kind: 'sheet', actorId, pose: normalized, cell: spec.cell, frames, src: getBattleSetSheetUrl(actorId, normalized) };
}

export function isBattleSetSheetLive(actorId) {
  const spec = actorId ? getBattleSet(actorId) : null;
  return spec?.status === BATTLE_SET_STATUS.SHIPPED;
}

// Every sheet URL the catalog would request once fully shipped. Used by the
// asset-manifest test to enforce existence + the banned-art filter.
export function listBattleSetSheetUrls() {
  const urls = [];
  for (const actorId of Object.keys({ ...DRAGON_BATTLE_SETS, ...NPC_BATTLE_SETS })) {
    for (const pose of BATTLE_POSES) {
      urls.push(getBattleSetSheetUrl(actorId, pose));
    }
  }
  return urls;
}

export function validateBattleSetSheetUrl(url) {
  if (isBannedArtUrl(url)) return 'banned substring';
  if (!String(url).includes('battle-sets')) return 'outside battle-sets dir';
  return null;
}
