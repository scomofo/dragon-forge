import { STATUS_APPLY_CHANCE, STATUS_EFFECTS } from './gameData';
import { getTypeEffectivenessLabel } from './battleEngine';

const BASE_PROFILES = {
  defend: {
    kind: 'defend',
    anticipationMs: 240,
    launchMs: 0,
    impactPauseMs: 0,
    recoveryMs: 180,
    shake: 0,
    flashColor: '#66ccff',
    attackerClass: 'sprite-guard',
    defenderClass: '',
    damageVariant: 'guard',
    sound: 'defend',
  },
  reflect: {
    kind: 'reflect',
    anticipationMs: 300,
    launchMs: 260,
    impactPauseMs: 90,
    recoveryMs: 240,
    shake: 5,
    flashColor: '#b388ff',
    attackerClass: 'sprite-telegraph-heavy',
    defenderClass: 'sprite-reflect-hit',
    damageVariant: 'reflect',
    sound: 'shieldDeflectSting',
  },
  miss: {
    kind: 'miss',
    anticipationMs: 220,
    launchMs: 260,
    impactPauseMs: 0,
    recoveryMs: 170,
    shake: 0,
    flashColor: '#777777',
    attackerClass: 'sprite-telegraph',
    defenderClass: 'sprite-whiff',
    damageVariant: 'miss',
    sound: 'miss',
  },
  resistedHit: {
    kind: 'resistedHit',
    anticipationMs: 240,
    launchMs: 300,
    impactPauseMs: 45,
    recoveryMs: 190,
    shake: 3,
    flashColor: '#99a0aa',
    attackerClass: 'sprite-telegraph',
    defenderClass: 'sprite-recoil-soft',
    damageVariant: 'resisted',
    sound: 'resisted',
  },
  normalHit: {
    kind: 'normalHit',
    anticipationMs: 260,
    launchMs: 320,
    impactPauseMs: 60,
    recoveryMs: 200,
    shake: 5,
    flashColor: '#ffffff',
    attackerClass: 'sprite-telegraph',
    defenderClass: 'sprite-recoil',
    damageVariant: 'normal',
    sound: 'attackHit',
  },
  effectiveHit: {
    kind: 'effectiveHit',
    anticipationMs: 300,
    launchMs: 330,
    impactPauseMs: 90,
    recoveryMs: 220,
    shake: 8,
    flashColor: '#ff6644',
    attackerClass: 'sprite-telegraph-heavy',
    defenderClass: 'sprite-recoil-heavy',
    damageVariant: 'super-effective',
    sound: 'superEffective',
  },
  criticalHit: {
    kind: 'criticalHit',
    anticipationMs: 340,
    launchMs: 340,
    impactPauseMs: 120,
    recoveryMs: 260,
    shake: 11,
    flashColor: '#ffcc00',
    attackerClass: 'sprite-telegraph-heavy',
    defenderClass: 'sprite-critical-hit',
    damageVariant: 'critical',
    sound: 'criticalHit',
  },
  ko: {
    kind: 'ko',
    anticipationMs: 320,
    launchMs: 340,
    impactPauseMs: 140,
    recoveryMs: 320,
    shake: 10,
    flashColor: '#ffffff',
    attackerClass: 'sprite-telegraph-heavy',
    defenderClass: 'sprite-ko-hit',
    damageVariant: 'ko',
    sound: 'ko',
  },
  status: {
    kind: 'status',
    anticipationMs: 0,
    launchMs: 0,
    impactPauseMs: 50,
    recoveryMs: 240,
    shake: 2,
    flashColor: '#44cc66',
    attackerClass: '',
    defenderClass: 'sprite-status-hit',
    damageVariant: 'status',
    sound: 'statusApply',
  },
  buff: {
    kind: 'buff',
    anticipationMs: 200,
    launchMs: 0,
    impactPauseMs: 60,
    recoveryMs: 300,
    shake: 0,
    flashColor: '#ffffaa',
    attackerClass: 'sprite-telegraph',
    defenderClass: '',
    damageVariant: 'buff',
    sound: 'statusApply',
  },
  heal: {
    kind: 'heal',
    anticipationMs: 180,
    launchMs: 0,
    impactPauseMs: 40,
    recoveryMs: 280,
    shake: 0,
    flashColor: '#88ffcc',
    attackerClass: 'sprite-telegraph',
    defenderClass: '',
    damageVariant: 'buff',
    sound: 'statusApply',
  },
  charge: {
    kind: 'charge',
    anticipationMs: 400,
    launchMs: 0,
    impactPauseMs: 0,
    recoveryMs: 200,
    shake: 0,
    flashColor: '#ffaa00',
    attackerClass: 'sprite-telegraph-heavy',
    defenderClass: '',
    damageVariant: 'charge',
    sound: 'attackLaunch',
  },
};

export function classifyBattleEvent(event) {
  if (!event) return 'normalHit';
  if (event.action === 'defend') return 'defend';
  if (event.action === 'reflect') return 'reflect';
  if (event.action === 'buff') return 'buff';
  if (event.action === 'heal') return 'heal';
  if (event.action === 'charge') return 'charge';
  if (event.action === 'statusSkip') return 'miss';
  if (event.attacker === 'status') return 'status';
  if (event.action !== 'attack') return 'normalHit';
  if (!event.hit) return 'miss';
  if (event.reflected) return 'reflect';
  if ((event.targetHp ?? 1) <= 0) return 'ko';
  if (event.isCritical) return 'criticalHit';
  if (event.effectiveness > 1) return 'effectiveHit';
  if (event.effectiveness < 1) return 'resistedHit';
  return 'normalHit';
}

export function getBattlePresentationProfile(event, move = null) {
  const kind = classifyBattleEvent(event);
  const profile = BASE_PROFILES[kind] || BASE_PROFILES.normalHit;
  const isHeavyMove = (move?.power || 0) >= 70;

  // C3: recovery tails are trimmed from the old fixed 200ms-class beats —
  // the next telegraph overlaps them, so a turn no longer ends in dead air.
  // Keep these durations at 1×. battleWait and GSAP already apply battle
  // speed; scaling here too made anticipation, recovery and hit-stop run at 4×.
  const scale = (ms) => Math.max(40, Math.round(ms * 0.6));

  return {
    ...profile,
    kind,
    anticipationMs: scale(isHeavyMove ? profile.anticipationMs + 60 : profile.anticipationMs),
    launchMs: scale(isHeavyMove ? profile.launchMs + 40 : profile.launchMs),
    recoveryMs: scale(profile.recoveryMs),
    impactPauseMs: Math.max(30, Math.round(profile.impactPauseMs)),
    // Move weight: heavy attacks fly slower, light attacks snap across.
    vfxTravelMs: (move?.power || 0) >= 70 ? 400 : 270,
    vfxImpactMs: 220,
    flashColor: move?.element && move.element !== 'neutral'
      ? profile.flashColor
      : profile.flashColor,
    statusVariant: event?.appliedStatus ? 'status' : null,
  };
}

// Apply poses at contact, before recovery. Reflected damage recoils its source;
// a miss can whiff, but a blocked/zero-damage hit must not fake a hurt reaction.
export function hasDamagingImpact(event) {
  return !!event.hit && !event.blocked && event.damage > 0;
}

export function getBattleContactState(event, profile = getBattlePresentationProfile(event)) {
  const isPlayer = event.attacker === 'player';
  const target = event.reflected ? event.attacker : isPlayer ? 'npc' : 'player';
  const state = {
    playerSpriteClass: isPlayer ? 'sprite-lunge' : '',
    npcSpriteClass: isPlayer ? '' : 'sprite-lunge',
    playerForcedFrame: isPlayer ? 3 : null,
    npcAttacking: !isPlayer,
  };
  if (!event.hit) {
    state[`${target}SpriteClass`] = profile.defenderClass || 'sprite-whiff';
  } else if (hasDamagingImpact(event)) {
    state[`${target}SpriteClass`] = profile.defenderClass || 'sprite-recoil';
  }
  return state;
}

export function getBattleResultCallout(event) {
  if (event?.blocked) return { text: 'BLOCKED', variant: 'blocked' };
  const variant = classifyBattleEvent(event);
  const textByVariant = {
    miss: 'MISS',
    resistedHit: 'RESIST',
    effectiveHit: 'SUPER HIT',
    criticalHit: 'CRITICAL',
    reflect: 'REFLECT',
    ko: 'KO',
    buff: 'FORTIFY',
    charge: 'CHARGING',
    heal: 'RESTORE',
  };
  const text = textByVariant[variant];
  return text ? { text, variant } : null;
}

// === FORMAL TELL VOCABULARY ===
// Every boss telegraph — NPC charge wind-ups, signature pre-warnings, and the
// authored boss-pattern beats — fires through ONE presentation contract:
// { icon, text, variant: 'tell' }, rendered by the battle-callout banner.
// The banner is the beat-level moment shown BEFORE the boss acts; the
// BattleCues chips stay the persistent layer. The pattern's full `tell` prose
// still lives in bossPatterns.js; `intro` condenses it to the one-line banner
// shown before the boss's first turn, and `beats` cover each pattern's
// committed mid-battle moments (fired when the script actually commits).
export const TELL_VARIANT = 'tell';

const PATTERN_TELL_BANNERS = {
  firewall_sentinel: {
    intro: { icon: '🛡️', text: 'PACKET SHIELD UP — DEFEND, THEN STRIKE' },
    beats: {},
  },
  buffer_overflow: {
    intro: { icon: '🌡️', text: 'HEAT BUILDING — MAGMA BREATH AT 4 STACKS' },
    beats: {
      overheat: { icon: '🔥', text: 'OVERHEAT — MAGMA BREATH FORCED!' },
    },
  },
  bit_wraith: {
    intro: { icon: '👁️', text: 'PHASE WATCH — A MISS MAKES IT PIERCE DEFEND' },
    beats: {
      phase: { icon: '🌀', text: 'IT PHASES — NEXT HIT IGNORES DEFEND!' },
    },
  },
  crypto_crab: {
    intro: { icon: '🔒', text: 'ENCRYPTED — REPEAT AN ELEMENT TO CRACK IT' },
    beats: {
      decrypted: { icon: '🔓', text: 'ENCRYPTION CRACKED — DAMAGE OPENS!' },
    },
  },
  phishing_siren: {
    intro: { icon: '🎣', text: 'LURE PULSE — WATCH TURNS 2 AND 5' },
    beats: {
      lure: { icon: '🎣', text: 'LURED — COMMAND INTERRUPTED!' },
    },
  },
  glitch_hydra: {
    intro: { icon: '🐉', text: 'THREE HEADS — BREAK THEM WITH SUPER-EFFECTIVE HITS' },
    beats: {
      headBroken: { icon: '💢', text: 'HEAD DOWN — KEEP HITTING ITS WEAKNESS' },
      lockBroken: { icon: '🔓', text: 'HP LOCK BROKEN — FINISH IT!' },
    },
  },
  logic_bomb: {
    intro: { icon: '⏳', text: 'FUSE BURNING — DETONATION AT ZERO' },
    beats: {
      detonation: { icon: '💥', text: 'FINAL DETONATION — DEFEND OR FINISH IT!' },
    },
  },
  recursive_golem: {
    intro: { icon: '🧱', text: 'HARDEN LOOPS — RUPTURE AT 3 STACKS' },
    beats: {
      rupture: { icon: '🌋', text: 'RUPTURE — TECTONIC RUPTURE FORCED!' },
    },
  },
  protocol_vulture: {
    intro: { icon: '🦅', text: 'PERCH AT HALF HP — SOUL DRAIN NEXT' },
    beats: {
      perch: { icon: '🦅', text: 'PERCHED — SOUL DRAIN INCOMING!' },
    },
  },
  data_corruption: {
    intro: { icon: '📼', text: 'CORRUPTION WATCH — BURN GARBLES A MOVE' },
    beats: {
      corrupted: { icon: '⚠️', text: 'MOVE CORRUPTED — FIRES AS BASIC ATTACK' },
    },
  },
  memory_leak: {
    intro: { icon: '💧', text: 'LEAK GROWING — ICE RESETS THE BUILDUP' },
    beats: {
      maxed: { icon: '🌊', text: 'LEAK MAXED — ICE RESETS IT!' },
    },
  },
  stack_overflow: {
    intro: { icon: '⚡', text: 'SURGE WATCH — THUNDER CLAP DOUBLES SPEED' },
    beats: {
      surge: { icon: '⚡', text: 'SURGE — SPEED DOUBLED FOR TWO TURNS!' },
      crash: { icon: '💥', text: 'SYSTEM CRASH — IT SKIPS THE TURN!' },
    },
  },
  mirror_admin_reset: {
    intro: { icon: '🪞', text: 'GREAT RESET ARMED — A PHASE-3 KO HEALS IT' },
    beats: {
      reset: { icon: '🪞', text: 'GREAT RESET — HEALED 25% MAX HP!' },
    },
  },
};

export function getTellCallout({ kind, npcName = '', moveName = '', patternId = null, beat = null } = {}) {
  if (kind === 'charge' && moveName) {
    return { icon: '⚡', text: `${npcName} is winding up ${moveName}!`.toUpperCase(), variant: TELL_VARIANT };
  }
  if (kind === 'signature' && moveName) {
    return { icon: '💥', text: `Signature — ${npcName} unleashes ${moveName}!`.toUpperCase(), variant: TELL_VARIANT };
  }
  if (kind === 'pattern' && patternId) {
    const entry = PATTERN_TELL_BANNERS[patternId];
    if (!entry) return null;
    const banner = (beat && entry.beats[beat]) || (!beat && entry.intro);
    return banner ? { ...banner, variant: TELL_VARIANT } : null;
  }
  return null;
}

export function shouldAnimateBattleEvent(event) {
  if (!event) return false;
  if (event.attacker === 'status') return false;
  if (event.action === 'statusSkip') return false;
  return ['attack', 'defend', 'reflect', 'buff', 'heal'].includes(event.action);
}

export function getStatusMoveSummary(move) {
  if (!move?.canApplyStatus) return null;
  const effect = STATUS_EFFECTS[move.element];
  if (!effect) return null;

  const summaryByType = {
    dot: 'Damage over time',
    skip: 'Stops the next action',
    maySkip: 'Chance to lose an action',
    debuff: effect.name === 'Blind' ? 'Lowers accuracy' : 'Weakens defenses',
    randomize: 'Scrambles the next action',
  };

  const applyPct = Math.round((move.applyChance ?? STATUS_APPLY_CHANCE) * 100);
  return {
    label: `${effect.name.toUpperCase()} ${applyPct}%`,
    title: effect.name,
    duration: `${effect.duration} ${effect.duration === 1 ? 'turn' : 'turns'}`,
    summary: summaryByType[effect.type] || 'Applies a status effect',
  };
}

export function getSignatureSummary(move) {
  if (!move?.isSignature) return null;
  if (move.actionType === 'heal') {
    return { label: `HEAL ${Math.round((move.healPercent || 0.25) * 100)}%`, title: 'Heal and cleanse' };
  }
  if (move.actionType === 'buff') {
    const stat = (move.buffStat || 'atk').toUpperCase();
    const pct = Math.round(((move.buffMultiplier || 1) - 1) * 100);
    return { label: `${stat} +${pct}%`, title: 'Once per battle' };
  }
  if (move.actionType === 'defendPlus') {
    const pct = Math.round(((move.defBuff || 1.4) - 1) * 100);
    return { label: `GUARD +${pct}%`, title: 'Defend and fortify' };
  }
  if (move.lifesteal) {
    return { label: `DRAIN ${Math.round(move.lifesteal * 100)}%`, title: 'Lifesteal' };
  }
  if (move.ignoreDefend) {
    return { label: 'PIERCE', title: 'Ignores Defend' };
  }
  if (move.copyAdvantage) {
    return { label: 'ADAPT', title: 'Copies type advantage' };
  }
  if ((move.applyChance ?? 0) >= 1) {
    return { label: 'LOCK 100%', title: 'Guaranteed status' };
  }
  return { label: 'SIG', title: 'Once per battle' };
}

// === TYPE EFFECTIVENESS BADGES ===
// Always-visible, touch-legible chips rendered next to each move name on the
// battle move buttons. Pure data: a compact symbol + short label plus the
// existing matchup CSS class (advantage/resisted/normal) so the badge colors
// stay consistent with the .move-btn matchup styling. The full matchup word
// remains in .move-meta for the tooltip.
export const EFFECTIVENESS_BADGES = {
  ADVANTAGE: { symbol: '▲', text: 'SE', matchClass: 'advantage' },
  RESISTED: { symbol: '▼', text: 'RES', matchClass: 'resisted' },
  NORMAL: { symbol: '●', text: 'NEUT', matchClass: 'normal' },
};

export function getEffectivenessBadge(moveElement, defenderElement) {
  const label = getTypeEffectivenessLabel(moveElement, defenderElement);
  return EFFECTIVENESS_BADGES[label] || EFFECTIVENESS_BADGES.NORMAL;
}

// === Post-loss fight recap (gameplay plan #6) ===
// buildDefeatRecap is pure: given the bounded per-turn fight records captured
// in BattleScreen and the turn the fight was lost on, it explains the biggest
// single hit taken and, for symmetry, the biggest hit dealt.
function formatEffectiveness(value) {
  return String(Math.round(value * 100) / 100);
}

export function buildDefeatRecap(fightRecords, turnCount) {
  const records = Array.isArray(fightRecords) ? fightRecords : [];
  const hitsTaken = records.filter((r) => r.attacker === 'npc' && (r.damage ?? 0) > 0);
  const hitsDealt = records.filter((r) => r.attacker === 'player' && (r.damage ?? 0) > 0);
  const biggestHitTaken = hitsTaken.length
    ? hitsTaken.reduce((a, b) => (b.damage > a.damage ? b : a))
    : null;
  const biggestHitDealt = hitsDealt.length
    ? hitsDealt.reduce((a, b) => (b.damage > a.damage ? b : a))
    : null;

  const causes = [];
  let summary = null;
  if (biggestHitTaken) {
    const effectiveness = biggestHitTaken.effectiveness ?? 1;
    if (effectiveness > 1) causes.push(`super-effective ×${formatEffectiveness(effectiveness)}`);
    else if (effectiveness < 1) causes.push(`resisted ×${formatEffectiveness(effectiveness)}`);
    if (biggestHitTaken.wasCharged) causes.push('opponent charged');
    if (biggestHitTaken.isCritical) causes.push('critical hit');
    // Defend halves damage only for the turn it is used, so a hit landing the
    // turn after a defend means the guard had already expired.
    const defendedPrevTurn = records.some(
      (r) => r.turn === biggestHitTaken.turn - 1 && r.playerDefended
    );
    if (defendedPrevTurn && !biggestHitTaken.playerDefended) causes.push('your defend expired');

    const chargedPrefix = biggestHitTaken.wasCharged ? 'charged ' : '';
    summary = `Turn ${biggestHitTaken.turn} — ${chargedPrefix}${biggestHitTaken.moveName} hit for ${biggestHitTaken.damage}${causes.length ? `: ${causes.join(' × ')}` : ''}.`;
  }

  const dealtSummary = biggestHitDealt
    ? `Your biggest hit: ${biggestHitDealt.moveName} for ${biggestHitDealt.damage}.`
    : null;

  return { lostTurn: turnCount, biggestHitTaken, biggestHitDealt, causes, summary, dealtSummary };

}
