import gsap from 'gsap';
import { elementColors, STATUS_EFFECTS } from './gameData';

// === SCREEN SHAKE (smooth, ambient) ===
export function screenShake(container, intensity = 6, duration = 0.2) {
  const cycles = Math.round(duration / 0.05);
  return gsap.to(container, {
    x: `random(-${intensity}, ${intensity})`,
    y: `random(-${intensity}, ${intensity})`,
    duration: 0.05,
    repeat: cycles,
    yoyo: true,
    ease: 'power2.inOut',
    onComplete() {
      gsap.set(container, { x: 0, y: 0 });
    },
  });
}

// === PIXEL SHAKE (NES square-wave snap) ===
// Hard left/right integer-pixel snaps with no easing — crunchier impact feel
// than smooth screenShake. Use on every hit; reserve screenShake for ambient.
export function pixelShake(container, intensity = 5, duration = 0.18) {
  const step = 0.04;
  const cycles = Math.max(2, Math.round(duration / step));
  const tl = gsap.timeline({
    onComplete() { gsap.set(container, { x: 0, y: 0 }); },
  });
  for (let i = 0; i < cycles; i++) {
    const decay = 1 - i / cycles;
    const amp = Math.max(1, Math.round(intensity * decay));
    const dx = (i % 2 === 0 ? -amp : amp);
    const dy = ((i % 4 < 2) ? 0 : (i % 2 === 0 ? -1 : 1));
    tl.set(container, { x: dx, y: dy }).to(container, { duration: step });
  }
  return tl;
}

// === HIT STOP (universal hitlag) ===
// Awaitable freeze. NES games hold attacker + target poses for 3-6 frames on
// every contact — caller awaits this between contact and damage burst.
export function hitStop(duration = 0.08) {
  return new Promise(resolve => gsap.delayedCall(duration, resolve));
}

// === TARGET KNOCKBACK ===
// Slides target away from attacker, then settles. Layers cleanly with hitSquash.
export function targetKnockback(el, attackerSide = 'left', intensity = 12) {
  const dir = attackerSide === 'left' ? 1 : -1;
  const tl = gsap.timeline();
  tl.to(el, { x: dir * intensity, duration: 0.06, ease: 'power3.out' });
  tl.to(el, { x: 0, duration: 0.22, ease: 'back.out(2.2)' });
  return tl;
}

// === HIT FLICKER (NES palette-swap crunch) ===
// Fast 4-cycle brightness toggle. Use on the sprite element, not the container.
export function hitFlicker(spriteEl, cycles = 4) {
  const tl = gsap.timeline({
    onComplete() { gsap.set(spriteEl, { filter: '' }); },
  });
  for (let i = 0; i < cycles; i++) {
    tl.set(spriteEl, { filter: 'brightness(3) saturate(0)' });
    tl.to(spriteEl, { duration: 0.03 });
    tl.set(spriteEl, { filter: '' });
    tl.to(spriteEl, { duration: 0.03 });
  }
  return tl;
}

// === HIT FLASH ===
export function hitFlash(targetContainer, color = '#ffffff') {
  const flash = document.createElement('div');
  Object.assign(flash.style, {
    position: 'absolute',
    inset: '0',
    background: color,
    opacity: '0',
    pointerEvents: 'none',
    zIndex: '25',
    borderRadius: 'inherit',
    mixBlendMode: 'screen',
  });
  targetContainer.style.position = 'relative';
  targetContainer.appendChild(flash);

  return gsap.fromTo(flash,
    { opacity: 0 },
    {
      opacity: 0.7,
      duration: 0.06,
      yoyo: true,
      repeat: 1,
      ease: 'power2.in',
      onComplete() {
        flash.remove();
      },
    }
  );
}

// === HIT FREEZE ===
export function hitFreeze(tl, duration = 0.1) {
  tl.addPause('+=0', () => {
    gsap.delayedCall(duration, () => tl.resume());
  });
  return tl;
}

// === ZOOM PUNCH ===
export function zoomPunch(container, targetSide = 'left') {
  const xShift = targetSide === 'left' ? -15 : 15;
  const tl = gsap.timeline();
  tl.to(container, {
    scale: 1.06,
    x: xShift,
    duration: 0.15,
    ease: 'power2.in',
  });
  tl.to(container, {
    scale: 1,
    x: 0,
    duration: 0.15,
    ease: 'back.out(2)',
  });
  return tl;
}

// === CRITICAL HIT (composed timeline) ===
export function criticalHit(container, targetContainer, targetSide = 'left') {
  const tl = gsap.timeline();

  tl.to(container, { filter: 'saturate(0.3)', duration: 0.05 }, 0);

  tl.addPause('+=0', () => {
    gsap.delayedCall(0.1, () => tl.resume());
  });

  tl.add(() => {
    const flash = document.createElement('div');
    Object.assign(flash.style, {
      position: 'absolute',
      inset: '0',
      background: '#ffffff',
      opacity: '0',
      pointerEvents: 'none',
      zIndex: '30',
    });
    container.appendChild(flash);
    gsap.fromTo(flash,
      { opacity: 0 },
      { opacity: 1, duration: 0.05, yoyo: true, repeat: 1, onComplete: () => flash.remove() }
    );
  });

  tl.add(() => screenShake(container, 11, 0.25), '<');

  const xShift = targetSide === 'left' ? -15 : 15;
  tl.to(container, { scale: 1.06, x: xShift, duration: 0.15, ease: 'power2.in' }, '+=0.05');
  tl.to(container, { scale: 1, x: 0, filter: 'none', duration: 0.15, ease: 'back.out(2)' });

  return tl;
}

// === DEFEND SHIELD ===
export function shieldUp(targetContainer, element = 'neutral') {
  const colors = elementColors[element] || elementColors.neutral;
  const shield = document.createElement('div');
  shield.className = 'shield-hex';
  Object.assign(shield.style, {
    position: 'absolute',
    inset: '-10%',
    background: `radial-gradient(ellipse, ${colors.glow}33, ${colors.primary}22)`,
    border: `2px solid ${colors.primary}88`,
    borderRadius: '50%',
    opacity: '0',
    pointerEvents: 'none',
    zIndex: '15',
    boxShadow: `0 0 20px ${colors.primary}44, inset 0 0 20px ${colors.glow}22`,
  });
  targetContainer.style.position = 'relative';
  targetContainer.appendChild(shield);

  const tl = gsap.timeline();
  tl.fromTo(shield,
    { opacity: 0, scale: 0.5 },
    { opacity: 0.8, scale: 1.05, duration: 0.15, ease: 'power2.out' }
  );
  tl.to(shield, { scale: 1.0, duration: 0.1, ease: 'power2.inOut' });
  tl.to(shield, { opacity: 0.7, duration: 0.5, yoyo: true, repeat: -1, ease: 'sine.inOut' });

  return { element: shield, timeline: tl };
}

// === SHIELD DEFLECT ===
export function shieldDeflect(shieldEl, targetContainer, attackDir = 'left') {
  const tl = gsap.timeline();

  tl.to(shieldEl, { opacity: 1, duration: 0.08 });
  tl.to(shieldEl, { scaleX: 0.95, duration: 0.05 });
  tl.to(shieldEl, { scaleX: 1.05, duration: 0.05 });
  tl.to(shieldEl, { scaleX: 1.0, duration: 0.05 });

  tl.add(() => {
    createSparks(targetContainer, attackDir, elementColors.neutral.primary);
  }, '<');

  tl.to(shieldEl, { opacity: 0.8, duration: 0.1 });

  return tl;
}

// === SHIELD DISMISS ===
export function shieldDismiss(shieldEl, shieldTimeline) {
  if (shieldTimeline) shieldTimeline.kill();
  return gsap.to(shieldEl, {
    scale: 0.8,
    opacity: 0,
    duration: 0.2,
    ease: 'power2.in',
    onComplete() {
      shieldEl.remove();
    },
  });
}

// === SPARKS ===
function createSparks(container, direction = 'left', color = '#ffffff', count = 3) {
  for (let i = 0; i < count; i++) {
    const spark = document.createElement('div');
    Object.assign(spark.style, {
      position: 'absolute',
      width: '6px',
      height: '6px',
      borderRadius: '50%',
      background: color,
      boxShadow: `0 0 6px ${color}`,
      left: direction === 'left' ? '10%' : '90%',
      top: '50%',
      pointerEvents: 'none',
      zIndex: '26',
    });
    container.appendChild(spark);

    const angle = (Math.random() - 0.5) * 120 * (Math.PI / 180);
    const dist = 30 + Math.random() * 40;
    const dx = Math.cos(angle) * dist * (direction === 'left' ? -1 : 1);
    const dy = Math.sin(angle) * dist;

    gsap.to(spark, {
      x: dx,
      y: dy,
      opacity: 0,
      scale: 0.3,
      duration: 0.2 + Math.random() * 0.1,
      ease: 'power2.out',
      onComplete() {
        spark.remove();
      },
    });
  }
}

// === SHATTER KO ===
export function shatterKO(spriteEl, element = 'neutral') {
  const rect = spriteEl.getBoundingClientRect();
  const parentRect = spriteEl.parentElement.getBoundingClientRect();
  const offsetX = rect.left - parentRect.left;
  const offsetY = rect.top - parentRect.top;
  const w = rect.width;
  const h = rect.height;
  const container = spriteEl.parentElement;

  let imageSrc;
  if (spriteEl.tagName === 'CANVAS') {
    imageSrc = spriteEl.toDataURL();
  } else {
    imageSrc = spriteEl.src || '';
  }

  const cols = 3;
  const rows = 4;
  const fragments = [];

  const tl = gsap.timeline();

  tl.add(() => hitFlash(container));
  tl.add(() => screenShake(container, 6, 0.2), '<');

  tl.add(() => {
    spriteEl.style.visibility = 'hidden';

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const frag = document.createElement('div');
        const fragW = w / cols;
        const fragH = h / rows;
        Object.assign(frag.style, {
          position: 'absolute',
          left: `${offsetX + c * fragW}px`,
          top: `${offsetY + r * fragH}px`,
          width: `${fragW}px`,
          height: `${fragH}px`,
          backgroundImage: `url(${imageSrc})`,
          backgroundSize: `${w}px ${h}px`,
          backgroundPosition: `-${c * fragW}px -${r * fragH}px`,
          imageRendering: 'pixelated',
          pointerEvents: 'none',
          zIndex: '20',
        });
        container.appendChild(frag);
        fragments.push(frag);
      }
    }
  });

  tl.add(() => {
    fragments.forEach((frag, i) => {
      const dx = (Math.random() - 0.5) * 240;
      const dy = -40 + Math.random() * 120;
      const rot = (Math.random() - 0.5) * 360;

      gsap.to(frag, {
        x: dx,
        y: dy,
        rotation: rot,
        scale: 0.3,
        opacity: 0,
        duration: 0.5,
        delay: i * 0.03,
        ease: 'power2.out',
        onComplete() {
          frag.remove();
        },
      });
    });
  });

  const colors = elementColors[element] || elementColors.neutral;
  tl.add(() => {
    for (let i = 0; i < 5; i++) {
      const p = document.createElement('div');
      Object.assign(p.style, {
        position: 'absolute',
        width: '8px',
        height: '8px',
        borderRadius: '50%',
        background: colors.primary,
        boxShadow: `0 0 8px ${colors.glow}`,
        left: `${offsetX + w / 2}px`,
        top: `${offsetY + h / 2}px`,
        pointerEvents: 'none',
        zIndex: '21',
      });
      container.appendChild(p);

      const angle = Math.random() * Math.PI * 2;
      const dist = 40 + Math.random() * 60;

      gsap.to(p, {
        x: Math.cos(angle) * dist,
        y: Math.sin(angle) * dist,
        opacity: 0,
        scale: 0.2,
        duration: 0.3,
        delay: 0.05 * i,
        ease: 'power2.out',
        onComplete() {
          p.remove();
        },
      });
    }
  }, '-=0.3');

  return tl;
}

// === STATUS EFFECT AURA ===
const STATUS_TINTS = {
  fire:   'sepia(0.4) saturate(1.8) hue-rotate(-10deg)',
  ice:    'saturate(0.5) brightness(1.2) hue-rotate(180deg)',
  storm:  'saturate(1.5) brightness(1.1) hue-rotate(240deg)',
  stone:  'saturate(0.4) brightness(0.9)',
  venom:  'hue-rotate(90deg) saturate(1.3)',
  shadow: 'brightness(0.6) contrast(0.8)',
};

const STATUS_PULSE = {
  fire:   { prop: 'filter', values: ['brightness(1.0)', 'brightness(1.3)'], duration: 1 },
  ice:    null,
  storm:  { prop: 'opacity', values: [1.0, 0.7], duration: 0.15, ease: 'none' },
  stone:  null,
  venom:  { prop: 'filter', values: ['brightness(1.0)', 'brightness(0.85)'], duration: 1.5 },
  shadow: null,
};

const STATUS_PARTICLE_CONFIG = {
  fire:   { color: '#ff6622', behavior: 'rise' },
  ice:    { color: '#88ccff', behavior: 'fall' },
  storm:  { color: '#aa66ff', behavior: 'spark' },
  stone:  { color: '#aa8844', behavior: 'fall' },
  venom:  { color: '#44cc44', behavior: 'orbit' },
  shadow: { color: '#8844aa', behavior: 'drift' },
};

export function statusAuraApply(spriteEl, statusEffect) {
  const tint = STATUS_TINTS[statusEffect];
  const pulse = STATUS_PULSE[statusEffect];
  const particleConfig = STATUS_PARTICLE_CONFIG[statusEffect];
  const timelines = [];

  if (tint) {
    const tintTl = gsap.to(spriteEl, { filter: tint, duration: 0.3 });
    timelines.push(tintTl);
  }

  if (pulse) {
    const pulseTl = gsap.timeline({ repeat: -1, yoyo: true });
    if (pulse.prop === 'filter') {
      const baseFilter = tint || '';
      pulseTl.fromTo(spriteEl,
        { filter: `${baseFilter} ${pulse.values[0]}` },
        { filter: `${baseFilter} ${pulse.values[1]}`, duration: pulse.duration, ease: pulse.ease || 'sine.inOut' }
      );
    } else {
      pulseTl.fromTo(spriteEl,
        { [pulse.prop]: pulse.values[0] },
        { [pulse.prop]: pulse.values[1], duration: pulse.duration, ease: pulse.ease || 'sine.inOut' }
      );
    }
    timelines.push(pulseTl);
  }

  const particles = [];
  if (particleConfig) {
    const container = spriteEl.parentElement;
    for (let i = 0; i < 5; i++) {
      const p = document.createElement('div');
      p.className = 'status-particle';
      Object.assign(p.style, {
        position: 'absolute',
        width: '7px',
        height: '7px',
        borderRadius: '50%',
        background: particleConfig.color,
        boxShadow: `0 0 6px ${particleConfig.color}`,
        pointerEvents: 'none',
        zIndex: '12',
        opacity: '0',
      });
      container.appendChild(p);
      particles.push(p);

      const ptl = createParticleLoop(p, particleConfig.behavior, container, i);
      timelines.push(ptl);
    }
  }

  return {
    timelines,
    particles,
    kill() {
      timelines.forEach(tl => tl.kill());
      particles.forEach((p, i) => {
        gsap.to(p, {
          x: (Math.random() - 0.5) * 60,
          y: (Math.random() - 0.5) * 60,
          opacity: 0,
          duration: 0.2,
          delay: i * 0.02,
          onComplete() { p.remove(); },
        });
      });
      gsap.to(spriteEl, { filter: 'none', duration: 0.3 });
    },
  };
}

function createParticleLoop(particle, behavior, container, index) {
  const rect = container.getBoundingClientRect();
  const cx = rect.width / 2;
  const cy = rect.height / 2;
  const delay = index * 0.6;

  const tl = gsap.timeline({ repeat: -1, delay });

  switch (behavior) {
    case 'rise':
      tl.set(particle, { left: cx + (Math.random() - 0.5) * 60, top: cy + 40, opacity: 0 });
      tl.to(particle, { opacity: 0.8, duration: 0.3 });
      tl.to(particle, { y: -80, x: (Math.random() - 0.5) * 30, opacity: 0, duration: 2.5, ease: 'power1.out' });
      break;

    case 'fall':
      tl.set(particle, { left: cx + (Math.random() - 0.5) * 60, top: cy - 40, opacity: 0 });
      tl.to(particle, { opacity: 0.7, duration: 0.3 });
      tl.to(particle, { y: 80, x: (Math.random() - 0.5) * 20, opacity: 0, duration: 2.5, ease: 'power1.in' });
      break;

    case 'spark':
      tl.set(particle, { left: cx, top: cy, opacity: 0, scale: 0.5 });
      tl.to(particle, { opacity: 1, scale: 1, duration: 0.05 });
      tl.to(particle, {
        x: (Math.random() - 0.5) * 80,
        y: (Math.random() - 0.5) * 80,
        opacity: 0,
        duration: 0.2,
        ease: 'power2.out',
      });
      tl.set(particle, { x: 0, y: 0 });
      tl.to(particle, { duration: Math.random() * 0.5 });
      break;

    case 'orbit':
      {
        const angle = (index / 5) * Math.PI * 2;
        const radius = 35;
        tl.set(particle, { left: cx, top: cy, opacity: 0, scale: 0.5 });
        tl.to(particle, { opacity: 0.7, scale: 1, duration: 0.5 });
        for (let step = 0; step < 4; step++) {
          const a = angle + (step + 1) * (Math.PI / 2);
          tl.to(particle, {
            x: Math.cos(a) * radius,
            y: Math.sin(a) * radius,
            duration: 0.75,
            ease: 'none',
          });
        }
        tl.to(particle, { scale: 1.3, opacity: 0, duration: 0.2 });
      }
      break;

    case 'drift':
    default:
      tl.set(particle, { left: cx - 40, top: cy + (Math.random() - 0.5) * 40, opacity: 0 });
      tl.to(particle, { opacity: 0.5, duration: 0.5 });
      tl.to(particle, { x: 80, opacity: 0, duration: 2.5, ease: 'none' });
      break;
  }

  return tl;
}

// === NPC LUNGE ===
// Anticipation pull-back, then forward strike, hold contact, return.
export function npcLunge(npcEl, direction = 'right') {
  const dx = direction === 'right' ? 30 : -30;
  const pullback = -dx * 0.25;
  const tl = gsap.timeline();
  tl.to(npcEl, { x: pullback, duration: 0.09, ease: 'power2.out' });
  tl.to(npcEl, { x: dx, duration: 0.11, ease: 'power3.in' });
  tl.to(npcEl, { duration: 0.18 });
  tl.to(npcEl, { x: 0, duration: 0.18, ease: 'power2.out' });
  return tl;
}

// === PLAYER LUNGE ===
export function playerLunge(spriteEl, direction = 'left') {
  const dx = direction === 'left' ? -20 : 20;
  const pullback = -dx * 0.3;
  const tl = gsap.timeline();
  tl.to(spriteEl, { x: pullback, duration: 0.08, ease: 'power2.out' });
  tl.to(spriteEl, { x: dx, duration: 0.11, ease: 'power3.in' });
  tl.to(spriteEl, { x: 0, duration: 0.16, ease: 'power2.out' });
  return tl;
}

// === HIT SQUASH ===
export function hitSquash(el) {
  const tl = gsap.timeline();
  tl.to(el, { scaleY: 0.95, scaleX: 1.05, duration: 0.05, ease: 'power2.in' });
  tl.to(el, { scaleY: 1, scaleX: 1, duration: 0.1, ease: 'back.out(3)' });
  return tl;
}
