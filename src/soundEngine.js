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
  attackLaunch: (opts) => {
    const p = ELEMENT_PITCH[opts?.element] || 0;
    noise(180, 2500 + p, 'bandpass', 0.4);
    sweep(250 + p, 500 + p, 150, 'sine', 0.3);
    osc(300 + p, 80, 'sawtooth', 0.15);
  },

  attackHit: (opts) => {
    const p = ELEMENT_PITCH[opts?.element] || 0;
    noise(100, 800 + p, 'lowpass', 0.6);
    osc(180 + p, 60, 'triangle', 0.5);
    osc(120 + p, 40, 'sine', 0.3);
    noise(50, 3000, 'highpass', 0.2);
  },

  superEffective: (opts) => {
    SFX.attackHit(opts);
    setTimeout(() => {
      sweep(800, 1600, 200, 'sine', 0.4);
      osc(1200, 150, 'square', 0.2);
      noise(80, 5000, 'highpass', 0.2);
    }, 60);
  },

  criticalHit: (opts) => {
    const p = ELEMENT_PITCH[opts?.element] || 0;
    // Heavier impact body
    noise(140, 600 + p, 'lowpass', 0.7);
    osc(150 + p, 90, 'triangle', 0.6);
    // Piercing bell sweep on top — the NES "this matters" cue
    sweep(900, 2400, 240, 'sine', 0.45);
    osc(1800, 180, 'square', 0.25);
    setTimeout(() => {
      osc(2400, 120, 'sine', 0.2);
      noise(60, 6000, 'highpass', 0.25);
    }, 80);
  },

  lungeContact: () => {
    // Short whip/swoosh at the contact frame
    sweep(1400, 600, 70, 'sine', 0.25);
    noise(50, 3500, 'highpass', 0.18);
  },

  shieldDeflectSting: () => {
    // Metallic ping
    osc(1600, 60, 'square', 0.35);
    osc(2400, 50, 'sine', 0.25);
    noise(40, 5000, 'highpass', 0.2);
    setTimeout(() => osc(1200, 80, 'triangle', 0.15), 30);
  },

  heartbeatThump: () => {
    osc(80, 90, 'sine', 0.35);
    osc(60, 120, 'triangle', 0.2);
  },

  resisted: () => {
    noise(120, 500, 'lowpass', 0.3);
    osc(200, 80, 'sine', 0.2);
  },

  miss: () => {
    sweep(900, 350, 250, 'sine', 0.15);
    noise(150, 1500, 'bandpass', 0.1);
  },

  defend: () => {
    osc(280, 120, 'triangle', 0.4);
    osc(420, 120, 'triangle', 0.3);
    noise(60, 2000, 'highpass', 0.3);
    setTimeout(() => osc(560, 80, 'sine', 0.2), 60);
  },

  ko: () => {
    sweep(250, 50, 900, 'sawtooth', 0.35);
    noise(600, 600, 'lowpass', 0.25);
    setTimeout(() => noise(400, 300, 'lowpass', 0.2), 400);
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

export function playSound(name, options) {
  const fn = SFX[name];
  if (fn) {
    try { fn(options); } catch { /* ignore audio errors */ }
  }
}

// === MUSIC ===

let currentMusic = null;
let currentTrackName = null;

const MUSIC_TRACKS = {
  title: '/assets/music/theme.mp3',
  hatchery: '/assets/music/music_hatchery.mp3',
  select: '/assets/music/music_select.mp3',
  battle: '/assets/music/music_battle.mp3',
  battleIntense: '/assets/music/music_battle_intense.mp3',
};

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
  if (currentTrackName === trackName && currentMusic && !currentMusic.paused) return;

  const src = MUSIC_TRACKS[trackName];
  if (!src) return;

  const vol = getMusicVolume();
  const newAudio = new Audio(src);
  newAudio.loop = true;
  newAudio.volume = immediate ? vol : 0;

  if (currentMusic && !currentMusic.paused) {
    if (immediate) {
      currentMusic.pause();
      currentMusic = newAudio;
      currentTrackName = trackName;
      newAudio.play().catch(() => {});
    } else {
      const oldMusic = currentMusic;
      currentMusic = newAudio;
      currentTrackName = trackName;
      fadeOut(oldMusic);
      fadeIn(newAudio, vol);
    }
  } else {
    currentMusic = newAudio;
    currentTrackName = trackName;
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
