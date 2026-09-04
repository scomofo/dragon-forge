import { STATUS_APPLY_CHANCE, STATUS_EFFECTS } from './gameData';
import { getBattleSpeed } from './battleSpeed';

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
  const speed = getBattleSpeed();

  // C3: recovery tails are trimmed from the old fixed 200ms-class beats —
  // the next telegraph overlaps them, so a turn no longer ends in dead air.
  // C4: the whole table scales down at 2x battle speed.
  const scale = (ms) => Math.max(40, Math.round(ms * 0.6 / speed));

  return {
    ...profile,
    kind,
    anticipationMs: scale(isHeavyMove ? profile.anticipationMs + 60 : profile.anticipationMs),
    launchMs: scale(isHeavyMove ? profile.launchMs + 40 : profile.launchMs),
    recoveryMs: scale(profile.recoveryMs),
    impactPauseMs: Math.max(30, Math.round(profile.impactPauseMs / speed)),
    // Move weight: heavy attacks fly slower, light attacks snap across.
    vfxTravelMs: Math.round(((move?.power || 0) >= 70 ? 400 : 270) / speed),
    vfxImpactMs: Math.round(220 / speed),
    flashColor: move?.element && move.element !== 'neutral'
      ? profile.flashColor
      : profile.flashColor,
    statusVariant: event?.appliedStatus ? 'status' : null,
  };
}

export function getBattleResultCallout(event) {
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
