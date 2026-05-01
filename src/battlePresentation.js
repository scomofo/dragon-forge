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
};

export function classifyBattleEvent(event) {
  if (!event) return 'normalHit';
  if (event.action === 'defend') return 'defend';
  if (event.action === 'reflect') return 'reflect';
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

  return {
    ...profile,
    kind,
    anticipationMs: isHeavyMove ? profile.anticipationMs + 60 : profile.anticipationMs,
    launchMs: isHeavyMove ? profile.launchMs + 40 : profile.launchMs,
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
  };
  const text = textByVariant[variant];
  return text ? { text, variant } : null;
}

export function shouldAnimateBattleEvent(event) {
  if (!event) return false;
  if (event.attacker === 'status') return false;
  if (event.action === 'statusSkip') return false;
  return ['attack', 'defend', 'reflect'].includes(event.action);
}
