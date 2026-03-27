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

const ELEMENT_PITCH = {
  fire: -100,
  ice: 200,
  storm: 100,
  stone: -200,
  venom: 50,
  shadow: -150,
  neutral: 0,
};

function playTone(freq, duration, type = 'square', volume = 1.0) {
  const ctx = getCtx();
  const vol = getSfxVolume() * volume;
  if (vol === 0) return;

  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.type = type;
  osc.frequency.value = freq;
  gain.gain.setValueAtTime(vol * 0.3, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration / 1000);
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.start();
  osc.stop(ctx.currentTime + duration / 1000);
}

function playNoise(duration, filterFreq = 2000, volume = 1.0) {
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
  filter.type = 'lowpass';
  filter.frequency.value = filterFreq;

  const gain = ctx.createGain();
  gain.gain.setValueAtTime(vol * 0.2, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration / 1000);

  source.connect(filter);
  filter.connect(gain);
  gain.connect(ctx.destination);
  source.start();
}

function playArpeggio(notes, noteType = 'square', noteDuration = 80) {
  notes.forEach((freq, i) => {
    setTimeout(() => playTone(freq, noteDuration, noteType, 0.8), i * noteDuration);
  });
}

const SFX = {
  buttonClick: () => playTone(800, 30, 'square', 0.5),
  buttonHover: () => playTone(800, 20, 'square', 0.2),
  navSwitch: () => playTone(600, 15, 'sine', 0.4),
  screenTransition: () => playNoise(200, 1500, 0.3),

  terminalType: () => playTone(400, 5, 'square', 0.15),
  terminalOk: () => playTone(600, 50, 'sine', 0.4),
  terminalWarning: () => playTone(400, 100, 'sawtooth', 0.4),
  terminalFail: () => { playNoise(150, 800, 0.5); playTone(150, 150, 'sine', 0.5); },
  terminalGlitch: () => {
    playNoise(300, 3000, 0.6);
    playTone(Math.random() * 500 + 200, 100, 'sawtooth', 0.3);
    setTimeout(() => playTone(Math.random() * 800 + 100, 80, 'square', 0.2), 100);
  },

  eggGlow: () => {
    const ctx = getCtx();
    if (getSfxVolume() === 0) return;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(200, ctx.currentTime);
    osc.frequency.linearRampToValueAtTime(400, ctx.currentTime + 0.2);
    gain.gain.setValueAtTime(getSfxVolume() * 0.2, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.2);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + 0.2);
  },
  eggCrack: () => { playNoise(50, 3000, 0.6); playTone(200, 50, 'sine', 0.5); },
  eggShake: () => playNoise(80, 600, 0.4),
  hatchBurst: () => {
    playNoise(300, 4000, 0.7);
    const ctx = getCtx();
    if (getSfxVolume() === 0) return;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(300, ctx.currentTime);
    osc.frequency.linearRampToValueAtTime(1200, ctx.currentTime + 0.3);
    gain.gain.setValueAtTime(getSfxVolume() * 0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.3);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + 0.3);
  },
  dragonReveal: () => playArpeggio([523, 659, 784], 'square', 100),

  attackLaunch: (opts) => {
    const offset = ELEMENT_PITCH[opts?.element] || 0;
    playNoise(150, 2000 + offset, 0.4);
    playTone(300 + offset, 100, 'sine', 0.3);
  },
  attackHit: (opts) => {
    const offset = ELEMENT_PITCH[opts?.element] || 0;
    playNoise(80, 600 + offset, 0.6);
    playTone(200 + offset, 60, 'sine', 0.5);
  },
  superEffective: (opts) => {
    SFX.attackHit(opts);
    setTimeout(() => playTone(1200, 200, 'sine', 0.5), 50);
  },
  resisted: () => playNoise(100, 400, 0.3),
  miss: () => {
    const ctx = getCtx();
    if (getSfxVolume() === 0) return;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, ctx.currentTime);
    osc.frequency.linearRampToValueAtTime(400, ctx.currentTime + 0.2);
    gain.gain.setValueAtTime(getSfxVolume() * 0.15, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.2);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + 0.2);
  },
  defend: () => { playTone(300, 150, 'sine', 0.5); playTone(450, 150, 'sine', 0.4); },
  ko: () => {
    const ctx = getCtx();
    if (getSfxVolume() === 0) return;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(200, ctx.currentTime);
    osc.frequency.linearRampToValueAtTime(60, ctx.currentTime + 0.8);
    gain.gain.setValueAtTime(getSfxVolume() * 0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.8);
    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = 800;
    osc.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + 0.8);
  },
  victoryFanfare: () => playArpeggio([523, 659, 784, 1047], 'square', 80),
  defeatDrone: () => {
    playTone(60, 800, 'sawtooth', 0.4);
    playNoise(800, 300, 0.2);
  },

  xpGain: () => playTone(1000, 40, 'sine', 0.3),
  levelUp: () => playArpeggio([523, 659, 784, 1047], 'square', 80),
  scrapsEarned: () => { playTone(1400, 30, 'sine', 0.3); setTimeout(() => playTone(1400, 30, 'sine', 0.3), 60); },
};

export function playSound(name, options) {
  const fn = SFX[name];
  if (fn) {
    try { fn(options); } catch { /* ignore audio errors */ }
  }
}

let currentMusic = null;
let currentTrackName = null;

const MUSIC_TRACKS = {
  title: '/assets/music/music_title.mp3',
  hatchery: '/assets/music/music_hatchery.mp3',
  select: '/assets/music/music_select.mp3',
  battle: '/assets/music/music_battle.mp3',
  battleIntense: '/assets/music/music_battle_intense.mp3',
};

function fadeOut(audio, duration = 1000) {
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

function fadeIn(audio, targetVol, duration = 1000) {
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
