# Combat Animation Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul Dragon Forge's combat animation system with GSAP-powered screen shake, hit flash, critical hit freeze+zoom, shield+deflect for defend, flash+shatter KO, status effect tint+particles, enhanced NPC animation, and improved damage numbers.

**Architecture:** New `animationEngine.js` module exports GSAP timeline factories called by a refactored `animateEvent()` in BattleScreen. Existing CSS animations remain for backward compatibility. Battle engine gets a critical hit system (`isCritical` flag + 1.5x multiplier). DOM overlay elements (flash, shield, particles, shatter fragments) are managed as ephemeral divs created/destroyed by GSAP timelines.

**Tech Stack:** React 18, GSAP + @gsap/react, Vite, Vitest

---

### Task 1: Install GSAP Dependencies

**Files:**
- Modify: `package.json`

- [ ] **Step 1: Install gsap and @gsap/react**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npm install gsap @gsap/react
```

Expected: packages added to `package.json` dependencies.

- [ ] **Step 2: Verify installation**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && node -e "require('gsap'); console.log('gsap OK')"
```

Expected: `gsap OK`

- [ ] **Step 3: Commit**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add package.json package-lock.json && git commit -m "feat: add gsap and @gsap/react dependencies for combat animations"
```

---

### Task 2: Add Critical Hit System to Battle Engine

**Files:**
- Modify: `src/battleEngine.js`
- Modify: `src/battleEngine.test.js`

- [ ] **Step 1: Write failing tests for critical hits**

Add to `src/battleEngine.test.js`:

```javascript
describe('calculateDamage critical hits', () => {
  const attacker = { atk: 28, element: 'fire', stage: 3 };
  const defender = { def: 20, element: 'ice', defending: false };
  const move = { element: 'fire', power: 65, accuracy: 100 };

  it('returns isCritical flag on result', () => {
    const result = calculateDamage(attacker, defender, move);
    expect(typeof result.isCritical).toBe('boolean');
  });

  it('critical hits deal 1.5x damage', () => {
    // Force critical by mocking Math.random
    const originalRandom = Math.random;
    // First call: accuracy check (needs < 100 to hit)
    // Second call: crit check (needs < 0.1 to crit)
    // Third call: damage roll
    let callCount = 0;
    Math.random = () => {
      callCount++;
      if (callCount === 1) return 0.5;  // accuracy: 50 < 100, hit
      if (callCount === 2) return 0.05; // crit: 5 < 10, critical!
      return 0.0; // damage roll: lowest (0.85)
    };

    const result = calculateDamage(attacker, defender, move);
    expect(result.isCritical).toBe(true);
    // Normal min damage: floor((56-10) * 2.0 * 0.85) = floor(78.2) = 78
    // Crit: floor(78 * 1.5) = 117
    expect(result.damage).toBe(117);

    Math.random = originalRandom;
  });

  it('non-critical hits have isCritical false', () => {
    const originalRandom = Math.random;
    let callCount = 0;
    Math.random = () => {
      callCount++;
      if (callCount === 1) return 0.5;  // accuracy: hit
      if (callCount === 2) return 0.99; // crit: no crit
      return 0.0; // damage roll
    };

    const result = calculateDamage(attacker, defender, move);
    expect(result.isCritical).toBe(false);

    Math.random = originalRandom;
  });

  it('misses cannot be critical', () => {
    const lowAccMove = { element: 'fire', power: 65, accuracy: 0 };
    const result = calculateDamage(attacker, defender, lowAccMove);
    expect(result.isCritical).toBe(false);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vitest run src/battleEngine.test.js
```

Expected: FAIL — `isCritical` is undefined.

- [ ] **Step 3: Implement critical hits in calculateDamage**

In `src/battleEngine.js`, replace the `calculateDamage` function:

```javascript
export const CRIT_CHANCE = 0.10;
export const CRIT_MULTIPLIER = 1.5;

export function calculateDamage(attacker, defender, move) {
  // Accuracy check
  const accuracyRoll = Math.random() * 100;
  if (accuracyRoll > move.accuracy) {
    return { damage: 0, effectiveness: 1.0, hit: false, isCritical: false };
  }

  const stageMult = stageMultipliers[attacker.stage] ?? 1.0;
  const baseDamage = (attacker.atk * stageMult * 2) - (defender.def * 0.5);
  const effectiveness = getTypeEffectiveness(move.element, defender.element);
  let typedDamage = baseDamage * effectiveness;

  if (defender.defending) {
    typedDamage *= 0.5;
  }

  const roll = 0.85 + Math.random() * 0.15;
  let finalDamage = Math.max(1, Math.floor(typedDamage * roll));

  // Critical hit check
  const isCritical = Math.random() < CRIT_CHANCE;
  if (isCritical) {
    finalDamage = Math.floor(finalDamage * CRIT_MULTIPLIER);
  }

  return { damage: finalDamage, effectiveness, hit: true, isCritical };
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vitest run src/battleEngine.test.js
```

Expected: ALL PASS

- [ ] **Step 5: Add isCritical to event objects in resolveAction**

In `src/battleEngine.js`, in the `resolveAction` function, update the two event push calls for attacks to include `isCritical` from the result:

In the reflected attack event push (~line 284):
```javascript
        reflected: true,
        targetHp: newSelfHp,
        isCritical: result.isCritical,
```

In the normal attack event push (~line 328):
```javascript
    appliedStatus: appliedStatus ? STATUS_EFFECTS[appliedStatus.effect].name : null,
    isCritical: result.isCritical,
```

- [ ] **Step 6: Run full test suite**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vitest run
```

Expected: ALL PASS

- [ ] **Step 7: Commit**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add src/battleEngine.js src/battleEngine.test.js && git commit -m "feat: add critical hit system (10% chance, 1.5x damage) to battle engine"
```

---

### Task 3: Create Animation Engine Module

**Files:**
- Create: `src/animationEngine.js`

- [ ] **Step 1: Create the animation engine with all timeline factories**

Create `src/animationEngine.js`:

```javascript
import gsap from 'gsap';
import { elementColors, STATUS_EFFECTS } from './gameData';

// === SCREEN SHAKE ===
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

// === HIT FLASH ===
// Creates a flash overlay div inside target, animates it, then removes it.
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

// === HIT FREEZE (inserts a pause into a timeline) ===
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

  // Desaturate
  tl.to(container, { filter: 'saturate(0.3)', duration: 0.05 }, 0);

  // Hit freeze
  tl.addPause('+=0', () => {
    gsap.delayedCall(0.1, () => tl.resume());
  });

  // White flash (full opacity)
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

  // Heavy screen shake
  tl.add(() => screenShake(container, 11, 0.25), '<');

  // Zoom punch
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
  // Idle pulse
  tl.to(shield, { opacity: 0.7, duration: 0.5, yoyo: true, repeat: -1, ease: 'sine.inOut' });

  return { element: shield, timeline: tl };
}

// === SHIELD DEFLECT ===
export function shieldDeflect(shieldEl, targetContainer, attackDir = 'left') {
  const tl = gsap.timeline();

  // Brighten shield
  tl.to(shieldEl, { opacity: 1, duration: 0.08 });

  // Wobble
  tl.to(shieldEl, { scaleX: 0.95, duration: 0.05 });
  tl.to(shieldEl, { scaleX: 1.05, duration: 0.05 });
  tl.to(shieldEl, { scaleX: 1.0, duration: 0.05 });

  // Sparks
  tl.add(() => {
    createSparks(targetContainer, attackDir, elementColors.neutral.primary);
  }, '<');

  // Return to idle
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

  // Capture sprite as image
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

  // White flash
  tl.add(() => hitFlash(container));

  // Screen shake
  tl.add(() => screenShake(container, 6, 0.2), '<');

  // Create fragments + hide original
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

  // Animate fragments flying outward
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

  // Element-colored burst particles
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

  // Apply tint
  if (tint) {
    const tintTl = gsap.to(spriteEl, { filter: tint, duration: 0.3 });
    timelines.push(tintTl);
  }

  // Apply pulse
  if (pulse) {
    const pulseTl = gsap.timeline({ repeat: -1, yoyo: true });
    if (pulse.prop === 'filter') {
      // Append brightness to tint filter
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

  // Create particles
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
      // Scatter particles outward and remove
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
      // Reset sprite filter
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
    case 'rise': // Embers rising
      tl.set(particle, { left: cx + (Math.random() - 0.5) * 60, top: cy + 40, opacity: 0 });
      tl.to(particle, { opacity: 0.8, duration: 0.3 });
      tl.to(particle, { y: -80, x: (Math.random() - 0.5) * 30, opacity: 0, duration: 2.5, ease: 'power1.out' });
      break;

    case 'fall': // Snowflakes / chips falling
      tl.set(particle, { left: cx + (Math.random() - 0.5) * 60, top: cy - 40, opacity: 0 });
      tl.to(particle, { opacity: 0.7, duration: 0.3 });
      tl.to(particle, { y: 80, x: (Math.random() - 0.5) * 20, opacity: 0, duration: 2.5, ease: 'power1.in' });
      break;

    case 'spark': // Erratic static sparks
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
      tl.to(particle, { duration: Math.random() * 0.5 }); // Random gap
      break;

    case 'orbit': // Slow bubbles orbiting
      {
        const angle = (index / 5) * Math.PI * 2;
        const radius = 35;
        tl.set(particle, { left: cx, top: cy, opacity: 0, scale: 0.5 });
        tl.to(particle, { opacity: 0.7, scale: 1, duration: 0.5 });
        // Approximate orbit with 4 waypoints
        for (let step = 0; step < 4; step++) {
          const a = angle + (step + 1) * (Math.PI / 2);
          tl.to(particle, {
            x: Math.cos(a) * radius,
            y: Math.sin(a) * radius,
            duration: 0.75,
            ease: 'none',
          });
        }
        tl.to(particle, { scale: 1.3, opacity: 0, duration: 0.2 }); // Pop
      }
      break;

    case 'drift': // Slow wisps
    default:
      tl.set(particle, { left: cx - 40, top: cy + (Math.random() - 0.5) * 40, opacity: 0 });
      tl.to(particle, { opacity: 0.5, duration: 0.5 });
      tl.to(particle, { x: 80, opacity: 0, duration: 2.5, ease: 'none' });
      break;
  }

  return tl;
}

// === NPC LUNGE ===
export function npcLunge(npcEl, direction = 'right') {
  const dx = direction === 'right' ? 30 : -30;
  const tl = gsap.timeline();
  tl.to(npcEl, { x: dx, duration: 0.15, ease: 'power2.in' });
  tl.to(npcEl, { duration: 0.2 }); // Hold at peak
  tl.to(npcEl, { x: 0, duration: 0.15, ease: 'power2.out' });
  return tl;
}

// === PLAYER LUNGE ===
export function playerLunge(spriteEl, direction = 'left') {
  const dx = direction === 'left' ? -20 : 20;
  const tl = gsap.timeline();
  tl.to(spriteEl, { x: dx, duration: 0.15, ease: 'power2.in' });
  tl.to(spriteEl, { x: 0, duration: 0.15, ease: 'power2.out' });
  return tl;
}

// === HIT SQUASH ===
export function hitSquash(el) {
  const tl = gsap.timeline();
  tl.to(el, { scaleY: 0.95, scaleX: 1.05, duration: 0.05, ease: 'power2.in' });
  tl.to(el, { scaleY: 1, scaleX: 1, duration: 0.1, ease: 'back.out(3)' });
  return tl;
}
```

- [ ] **Step 2: Verify the file has no syntax errors**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && node -e "import('./src/animationEngine.js').catch(e => console.error(e.message))" --input-type=module
```

Note: This may show import errors since it needs a browser environment. The real verification happens when we integrate it. Just ensure no obvious syntax issues.

- [ ] **Step 3: Commit**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add src/animationEngine.js && git commit -m "feat: create animationEngine.js with GSAP timeline factories for all combat animations"
```

---

### Task 4: Add Combat Animation CSS

**Files:**
- Modify: `src/styles/battle.css`

- [ ] **Step 1: Add new CSS classes for combat animations**

Append to `src/styles/battle.css` (before the `@media` queries):

```css
/* === CRITICAL HIT DAMAGE NUMBER === */
.damage-number.critical {
  color: #ffcc00;
  font-size: 24px;
  font-weight: bold;
  text-shadow: 0 0 10px rgba(255, 204, 0, 0.6), 2px 2px 0 #000, -1px -1px 0 #000;
  animation: damageCritFloat 1.0s ease-out forwards;
}

@keyframes damageCritFloat {
  0% {
    opacity: 1;
    transform: translateY(0) scale(1.5);
  }
  20% {
    transform: translateY(-20px) scale(1.0);
  }
  50% {
    opacity: 1;
    transform: translateY(-50px) scale(1.1);
  }
  100% {
    opacity: 0;
    transform: translateY(-80px) scale(0.9);
  }
}

/* === MISS — drifts sideways === */
.damage-number.miss {
  color: #666666;
  font-style: italic;
  animation: damageMissDrift 0.6s ease-out forwards;
}

@keyframes damageMissDrift {
  0% {
    opacity: 1;
    transform: translateX(0) translateY(0);
  }
  100% {
    opacity: 0;
    transform: translateX(30px) translateY(-20px);
  }
}

/* === STATUS TICK damage — pulse in place === */
.damage-number.status-tick {
  font-size: 14px;
  font-weight: bold;
  animation: damageStatusPulse 0.6s ease-out forwards;
}

@keyframes damageStatusPulse {
  0% {
    opacity: 0;
    transform: scale(0.5);
  }
  30% {
    opacity: 1;
    transform: scale(1.2);
  }
  60% {
    transform: scale(1.0);
  }
  100% {
    opacity: 0;
    transform: scale(0.9);
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add src/styles/battle.css && git commit -m "feat: add CSS for critical, miss drift, and status tick damage numbers"
```

---

### Task 5: Update DamageNumber Component

**Files:**
- Modify: `src/DamageNumber.jsx`

- [ ] **Step 1: Read current DamageNumber.jsx**

Already read. Current component at `src/DamageNumber.jsx` accepts `damage`, `effectiveness`, `hit`, `position`, `onComplete`.

- [ ] **Step 2: Update DamageNumber to support critical and status tick types, and staggered positioning**

Replace `src/DamageNumber.jsx` with:

```jsx
import { useEffect, useState } from 'react';

export default function DamageNumber({ damage, effectiveness, hit, position, onComplete, isCritical = false, isStatusTick = false, statusElement = null, staggerIndex = 0 }) {
  const [visible, setVisible] = useState(true);

  const duration = isCritical ? 1000 : isStatusTick ? 600 : hit ? 800 : 600;

  useEffect(() => {
    const timer = setTimeout(() => {
      setVisible(false);
      onComplete?.();
    }, duration);
    return () => clearTimeout(timer);
  }, [onComplete, duration]);

  if (!visible) return null;

  let className = 'damage-number normal';
  let text = String(damage);

  if (isStatusTick) {
    className = 'damage-number status-tick';
    text = String(damage);
  } else if (!hit) {
    className = 'damage-number miss';
    text = 'MISS';
  } else if (isCritical) {
    className = 'damage-number critical';
    text = `${damage}`;
  } else if (effectiveness > 1.0) {
    className = 'damage-number super-effective';
    text = `${damage}`;
  } else if (effectiveness < 1.0) {
    className = 'damage-number resisted';
    text = `${damage}`;
  }

  // Stagger offset to avoid overlap on multi-hits
  const xOffset = staggerIndex * 15 * (staggerIndex % 2 === 0 ? 1 : -1);

  // Status tick color matches element
  const statusColor = isStatusTick && statusElement
    ? { fire: '#ff6622', ice: '#88ccff', storm: '#aa66ff', stone: '#aa8844', venom: '#44cc44', shadow: '#8844aa' }[statusElement]
    : undefined;

  return (
    <div
      className={className}
      style={{
        left: `${position.x + xOffset}px`,
        top: `${position.y}px`,
        ...(statusColor ? { color: statusColor } : {}),
      }}
    >
      {text}
    </div>
  );
}
```

- [ ] **Step 3: Verify the app still builds**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vite build 2>&1 | tail -5
```

Expected: Build succeeds (DamageNumber callers still pass the original props; new props have defaults).

- [ ] **Step 4: Commit**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add src/DamageNumber.jsx && git commit -m "feat: enhance DamageNumber with critical, miss drift, status tick types and stagger positioning"
```

---

### Task 6: Expose Canvas Ref from DragonSprite

**Files:**
- Modify: `src/DragonSprite.jsx`

- [ ] **Step 1: Add forwardRef to DragonSprite so BattleScreen can access the canvas**

In `src/DragonSprite.jsx`, wrap the component with `forwardRef` and expose `canvasRef`:

Change the import line:
```javascript
import { useState, useEffect, useRef, useCallback, forwardRef, useImperativeHandle } from 'react';
```

Change the function signature and add `useImperativeHandle`:
```javascript
const DragonSprite = forwardRef(function DragonSprite({ spriteSheet, stage = 3, flipX = false, forcedFrame = null, className = '', size = null, shiny = false, element = '' }, ref) {
  const canvasRef = useRef(null);
  const imageRef = useRef(null);
  const [frame, setFrame] = useState(0);
  const [imageLoaded, setImageLoaded] = useState(false);

  useImperativeHandle(ref, () => ({
    getCanvas: () => canvasRef.current,
  }));
```

Change the export at the bottom:
```javascript
export default DragonSprite;
```

The rest of the component stays the same — only the wrapper changes.

- [ ] **Step 2: Verify the app still builds**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vite build 2>&1 | tail -5
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add src/DragonSprite.jsx && git commit -m "feat: expose canvas ref from DragonSprite via forwardRef for shatter KO"
```

---

### Task 7: Update NpcSprite with Lunge Support

**Files:**
- Modify: `src/NpcSprite.jsx`

- [ ] **Step 1: Add forwardRef to NpcSprite so BattleScreen can animate lunge**

Replace `src/NpcSprite.jsx` with:

```jsx
import { forwardRef } from 'react';

const NpcSprite = forwardRef(function NpcSprite({ idleSprite, attackSprite, isAttacking = false, className = '', size = 160, flipX = false, style = {} }, ref) {
  const src = isAttacking ? attackSprite : idleSprite;

  return (
    <img
      ref={ref}
      className={`npc-sprite pixelated ${className}`}
      src={src}
      alt="NPC"
      style={{
        imageRendering: 'pixelated',
        height: `${size}px`,
        objectFit: 'contain',
        transform: flipX ? 'scaleX(-1)' : 'none',
        ...style,
      }}
    />
  );
});

export default NpcSprite;
```

- [ ] **Step 2: Verify build**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vite build 2>&1 | tail -5
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add src/NpcSprite.jsx && git commit -m "feat: add forwardRef to NpcSprite for GSAP lunge animation"
```

---

### Task 8: Integrate Animation Engine into BattleScreen

**Files:**
- Modify: `src/BattleScreen.jsx`

This is the main integration task. It refactors `animateEvent()` and the KO/defend paths to use GSAP timelines.

- [ ] **Step 1: Add imports and refs at the top of BattleScreen**

Add these imports after existing imports:

```javascript
import { useGSAP } from '@gsap/react';
import {
  screenShake, hitFlash, criticalHit, shatterKO,
  shieldUp, shieldDeflect, shieldDismiss,
  statusAuraApply, npcLunge, playerLunge, hitSquash,
} from './animationEngine';
```

Add new refs inside the component function (after `damageIdRef`):

```javascript
  const battleContainerRef = useRef(null);
  const playerSpriteContainerRef = useRef(null);
  const npcSpriteContainerRef = useRef(null);
  const playerSpriteRef = useRef(null);
  const npcSpriteImgRef = useRef(null);
  const shieldRef = useRef(null);
  const playerAuraRef = useRef(null);
  const npcAuraRef = useRef(null);
  const damageStaggerRef = useRef(0);
```

- [ ] **Step 2: Refactor the defend handler in animateEvent**

Replace the defend block (lines 176-185) in `animateEvent`:

```javascript
    if (event.action === 'defend') {
      dispatch({ type: 'ADD_LOG', text: `${who} defended.` });
      playSound('defend');
      const targetContainer = isPlayer ? playerSpriteContainerRef.current : npcSpriteContainerRef.current;
      if (targetContainer) {
        const shield = shieldUp(targetContainer, isPlayer ? state.dragon.element : state.npc.element);
        if (isPlayer) {
          shieldRef.current = shield;
        }
      }
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
        await wait(400);
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      }
      return;
    }
```

- [ ] **Step 3: Refactor the attack animation in animateEvent to add lunge, shake, flash, and crit**

Replace the section after VFX (the IMPACT phase, roughly lines 238-314) with:

```javascript
    // IMPACT phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: 3 });
      // Player lunge
      const spriteEl = playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current;
      if (spriteEl) playerLunge(spriteEl, 'left');
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_NPC_ATTACKING', value: true });
      // NPC lunge
      const npcEl = npcSpriteImgRef.current;
      if (npcEl) npcLunge(npcEl, state.npc.flipSprite ? 'left' : 'right');
    }

    if (event.hit) {
      if (event.reflected) {
        if (isPlayer) {
          dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        } else {
          dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        }
        playSound('superEffective');
      } else {
        if (isPlayer) {
          dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        } else {
          dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        }
        if (event.effectiveness > 1.0) playSound('superEffective');
        else if (event.effectiveness < 1.0) playSound('resisted');
        else playSound('attackHit');
      }

      // --- New animation: screen shake + hit flash (or crit timeline) ---
      const container = battleContainerRef.current;
      const targetContainer = isPlayer
        ? (event.reflected ? playerSpriteContainerRef.current : npcSpriteContainerRef.current)
        : (event.reflected ? npcSpriteContainerRef.current : playerSpriteContainerRef.current);
      const targetSide = isPlayer ? (event.reflected ? 'right' : 'left') : (event.reflected ? 'left' : 'right');

      // Check if target is defending (shield deflect)
      const targetDefending = isPlayer ? state.npcDefending : state.playerDefending;
      if (targetDefending && shieldRef.current) {
        shieldDeflect(shieldRef.current.element, targetContainer, isPlayer ? 'right' : 'left');
        screenShake(container, 3, 0.15); // Half intensity
      } else if (event.isCritical && container) {
        await new Promise(resolve => {
          const tl = criticalHit(container, targetContainer, targetSide);
          tl.eventCallback('onComplete', resolve);
        });
      } else if (container) {
        // Normal hit: damage-scaled shake
        const hpRatio = event.damage / (isPlayer ? state.npcMaxHp : state.playerMaxHp);
        const intensity = 4 + hpRatio * 8; // 4-12px
        screenShake(container, Math.min(intensity, 8), 0.2);
        if (targetContainer) {
          const flashColor = event.effectiveness > 1.0
            ? (elementColors[move.element]?.primary || '#ffffff')
            : '#ffffff';
          hitFlash(targetContainer, flashColor);
        }
      }

      // Hit squash on target
      const hitTarget = isPlayer
        ? (event.reflected ? playerSpriteContainerRef.current : npcSpriteContainerRef.current)
        : (event.reflected ? npcSpriteContainerRef.current : playerSpriteContainerRef.current);
      if (hitTarget) hitSquash(hitTarget);
    } else {
      playSound('miss');
    }

    const dmgTarget = event.reflected ? (isPlayer ? 'player' : 'npc') : (isPlayer ? 'npc' : 'player');
    const dmgId = ++damageIdRef.current;
    const staggerIdx = damageStaggerRef.current++;
    dispatch({
      type: 'ADD_DAMAGE_NUMBER',
      entry: {
        id: dmgId,
        damage: event.damage,
        effectiveness: event.effectiveness,
        hit: event.hit,
        target: dmgTarget,
        isCritical: event.isCritical || false,
        staggerIndex: staggerIdx,
      },
    });
    if (event.hit && isPlayer && !event.reflected) {
      dispatch({ type: 'TRACK_DAMAGE', damage: event.damage });
    }

    // Battle log entry
    if (event.hit) {
      const critText = event.isCritical ? ' CRITICAL!' : '';
      const effText = event.effectiveness > 1 ? ' Super effective!' : event.effectiveness < 1 ? ' Resisted.' : '';
      const reflectText = event.reflected ? ' REFLECTED!' : '';
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — ${event.damage} dmg.${critText}${effText}${reflectText}` });
    } else {
      dispatch({ type: 'ADD_LOG', text: `${who} used ${event.moveName} — missed!` });
    }
    if (event.appliedStatus) {
      dispatch({ type: 'ADD_LOG', text: `${event.appliedStatus} applied!` });
      playSound('statusApply');
    }
    await wait(300);

    // Reset stagger counter
    damageStaggerRef.current = 0;

    // RECOIL phase
    if (isPlayer) {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-recoil' });
    } else {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-recoil' });
    }
    await wait(200);

    // RESOLUTION
    dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_ATTACKING', value: false });
    dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });

    // Dismiss shield after attack resolves
    if (shieldRef.current) {
      shieldDismiss(shieldRef.current.element, shieldRef.current.timeline);
      shieldRef.current = null;
    }

    await wait(200);
```

- [ ] **Step 4: Replace KO fade with shatter animation**

In `handleMoveSelect`, replace the NPC KO section (around the `sprite-ko` dispatch, ~line 466):

Replace:
```javascript
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
        playSound('ko');
        await wait(600);
```

With:
```javascript
        playSound('ko');
        const npcSpriteEl = npcSpriteImgRef.current;
        if (npcSpriteEl) {
          await new Promise(resolve => {
            const tl = shatterKO(npcSpriteEl, state.npc.element);
            tl.eventCallback('onComplete', resolve);
          });
        } else {
          dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
          await wait(600);
        }
```

Do the same for the player KO (around line 489):

Replace:
```javascript
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-ko' });
      playSound('ko');
      await wait(600);
```

With:
```javascript
      playSound('ko');
      const playerCanvas = playerSpriteRef.current?.getCanvas?.();
      if (playerCanvas) {
        await new Promise(resolve => {
          const tl = shatterKO(playerCanvas, state.dragon.element);
          tl.eventCallback('onComplete', resolve);
        });
      } else {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-ko' });
        await wait(600);
      }
```

Also replace the phase-shift KO (~line 407):

Replace:
```javascript
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
        playSound('ko');
        await wait(600);
```

With:
```javascript
        playSound('ko');
        const phaseNpcEl = npcSpriteImgRef.current;
        if (phaseNpcEl) {
          await new Promise(resolve => {
            const tl = shatterKO(phaseNpcEl, state.npc.element);
            tl.eventCallback('onComplete', resolve);
          });
        } else {
          dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
          await wait(600);
        }
```

- [ ] **Step 5: Add status aura application and removal**

After the status sync dispatches in `handleMoveSelect` (around line 365):

```javascript
    dispatch({ type: 'SET_PLAYER_STATUS', value: result.player.status || null });
    dispatch({ type: 'SET_NPC_STATUS', value: result.npc.status || null });

    // Apply/remove status auras
    if (result.player.status && !playerAuraRef.current) {
      const spriteEl = playerSpriteRef.current?.getCanvas?.() || playerSpriteContainerRef.current;
      if (spriteEl) {
        playerAuraRef.current = statusAuraApply(spriteEl, result.player.status.effect);
      }
    } else if (!result.player.status && playerAuraRef.current) {
      playerAuraRef.current.kill();
      playerAuraRef.current = null;
    }

    if (result.npc.status && !npcAuraRef.current) {
      const npcEl = npcSpriteImgRef.current || npcSpriteContainerRef.current;
      if (npcEl) {
        npcAuraRef.current = statusAuraApply(npcEl, result.npc.status.effect);
      }
    } else if (!result.npc.status && npcAuraRef.current) {
      npcAuraRef.current.kill();
      npcAuraRef.current = null;
    }
```

- [ ] **Step 6: Update status tick damage numbers to use new type**

In the status tick processing loop (around line 376), update the ADD_DAMAGE_NUMBER dispatch:

```javascript
          dispatch({
            type: 'ADD_DAMAGE_NUMBER',
            entry: { id: dmgId, damage: event.damage, effectiveness: 1.0, hit: true, target: event.target, isStatusTick: true, statusElement: event.target === 'player' ? state.playerStatus?.effect : state.npcStatus?.effect },
          });
```

- [ ] **Step 7: Add ref attributes to JSX elements**

Update the root div:
```jsx
    <div ref={battleContainerRef} style={{ position: 'relative', width: '100%', height: '100%', overflow: 'hidden' }}>
```

Update the NPC sprite container div:
```jsx
        <div ref={npcSpriteContainerRef} style={{ position: 'relative' }}>
          <NpcSprite
            ref={npcSpriteImgRef}
```

Update the player sprite container div:
```jsx
        <div ref={playerSpriteContainerRef} style={{ position: 'relative' }}>
          <DragonSprite
            ref={playerSpriteRef}
```

- [ ] **Step 8: Pass new props through to DamageNumber**

Update both DamageNumber render calls (NPC and player side) to pass the new props:

```jsx
              <DamageNumber
                key={d.id}
                damage={d.damage}
                effectiveness={d.effectiveness}
                hit={d.hit}
                isCritical={d.isCritical || false}
                isStatusTick={d.isStatusTick || false}
                statusElement={d.statusElement}
                staggerIndex={d.staggerIndex || 0}
                position={{ x: 40, y: -20 }}
                onComplete={() => dispatch({ type: 'REMOVE_DAMAGE_NUMBER', id: d.id })}
              />
```

- [ ] **Step 9: Clean up auras on unmount**

Add cleanup effect after the `useEffect` for autoBattle:

```javascript
  useEffect(() => {
    return () => {
      if (playerAuraRef.current) playerAuraRef.current.kill();
      if (npcAuraRef.current) npcAuraRef.current.kill();
    };
  }, []);
```

- [ ] **Step 10: Verify build**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vite build 2>&1 | tail -10
```

Expected: Build succeeds.

- [ ] **Step 11: Commit**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add src/BattleScreen.jsx && git commit -m "feat: integrate GSAP animation engine into BattleScreen — shake, flash, crit, shield, shatter, status aura, lunge"
```

---

### Task 9: Manual Testing & Polish

**Files:**
- Possibly modify: `src/animationEngine.js`, `src/BattleScreen.jsx`, `src/styles/battle.css`

- [ ] **Step 1: Run the dev server**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npm run dev
```

- [ ] **Step 2: Test each animation in a battle**

Playtest checklist:
1. Start a battle. Attack — verify screen shake + hit flash on impact
2. Use a super-effective move — verify element-colored flash + stronger shake
3. Get hit — verify player recoil + NPC lunge
4. Use Defend — verify shield appears, stays during enemy turn, deflects with sparks
5. Get a status effect applied — verify tint + particle aura appears
6. Wait for status to expire — verify aura clears cleanly
7. Win a battle — verify shatter KO (fragments fly, element burst)
8. Lose a battle — verify player shatter KO
9. Land a critical hit (may take several tries at 10% chance) — verify freeze + flash + zoom
10. Miss — verify miss text drifts sideways

- [ ] **Step 3: Fix any timing or visual issues found**

Adjust animation durations, intensities, or positions as needed based on playtesting.

- [ ] **Step 4: Run existing tests to ensure no regressions**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vitest run
```

Expected: ALL PASS

- [ ] **Step 5: Commit any polish fixes**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add -A && git commit -m "fix: polish combat animation timing and visual feedback"
```

---

### Task 10: Production Build Verification

**Files:**
- None (verification only)

- [ ] **Step 1: Run production build**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vite build
```

Expected: Build succeeds with no errors.

- [ ] **Step 2: Preview production build**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vite preview
```

Open in browser, run through a battle, verify animations work in production mode.

- [ ] **Step 3: Run full test suite one final time**

Run:
```bash
cd /c/Users/Scott\ Morley/Dev/DF && npx vitest run
```

Expected: ALL PASS

- [ ] **Step 4: Final commit if any changes needed**

```bash
cd /c/Users/Scott\ Morley/Dev/DF && git add -A && git commit -m "chore: verify production build with combat animation overhaul"
```
