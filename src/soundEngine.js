let audioCtx = null;

function getCtx() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
  return audioCtx;
}

const SOUND_PREFS_KEY = 'dragonforge_sound';

function loadPrefs() {
  try {
    const raw = localStorage.getItem(SOUND_PREFS_KEY);
    if (!raw) return { sfxVolume: 0.7, musicVolume: 0.5, muted: false };
    return JSON.parse(raw);
  } catch {
    return { sfxVolume: 0.7, musicVolume: 0.5, muted: false };
  }
}

function savePrefs(prefs) {
  localStorage.setItem(SOUND_PREFS_KEY, JSON.stringify(prefs));
}

let prefs = loadPrefs();

export function isMuted() {
  return prefs.muted;
}

export function toggleMute() {
  prefs.muted = !prefs.muted;
  savePrefs(prefs);
  if (prefs.muted) {
    stopMusic();
  }
  return prefs.muted;
}

export function getSfxVolume() {
  return prefs.muted ? 0 : prefs.sfxVolume;
}

export function getMusicVolume() {
  return prefs.muted ? 0 : prefs.musicVolume;
}

export function setSfxVolume(vol) {
  prefs.sfxVolume = Math.max(0, Math.min(1, vol));
  savePrefs(prefs);
}

export function setMusicVolume(vol) {
  prefs.musicVolume = Math.max(0, Math.min(1, vol));
  savePrefs(prefs);
}

// === SYNTHESIS PRIMITIVES ===

function osc(freq, duration, type = 'square', volume = 1.0, detune = 0) {
  const ctx = getCtx();
  const vol = getSfxVolume() * volume;
  if (vol === 0) return null;

  const o = ctx.createOscillator();
  const g = ctx.createGain();
  o.type = type;
  o.frequency.value = freq;
  o.detune.value = detune;
  g.gain.setValueAtTime(vol * 0.3, ctx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration / 1000);
  o.connect(g);
  g.connect(ctx.destination);
  o.start();
  o.stop(ctx.currentTime + duration / 1000);
  return { osc: o, gain: g };
}

function sweep(startFreq, endFreq, duration, type = 'sine', volume = 1.0) {
  const ctx = getCtx();
  const vol = getSfxVolume() * volume;
  if (vol === 0) return;

  const o = ctx.createOscillator();
  const g = ctx.createGain();
  o.type = type;
  o.frequency.setValueAtTime(startFreq, ctx.currentTime);
  o.frequency.exponentialRampToValueAtTime(Math.max(endFreq, 20), ctx.currentTime + duration / 1000);
  g.gain.setValueAtTime(vol * 0.25, ctx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration / 1000);
  o.connect(g);
  g.connect(ctx.destination);
  o.start();
  o.stop(ctx.currentTime + duration / 1000);
}

function bend(startFreq, midFreq, endFreq, duration, type = 'square', volume = 1.0) {
  const ctx = getCtx();
  const vol = getSfxVolume() * volume;
  if (vol === 0) return;

  const o = ctx.createOscillator();
  const g = ctx.createGain();
  const midTime = ctx.currentTime + (duration / 1000) * 0.42;
  const endTime = ctx.currentTime + duration / 1000;
  o.type = type;
  o.frequency.setValueAtTime(startFreq, ctx.currentTime);
  o.frequency.exponentialRampToValueAtTime(Math.max(midFreq, 20), midTime);
  o.frequency.exponentialRampToValueAtTime(Math.max(endFreq, 20), endTime);
  g.gain.setValueAtTime(vol * 0.26, ctx.currentTime);
  g.gain.linearRampToValueAtTime(vol * 0.2, midTime);
  g.gain.exponentialRampToValueAtTime(0.001, endTime);
  o.connect(g);
  g.connect(ctx.destination);
  o.start();
  o.stop(endTime);
}

function noise(duration, filterFreq = 2000, filterType = 'lowpass', volume = 1.0) {
  const ctx = getCtx();
  const vol = getSfxVolume() * volume;
  if (vol === 0) return;

  const bufferSize = ctx.sampleRate * (duration / 1000);
  const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < bufferSize; i++) {
    data[i] = Math.random() * 2 - 1;
  }

  const source = ctx.createBufferSource();
  source.buffer = buffer;

  const filter = ctx.createBiquadFilter();
  filter.type = filterType;
  filter.frequency.value = filterFreq;
  filter.Q.value = 1.5;

  const gain = ctx.createGain();
  gain.gain.setValueAtTime(vol * 0.2, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration / 1000);

  source.connect(filter);
  filter.connect(gain);
  gain.connect(ctx.destination);
  source.start();
}

function noiseBurst(duration, filterFreq = 1800, filterType = 'bandpass', volume = 1.0, q = 4) {
  const ctx = getCtx();
  const vol = getSfxVolume() * volume;
  if (vol === 0) return;

  const bufferSize = ctx.sampleRate * (duration / 1000);
  const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < bufferSize; i++) {
    data[i] = (Math.random() * 2 - 1) * (1 - i / bufferSize);
  }

  const source = ctx.createBufferSource();
  const filter = ctx.createBiquadFilter();
  const gain = ctx.createGain();
  source.buffer = buffer;
  filter.type = filterType;
  filter.frequency.value = filterFreq;
  filter.Q.value = q;
  gain.gain.setValueAtTime(vol * 0.24, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration / 1000);
  source.connect(filter);
  filter.connect(gain);
  gain.connect(ctx.destination);
  source.start();
}

function arpeggio(notes, type = 'square', noteDuration = 80, volume = 0.8) {
  notes.forEach((freq, i) => {
    setTimeout(() => osc(freq, noteDuration, type, volume), i * noteDuration);
  });
}

function chord(freqs, duration, type = 'sine', volume = 0.5) {
  freqs.forEach((freq, i) => {
    osc(freq, duration, type, volume * 0.6, i * 5);
  });
}

function delay(ms) {
  return new Promise(r => setTimeout(r, ms));
}

const ELEMENT_PITCH = {
  fire: -100,
  ice: 200,
  storm: 100,
  stone: -200,
  venom: 50,
  shadow: -150,
  void: 300,
  neutral: 0,
};

const SFX_SCHEMA = {
  ui: {
    buttonClick: { role: 'confirm', priority: 1, cooldownMs: 25 },
    buttonHover: { role: 'hover', priority: 0, cooldownMs: 35 },
    navSwitch: { role: 'navigation', priority: 1, cooldownMs: 80 },
    screenTransition: { role: 'transition', priority: 2, cooldownMs: 180 },
  },
  terminal: {
    terminalType: { role: 'text', priority: 0, cooldownMs: 12 },
    terminalOk: { role: 'success', priority: 1, cooldownMs: 80 },
    terminalWarning: { role: 'warning', priority: 2, cooldownMs: 120 },
    terminalFail: { role: 'failure', priority: 3, cooldownMs: 180 },
    terminalGlitch: { role: 'glitch', priority: 3, cooldownMs: 240 },
  },
  hatchery: {
    eggGlow: { role: 'charge', priority: 1, cooldownMs: 100 },
    eggCrack: { role: 'impact', priority: 2, cooldownMs: 70 },
    eggShake: { role: 'motion', priority: 1, cooldownMs: 90 },
    hatchBurst: { role: 'reveal', priority: 3, cooldownMs: 300 },
    dragonReveal: { role: 'reward', priority: 3, cooldownMs: 300 },
  },
  combat: {
    combatCommandSelect: { role: 'command', priority: 1, cooldownMs: 60 },
    combatCommandExecute: { role: 'execute', priority: 2, cooldownMs: 120 },
    combatFeedTick: { role: 'message', priority: 0, cooldownMs: 35 },
    attackLaunch: { role: 'anticipation', priority: 2, cooldownMs: 90 },
    lungeContact: { role: 'contact', priority: 2, cooldownMs: 65 },
    attackHit: { role: 'hit', priority: 2, cooldownMs: 70 },
    superEffective: { role: 'strong-hit', priority: 3, cooldownMs: 90 },
    criticalHit: { role: 'critical-hit', priority: 4, cooldownMs: 140 },
    resisted: { role: 'weak-hit', priority: 1, cooldownMs: 70 },
    miss: { role: 'miss', priority: 1, cooldownMs: 80 },
    defend: { role: 'guard', priority: 2, cooldownMs: 100 },
    shieldDeflectSting: { role: 'reflect', priority: 3, cooldownMs: 110 },
    heartbeatThump: { role: 'danger-pulse', priority: 1, cooldownMs: 140 },
    statusApply: { role: 'status-apply', priority: 2, cooldownMs: 110 },
    statusTick: { role: 'status-tick', priority: 1, cooldownMs: 70 },
    statusExpire: { role: 'status-expire', priority: 1, cooldownMs: 110 },
    ko: { role: 'ko', priority: 4, cooldownMs: 350 },
    victoryFanfare: { role: 'victory', priority: 5, cooldownMs: 800 },
    defeatDrone: { role: 'defeat', priority: 5, cooldownMs: 800 },
    xpGain: { role: 'reward-small', priority: 2, cooldownMs: 150 },
    levelUp: { role: 'reward-major', priority: 4, cooldownMs: 450 },
    scrapsEarned: { role: 'currency', priority: 1, cooldownMs: 120 },
  },
  fusion: {
    fusionMerge: { role: 'charge', priority: 2, cooldownMs: 300 },
    fusionBurst: { role: 'burst', priority: 3, cooldownMs: 300 },
    fusionReveal: { role: 'reward', priority: 4, cooldownMs: 500 },
  },
};

const SOUND_ALIASES = {
  uiConfirm: 'buttonClick',
  uiHover: 'buttonHover',
  commandSelect: 'combatCommandSelect',
  commandExecute: 'combatCommandExecute',
  combatMessage: 'combatFeedTick',
};

const MUSIC_SCHEMA = {
  title: { role: 'boot-theme', mood: 'mysterious', source: 'asset', path: '/assets/music/theme.mp3' },
  openingTense: { role: 'opening-sequence', mood: 'tense', source: 'asset', path: '/assets/music/music_battle_intense.mp3' },
  hatchery: { role: 'home-base', mood: 'warm', source: 'asset', path: '/assets/music/music_hatchery.mp3' },
  select: { role: 'menu-selection', mood: 'focused', source: 'asset', path: '/assets/music/music_select.mp3' },
  mapWander: { role: 'map-wandering', mood: 'wandering', source: 'asset', path: '/assets/music/music_select.mp3' },
  battle: { role: 'battle-standard', mood: 'active', source: 'asset', path: '/assets/music/music_battle.mp3' },
  battleTense: { role: 'battle-tense', mood: 'tense', source: 'asset', path: '/assets/music/music_battle_intense.mp3' },
  battleIntense: { role: 'battle-critical', mood: 'danger', source: 'asset', path: '/assets/music/music_battle_intense.mp3' },
};

const MUSIC_ALIASES = {
  map: 'mapWander',
  wandering: 'mapWander',
  tenseBattle: 'battleTense',
  opening: 'openingTense',
};

const SOUND_DEFINITIONS = Object.entries(SFX_SCHEMA).reduce((defs, [category, entries]) => {
  Object.entries(entries).forEach(([name, meta]) => {
    defs[name] = { name, category, ...meta };
  });
  return defs;
}, {});

const lastPlayedAt = new Map();

function resolveSoundName(name) {
  return SOUND_ALIASES[name] || name;
}

function resolveMusicName(name) {
  return MUSIC_ALIASES[name] || name;
}

function elementColorBurst(element, delayMs = 0, volume = 1) {
  const p = ELEMENT_PITCH[element] || 0;
  setTimeout(() => {
    if (element === 'fire') {
      noiseBurst(120, 3200 + p, 'bandpass', 0.34 * volume, 7);
      bend(220 + p, 620 + p, 360 + p, 150, 'sawtooth', 0.22 * volume);
    } else if (element === 'ice') {
      arpeggio([980 + p, 1320 + p, 1760 + p], 'triangle', 32, 0.18 * volume);
      noiseBurst(90, 6200, 'highpass', 0.12 * volume, 5);
    } else if (element === 'storm') {
      bend(900 + p, 1800 + p, 700 + p, 120, 'square', 0.24 * volume);
      noiseBurst(80, 4600, 'highpass', 0.18 * volume, 8);
    } else if (element === 'stone') {
      osc(92, 90, 'triangle', 0.42 * volume);
      noiseBurst(150, 420, 'lowpass', 0.36 * volume, 2);
    } else if (element === 'venom') {
      bend(360 + p, 240 + p, 460 + p, 180, 'sawtooth', 0.2 * volume);
      noiseBurst(130, 1500, 'bandpass', 0.2 * volume, 9);
    } else if (element === 'shadow') {
      osc(110 + p, 140, 'sawtooth', 0.28 * volume);
      bend(520 + p, 180 + p, 740 + p, 210, 'triangle', 0.18 * volume);
      noiseBurst(130, 900, 'bandpass', 0.18 * volume, 6);
    } else {
      osc(420 + p, 70, 'square', 0.16 * volume);
      noiseBurst(70, 2500 + p, 'bandpass', 0.12 * volume, 4);
    }
  }, delayMs);
}

// === SFX DEFINITIONS ===

const SFX = {
  // --- UI ---
  buttonClick: () => {
    osc(900, 25, 'square', 0.4);
    osc(1200, 15, 'sine', 0.2);
  },

  buttonHover: () => {
    osc(800, 15, 'sine', 0.15);
  },

  navSwitch: () => {
    sweep(500, 900, 80, 'sine', 0.35);
    noise(40, 3000, 'highpass', 0.15);
  },

  screenTransition: () => {
    noise(250, 2000, 'bandpass', 0.3);
    sweep(200, 800, 200, 'sine', 0.2);
  },

  // --- Terminal ---
  terminalType: () => {
    osc(440, 8, 'square', 0.12);
    noise(5, 4000, 'highpass', 0.08);
  },

  terminalOk: () => {
    osc(500, 40, 'sine', 0.35);
    setTimeout(() => osc(700, 60, 'sine', 0.3), 40);
  },

  terminalWarning: () => {
    osc(350, 80, 'sawtooth', 0.35);
    setTimeout(() => osc(300, 80, 'sawtooth', 0.3), 80);
  },

  terminalFail: () => {
    noise(200, 1200, 'lowpass', 0.5);
    osc(150, 200, 'sawtooth', 0.4);
    osc(120, 200, 'sawtooth', 0.3);
  },

  terminalGlitch: () => {
    noise(350, 4000, 'lowpass', 0.5);
    for (let i = 0; i < 5; i++) {
      setTimeout(() => {
        osc(Math.random() * 600 + 100, 40, 'sawtooth', 0.2);
        noise(30, Math.random() * 3000 + 500, 'bandpass', 0.15);
      }, i * 60);
    }
  },

  // --- Hatchery ---
  eggGlow: () => {
    sweep(180, 450, 300, 'sine', 0.25);
    osc(360, 300, 'sine', 0.1);
  },

  eggCrack: () => {
    noise(60, 4000, 'highpass', 0.6);
    osc(180, 40, 'triangle', 0.5);
    osc(250, 30, 'square', 0.2);
  },

  eggShake: () => {
    noise(100, 800, 'bandpass', 0.4);
    osc(120, 80, 'sine', 0.2);
  },

  hatchBurst: () => {
    noise(400, 5000, 'lowpass', 0.7);
    sweep(200, 1500, 350, 'sine', 0.4);
    sweep(300, 2000, 300, 'sawtooth', 0.15);
    setTimeout(() => noise(200, 2000, 'highpass', 0.3), 100);
  },

  dragonReveal: () => {
    arpeggio([523, 659, 784, 1047], 'sine', 90, 0.6);
    setTimeout(() => osc(1047, 200, 'sine', 0.3), 360);
    setTimeout(() => noise(100, 6000, 'highpass', 0.1), 200);
  },

  // --- Combat ---
  combatCommandSelect: (opts) => {
    const p = ELEMENT_PITCH[opts?.element] || 0;
    bend(560 + p, 980 + p, 760 + p, 46, 'square', 0.32);
    setTimeout(() => osc(1240 + p, 22, 'triangle', 0.18), 28);
    noiseBurst(34, 3600, 'highpass', 0.12, 7);
  },

  combatCommandExecute: (opts) => {
    const p = ELEMENT_PITCH[opts?.element] || 0;
    bend(260 + p, 760 + p, 420 + p, 150, 'square', 0.34);
    setTimeout(() => osc(1160 + p, 52, 'sine', 0.2), 58);
    elementColorBurst(opts?.element, 70, 0.45);
  },

  combatFeedTick: () => {
    osc(880, 14, 'square', 0.14);
    setTimeout(() => osc(660, 14, 'square', 0.1), 18);
  },

  attackLaunch: (opts) => {
    const p = ELEMENT_PITCH[opts?.element] || 0;
    noiseBurst(180, 2500 + p, 'bandpass', 0.42, 6);
    bend(190 + p, 620 + p, 380 + p, 180, 'sawtooth', 0.32);
    osc(300 + p, 90, 'square', 0.18);
    elementColorBurst(opts?.element, 55, 0.6);
  },

  attackHit: (opts) => {
    const p = ELEMENT_PITCH[opts?.element] || 0;
    noiseBurst(150, 780 + p, 'lowpass', 0.82, 2.5);
    osc(165 + p, 90, 'triangle', 0.64);
    osc(96 + p, 75, 'sine', 0.38);
    setTimeout(() => noiseBurst(70, 3600 + p, 'highpass', 0.28, 5), 24);
    elementColorBurst(opts?.element, 34, 0.5);
  },

  superEffective: (opts) => {
    SFX.attackHit(opts);
    setTimeout(() => {
      bend(760, 1900, 1180, 230, 'square', 0.48);
      osc(1520, 180, 'triangle', 0.28);
      noiseBurst(120, 5800, 'highpass', 0.28, 8);
      elementColorBurst(opts?.element, 60, 0.72);
    }, 60);
  },

  criticalHit: (opts) => {
    const p = ELEMENT_PITCH[opts?.element] || 0;
    // Heavier impact body
    noiseBurst(180, 520 + p, 'lowpass', 0.95, 2);
    osc(135 + p, 120, 'triangle', 0.76);
    // Piercing bell sweep on top — the NES "this matters" cue
    bend(720 + p, 2600 + p, 1250 + p, 280, 'square', 0.55);
    osc(1800 + p, 210, 'triangle', 0.28);
    setTimeout(() => {
      osc(2400 + p, 120, 'sine', 0.24);
      noiseBurst(80, 6500, 'highpass', 0.34, 9);
      elementColorBurst(opts?.element, 0, 0.82);
    }, 80);
  },

  lungeContact: () => {
    bend(1600, 720, 980, 84, 'triangle', 0.32);
    noiseBurst(58, 3800, 'highpass', 0.22, 6);
  },

  shieldDeflectSting: () => {
    osc(1600, 70, 'square', 0.42);
    osc(2400, 60, 'sine', 0.32);
    noiseBurst(70, 5400, 'highpass', 0.25, 9);
    setTimeout(() => bend(1350, 900, 1250, 110, 'triangle', 0.22), 34);
  },

  heartbeatThump: () => {
    osc(80, 90, 'sine', 0.35);
    osc(60, 120, 'triangle', 0.2);
  },

  resisted: () => {
    noiseBurst(130, 420, 'lowpass', 0.34, 2);
    bend(240, 165, 210, 110, 'triangle', 0.22);
  },

  miss: () => {
    bend(980, 420, 260, 260, 'sine', 0.18);
    noiseBurst(170, 1600, 'bandpass', 0.12, 5);
  },

  defend: () => {
    chord([260, 390, 520], 150, 'triangle', 0.45);
    noiseBurst(82, 2600, 'highpass', 0.28, 5);
    setTimeout(() => osc(680, 86, 'sine', 0.24), 70);
  },

  ko: () => {
    bend(280, 120, 48, 920, 'sawtooth', 0.45);
    noiseBurst(700, 520, 'lowpass', 0.34, 2);
    setTimeout(() => noiseBurst(430, 280, 'lowpass', 0.25, 1.5), 400);
    setTimeout(() => osc(50, 500, 'sine', 0.15), 200);
  },

  victoryFanfare: () => {
    arpeggio([523, 659, 784], 'square', 100, 0.5);
    setTimeout(() => {
      chord([1047, 1319, 1568], 400, 'sine', 0.4);
      noise(100, 6000, 'highpass', 0.1);
    }, 350);
  },

  defeatDrone: () => {
    osc(55, 1200, 'sawtooth', 0.3);
    osc(58, 1200, 'sawtooth', 0.25);
    noise(1000, 400, 'lowpass', 0.2);
    setTimeout(() => sweep(200, 55, 800, 'sine', 0.15), 200);
  },

  xpGain: () => {
    arpeggio([800, 1000, 1200], 'sine', 50, 0.35);
  },

  levelUp: () => {
    arpeggio([523, 659, 784, 1047], 'square', 70, 0.5);
    setTimeout(() => {
      chord([1047, 1319], 300, 'sine', 0.3);
      noise(60, 6000, 'highpass', 0.1);
    }, 300);
  },

  scrapsEarned: () => {
    osc(1400, 30, 'sine', 0.3);
    setTimeout(() => osc(1600, 30, 'sine', 0.3), 50);
    setTimeout(() => osc(1800, 40, 'sine', 0.25), 100);
  },

  // --- Status Effects ---
  statusApply: () => {
    noise(80, 2500, 'bandpass', 0.4);
    sweep(500, 200, 120, 'sawtooth', 0.3);
    osc(300, 100, 'triangle', 0.2);
  },

  statusTick: () => {
    noise(50, 2000, 'bandpass', 0.25);
    osc(250, 40, 'sine', 0.15);
  },

  statusExpire: () => {
    arpeggio([350, 450, 550, 700], 'sine', 50, 0.3);
    noise(40, 5000, 'highpass', 0.1);
  },

  // --- Fusion ---
  fusionMerge: () => {
    sweep(200, 600, 500, 'sine', 0.35);
    sweep(250, 700, 500, 'sine', 0.3);
    noise(400, 1500, 'bandpass', 0.15);
    setTimeout(() => osc(500, 200, 'triangle', 0.2), 200);
  },

  fusionBurst: () => {
    noise(300, 5000, 'lowpass', 0.6);
    sweep(300, 1500, 300, 'sine', 0.4);
    chord([600, 900, 1200], 250, 'sine', 0.3);
    setTimeout(() => noise(150, 3000, 'highpass', 0.3), 100);
  },

  fusionReveal: () => {
    arpeggio([523, 659, 784, 1047], 'sine', 100, 0.5);
    setTimeout(() => {
      chord([1047, 1319, 1568], 500, 'sine', 0.35);
      osc(1568, 300, 'triangle', 0.15);
    }, 400);
  },
};

export function getSoundSchema() {
  return SFX_SCHEMA;
}

export function getSoundDefinition(name) {
  return SOUND_DEFINITIONS[resolveSoundName(name)] || null;
}

export function listSoundNames(category) {
  if (!category) return Object.keys(SOUND_DEFINITIONS);
  return Object.entries(SOUND_DEFINITIONS)
    .filter(([, definition]) => definition.category === category)
    .map(([name]) => name);
}

export function playSound(name, options) {
  const resolvedName = resolveSoundName(name);
  const fn = SFX[resolvedName];
  if (fn) {
    try {
      const definition = SOUND_DEFINITIONS[resolvedName];
      const now = typeof performance !== 'undefined' ? performance.now() : Date.now();
      const cooldownMs = options?.cooldownMs ?? definition?.cooldownMs ?? 0;
      const lastPlayed = lastPlayedAt.get(resolvedName) || 0;
      if (cooldownMs > 0 && now - lastPlayed < cooldownMs) return;
      lastPlayedAt.set(resolvedName, now);
      fn(options);
    } catch { /* ignore audio errors */ }
  }
}

// === MUSIC ===

let currentMusic = null;
let currentTrackName = null;

const MUSIC_TRACKS = {
  title: '/assets/music/theme.mp3',
  openingTense: '/assets/music/music_battle_intense.mp3',
  hatchery: '/assets/music/music_hatchery.mp3',
  select: '/assets/music/music_select.mp3',
  mapWander: '/assets/music/music_select.mp3',
  battle: '/assets/music/music_battle.mp3',
  battleTense: '/assets/music/music_battle_intense.mp3',
  battleIntense: '/assets/music/music_battle_intense.mp3',
};

export function getMusicSchema() {
  return MUSIC_SCHEMA;
}

export function getMusicDefinition(trackName) {
  return MUSIC_SCHEMA[resolveMusicName(trackName)] || null;
}

function fadeOut(audio, duration = 350) {
  return new Promise((resolve) => {
    if (!audio || audio.paused) { resolve(); return; }
    const startVol = audio.volume;
    const steps = 20;
    const stepTime = duration / steps;
    const stepVol = startVol / steps;
    let step = 0;
    const interval = setInterval(() => {
      step++;
      audio.volume = Math.max(0, startVol - stepVol * step);
      if (step >= steps) {
        clearInterval(interval);
        audio.pause();
        audio.volume = startVol;
        resolve();
      }
    }, stepTime);
  });
}

function fadeIn(audio, targetVol, duration = 350) {
  audio.volume = 0;
  audio.play().catch(() => {});
  const steps = 20;
  const stepTime = duration / steps;
  const stepVol = targetVol / steps;
  let step = 0;
  const interval = setInterval(() => {
    step++;
    audio.volume = Math.min(targetVol, stepVol * step);
    if (step >= steps) clearInterval(interval);
  }, stepTime);
}

export function playMusic(trackName, immediate = false) {
  if (prefs.muted) return;
  const resolvedTrackName = resolveMusicName(trackName);
  if (currentTrackName === resolvedTrackName && currentMusic && !currentMusic.paused) return;

  const src = MUSIC_TRACKS[resolvedTrackName];
  if (!src) return;

  const vol = getMusicVolume();
  const newAudio = new Audio(src);
  newAudio.loop = true;
  newAudio.volume = immediate ? vol : 0;

  if (currentMusic && !currentMusic.paused) {
    if (immediate) {
      currentMusic.pause();
      currentMusic = newAudio;
      currentTrackName = resolvedTrackName;
      newAudio.play().catch(() => {});
    } else {
      const oldMusic = currentMusic;
      currentMusic = newAudio;
      currentTrackName = resolvedTrackName;
      fadeOut(oldMusic);
      fadeIn(newAudio, vol);
    }
  } else {
    currentMusic = newAudio;
    currentTrackName = resolvedTrackName;
    if (immediate) {
      newAudio.volume = vol;
      newAudio.play().catch(() => {});
    } else {
      fadeIn(newAudio, vol);
    }
  }
}

export function stopMusic() {
  if (currentMusic) {
    fadeOut(currentMusic);
    currentTrackName = null;
  }
}

export function getCurrentTrack() {
  return currentTrackName;
}

// === HEARTBEAT (low-HP urgency pulse) ===
let heartbeatInterval = null;

export function startHeartbeat(intervalMs = 600) {
  if (heartbeatInterval) return;
  const tick = () => {
    if (prefs.muted) return;
    SFX.heartbeatThump();
    setTimeout(() => { if (!prefs.muted) SFX.heartbeatThump(); }, 180);
  };
  tick();
  heartbeatInterval = setInterval(tick, intervalMs);
}

export function stopHeartbeat() {
  if (heartbeatInterval) {
    clearInterval(heartbeatInterval);
    heartbeatInterval = null;
  }
}
