# Dragon Forge: Terminal Intro & Sound System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the title screen with a full fake terminal boot sequence and add a complete sound system with synthesized SFX (Web Audio API) and HTML5 Audio music playback with per-screen tracks and combat intensity crossfading.

**Architecture:** Sound engine is a standalone module (`soundEngine.js`) with two subsystems: a Web Audio API synthesizer for all SFX and an HTML5 Audio player for music tracks. Terminal intro is a complete rewrite of TitleScreen.jsx with timed typewriter effects. Both systems integrate into existing screens via simple function calls.

**Tech Stack:** React 18, Web Audio API, HTML5 Audio, CSS animations

---

## File Map

| File | Responsibility |
|---|---|
| `src/soundEngine.js` | **Create:** SFX synthesis + music player + volume state |
| `src/SoundToggle.jsx` | **Create:** Mute button component for NavBar and title |
| `src/TitleScreen.jsx` | **Rewrite:** Full terminal boot sequence |
| `src/NavBar.jsx` | **Modify:** Add SoundToggle component |
| `src/HatcheryScreen.jsx` | **Modify:** Add SFX calls to egg animation |
| `src/BattleScreen.jsx` | **Modify:** Add SFX calls + music intensity switching |
| `src/BattleSelectScreen.jsx` | **Modify:** Add SFX to interactions |
| `src/App.jsx` | **Modify:** Add music transition calls on screen changes |
| `src/styles.css` | **Modify:** Add terminal styles |
| `assets/music/` | **Create:** Directory for user-provided music tracks |

---

## Task 1: Sound Engine — SFX Synthesizer

**Files:**
- Create: `src/soundEngine.js`

- [ ] **Step 1: Create src/soundEngine.js with the SFX synthesizer**

```js
// src/soundEngine.js

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

// === VOLUME STATE ===
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

// === ELEMENT PITCH OFFSETS ===
const ELEMENT_PITCH = {
  fire: -100,
  ice: 200,
  storm: 100,
  stone: -200,
  venom: 50,
  shadow: -150,
  neutral: 0,
};

// === SFX PRIMITIVES ===
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

// === SFX CATALOG ===
const SFX = {
  // UI
  buttonClick: () => playTone(800, 30, 'square', 0.5),
  buttonHover: () => playTone(800, 20, 'square', 0.2),
  navSwitch: () => playTone(600, 15, 'sine', 0.4),
  screenTransition: () => playNoise(200, 1500, 0.3),

  // Terminal
  terminalType: () => playTone(400, 5, 'square', 0.15),
  terminalOk: () => playTone(600, 50, 'sine', 0.4),
  terminalWarning: () => playTone(400, 100, 'sawtooth', 0.4),
  terminalFail: () => { playNoise(150, 800, 0.5); playTone(150, 150, 'sine', 0.5); },
  terminalGlitch: () => {
    playNoise(300, 3000, 0.6);
    playTone(Math.random() * 500 + 200, 100, 'sawtooth', 0.3);
    setTimeout(() => playTone(Math.random() * 800 + 100, 80, 'square', 0.2), 100);
  },

  // Hatchery
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

  // Combat
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

  // Progression
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

// === MUSIC PLAYER ===
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
```

- [ ] **Step 2: Create the assets/music directory**

```bash
mkdir -p assets/music
```

- [ ] **Step 3: Commit**

```bash
git add src/soundEngine.js
git commit -m "feat: sound engine — Web Audio SFX synthesizer + HTML5 Audio music player"
```

---

## Task 2: Sound Toggle Component

**Files:**
- Create: `src/SoundToggle.jsx`
- Modify: `src/styles.css`

- [ ] **Step 1: Create src/SoundToggle.jsx**

```jsx
import { useState } from 'react';
import { isMuted, toggleMute } from './soundEngine';

export default function SoundToggle() {
  const [muted, setMuted] = useState(isMuted());

  function handleToggle(e) {
    e.stopPropagation();
    const newMuted = toggleMute();
    setMuted(newMuted);
  }

  return (
    <button className="sound-toggle" onClick={handleToggle} title={muted ? 'Unmute' : 'Mute'}>
      {muted ? '🔇' : '🔊'}
    </button>
  );
}
```

- [ ] **Step 2: Add sound toggle CSS to styles.css**

Read `src/styles.css`. Find the `.nav-scraps` rule and add after it:

```css
.sound-toggle {
  font-size: 14px;
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px 8px;
  margin-left: 8px;
  opacity: 0.7;
  transition: opacity 0.15s;
}

.sound-toggle:hover {
  opacity: 1;
}
```

- [ ] **Step 3: Update NavBar to include SoundToggle**

Read `src/NavBar.jsx`. Replace with:

```jsx
import { loadSave } from './persistence';
import SoundToggle from './SoundToggle';

export default function NavBar({ activeScreen, onNavigate }) {
  const save = loadSave();

  return (
    <div className="nav-bar">
      <div className="nav-tabs">
        <button
          className={`nav-tab ${activeScreen === 'hatchery' ? 'active' : ''}`}
          onClick={() => onNavigate('hatchery')}
        >
          HATCHERY
        </button>
        <button
          className={`nav-tab ${activeScreen === 'battleSelect' ? 'active' : ''}`}
          onClick={() => onNavigate('battleSelect')}
        >
          BATTLES
        </button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div className="nav-scraps">◆ {save.dataScraps}</div>
        <SoundToggle />
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add src/SoundToggle.jsx src/NavBar.jsx src/styles.css
git commit -m "feat: sound toggle mute button in NavBar"
```

---

## Task 3: Terminal Boot Sequence

**Files:**
- Rewrite: `src/TitleScreen.jsx`
- Modify: `src/styles.css`

- [ ] **Step 1: Add terminal CSS to styles.css**

Read `src/styles.css`. Find the `/* === TITLE SCREEN === */` section and REPLACE everything from that comment through the `.enter-btn:hover` rule with:

```css
/* === TITLE SCREEN / TERMINAL === */
.terminal-screen {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #000000;
  padding: 24px;
  overflow: hidden;
  position: relative;
}

.terminal-output {
  flex: 1;
  overflow-y: auto;
  font-family: 'Press Start 2P', monospace;
  font-size: 9px;
  line-height: 2;
}

.terminal-line {
  display: flex;
  justify-content: space-between;
  white-space: pre;
}

.terminal-text {
  color: #44ff44;
}

.terminal-cursor {
  display: inline-block;
  width: 8px;
  height: 12px;
  background: #44ff44;
  animation: blink 0.7s step-end infinite;
  vertical-align: middle;
  margin-left: 2px;
}

.terminal-status {
  font-size: 8px;
  margin-left: 16px;
}

.terminal-status.ok { color: #44ff44; }
.terminal-status.warning { color: #ffcc00; }
.terminal-status.fail { color: #ff4444; }

.terminal-separator {
  color: #44ff44;
  font-size: 9px;
  letter-spacing: 0;
}

.terminal-felix-section {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  margin-top: 12px;
  animation: revealFadeIn 0.5s ease-out;
}

.terminal-felix-portrait {
  width: 120px;
  height: 120px;
  flex-shrink: 0;
  border: 2px solid #44ff44;
  overflow: hidden;
}

.terminal-dialogue {
  color: #ffffff;
  font-size: 9px;
  line-height: 2.2;
}

.terminal-init-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 11px;
  padding: 14px 28px;
  background: #000;
  color: #ff6622;
  border: 2px solid #ff6622;
  cursor: pointer;
  margin-top: 16px;
  align-self: center;
  transition: all 0.2s;
  animation: eggPulse 2s ease-in-out infinite;
}

.terminal-init-btn:hover {
  background: #ff6622;
  color: #000;
  box-shadow: 0 0 20px rgba(255, 102, 34, 0.4);
}

.terminal-sound-toggle {
  position: absolute;
  top: 12px;
  right: 12px;
}

@keyframes terminalGlitch {
  0% { filter: none; transform: none; }
  20% { filter: hue-rotate(90deg) contrast(200%); transform: translateX(-4px); }
  40% { filter: hue-rotate(180deg) saturate(300%); transform: translateX(4px) skewX(2deg); }
  60% { filter: hue-rotate(270deg) invert(80%); transform: translateY(-2px); }
  80% { filter: hue-rotate(45deg) contrast(150%); transform: translateX(2px); }
  100% { filter: none; transform: none; }
}

.terminal-glitch {
  animation: terminalGlitch 0.3s ease-in-out;
}
```

- [ ] **Step 2: Rewrite src/TitleScreen.jsx**

Read `src/TitleScreen.jsx` first, then replace entirely:

```jsx
import { useState, useEffect, useRef, useCallback } from 'react';
import { playSound, playMusic } from './soundEngine';
import SoundToggle from './SoundToggle';

const BOOT_LINES = [
  { text: '> DRAGON FORGE SYSTEMS v2.7.1', status: null, delay: 600 },
  { text: '> INITIALIZING KERNEL...', status: 'OK', delay: 800 },
  { text: '> LOADING ELEMENTAL MATRIX...', status: 'OK', delay: 1000 },
  { text: '> CALIBRATING QUANTUM RESONANCE...', status: 'OK', delay: 900 },
  { text: '> SCANNING FOR DRAGON SIGNATURES...', status: 'WARNING', delay: 1200 },
  { text: '> STABILITY INDEX: 23% — CRITICAL', status: 'FAIL', delay: 800 },
];

const FELIX_LINES = [
  '"The Elemental Matrix is collapsing.',
  ' Something is draining it from the inside.',
  ' I\'ve traced the source... The Singularity.',
  ' It\'s consuming dragon energy faster than',
  ' we can stabilize it."',
  '',
  '"I need a Dragon Forger. Someone who can',
  ' hatch, train, and fight. That\'s you."',
];

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export default function TitleScreen({ onStart }) {
  const [lines, setLines] = useState([]);
  const [typingText, setTypingText] = useState('');
  const [showCursor, setShowCursor] = useState(true);
  const [phase, setPhase] = useState('boot'); // boot, glitch, felix, ready
  const [felixVisible, setFelixVisible] = useState(false);
  const [felixLines, setFelixLines] = useState([]);
  const [showButton, setShowButton] = useState(false);
  const [glitching, setGlitching] = useState(false);
  const skippedRef = useRef(false);
  const containerRef = useRef(null);

  const scrollToBottom = () => {
    if (containerRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight;
    }
  };

  const typeText = useCallback(async (text, charDelay = 50) => {
    for (let i = 0; i <= text.length; i++) {
      if (skippedRef.current) return text;
      setTypingText(text.slice(0, i));
      if (i < text.length) playSound('terminalType');
      await wait(charDelay);
      scrollToBottom();
    }
    return text;
  }, []);

  const runBootSequence = useCallback(async () => {
    playMusic('title');

    for (const line of BOOT_LINES) {
      if (skippedRef.current) break;
      await typeText(line.text);
      setTypingText('');

      let statusEl = null;
      if (line.status) {
        await wait(200);
        if (line.status === 'OK') playSound('terminalOk');
        else if (line.status === 'WARNING') playSound('terminalWarning');
        else if (line.status === 'FAIL') playSound('terminalFail');
        statusEl = line.status;
      }

      setLines((prev) => [...prev, { text: line.text, status: statusEl }]);
      await wait(line.delay);
      scrollToBottom();
    }

    if (skippedRef.current) {
      // Show all boot lines immediately
      setLines(BOOT_LINES.map((l) => ({ text: l.text, status: l.status })));
      setTypingText('');
    }

    // Glitch
    setPhase('glitch');
    setGlitching(true);
    playSound('terminalGlitch');
    await wait(300);
    setGlitching(false);

    // Felix section
    setPhase('felix');
    setLines((prev) => [
      ...prev,
      { text: '> ==========================================', status: null },
      { text: '> EMERGENCY BROADCAST — DR. FELIX', status: null },
      { text: '> ==========================================', status: null },
    ]);
    scrollToBottom();
    await wait(400);

    setFelixVisible(true);
    scrollToBottom();

    // Type Felix's dialogue
    skippedRef.current = false;
    for (const line of FELIX_LINES) {
      if (skippedRef.current) break;
      if (line === '') {
        setFelixLines((prev) => [...prev, '']);
        await wait(300);
        continue;
      }
      await typeText(line, 40);
      setTypingText('');
      setFelixLines((prev) => [...prev, line]);
      scrollToBottom();
    }

    if (skippedRef.current) {
      setFelixLines([...FELIX_LINES]);
      setTypingText('');
    }

    setPhase('ready');
    setShowButton(true);
    setShowCursor(false);
    scrollToBottom();
  }, [typeText]);

  useEffect(() => {
    runBootSequence();
  }, [runBootSequence]);

  const handleClick = () => {
    if (phase === 'boot') {
      skippedRef.current = true;
    } else if (phase === 'felix') {
      skippedRef.current = true;
    }
  };

  const handleStart = () => {
    playSound('buttonClick');
    onStart();
  };

  return (
    <div className={`terminal-screen ${glitching ? 'terminal-glitch' : ''}`} onClick={handleClick}>
      <div className="terminal-sound-toggle">
        <SoundToggle />
      </div>

      <div className="terminal-output" ref={containerRef}>
        {lines.map((line, i) => (
          <div key={i} className="terminal-line">
            <span className="terminal-text">{line.text}</span>
            {line.status && (
              <span className={`terminal-status ${line.status.toLowerCase()}`}>[{line.status}]</span>
            )}
          </div>
        ))}

        {typingText && (
          <div className="terminal-line">
            <span className="terminal-text">
              {typingText}
              {showCursor && <span className="terminal-cursor" />}
            </span>
          </div>
        )}

        {felixVisible && (
          <div className="terminal-felix-section">
            <div className="terminal-felix-portrait">
              <img
                src="/assets/felix_pixel.jpg"
                alt="Professor Felix"
                className="pixelated"
                style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
              />
            </div>
            <div className="terminal-dialogue">
              {felixLines.map((line, i) => (
                <div key={i}>{line || '\u00A0'}</div>
              ))}
              {phase === 'felix' && typingText && (
                <div>
                  {typingText}
                  {showCursor && <span className="terminal-cursor" />}
                </div>
              )}
            </div>
          </div>
        )}

        {showButton && (
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 20 }}>
            <button className="terminal-init-btn" onClick={handleStart}>
              INITIALIZE_SIMULATION.EXE
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Verify build**

Run: `npx vite build`
Expected: Clean build.

- [ ] **Step 4: Commit**

```bash
git add src/TitleScreen.jsx src/styles.css
git commit -m "feat: full terminal boot sequence with typewriter, glitch, and Felix broadcast"
```

---

## Task 4: Music Transitions in App.jsx

**Files:**
- Modify: `src/App.jsx`

- [ ] **Step 1: Update App.jsx with music transitions**

Read `src/App.jsx` first, then replace:

```jsx
import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import HatcheryScreen from './HatcheryScreen';
import { playMusic, stopMusic, playSound } from './soundEngine';

const SCREENS = {
  TITLE: 'title',
  HATCHERY: 'hatchery',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);

  function handleStartGame() {
    playSound('screenTransition');
    playMusic('hatchery');
    setScreen(SCREENS.HATCHERY);
  }

  function handleNavigate(target) {
    playSound('navSwitch');
    if (target === 'hatchery') {
      playMusic('hatchery');
      setScreen(SCREENS.HATCHERY);
    } else if (target === 'battleSelect') {
      playMusic('select');
      setScreen(SCREENS.BATTLE_SELECT);
    }
  }

  function handleBeginBattle(config) {
    playSound('buttonClick');
    playMusic('battle', true);
    setBattleConfig(config);
    setScreen(SCREENS.BATTLE);
  }

  function handleBattleEnd() {
    playMusic('select');
    setBattleConfig(null);
    setScreen(SCREENS.BATTLE_SELECT);
  }

  return (
    <div className="app">
      {screen === SCREENS.TITLE && (
        <TitleScreen onStart={handleStartGame} />
      )}
      {screen === SCREENS.HATCHERY && (
        <HatcheryScreen onNavigate={handleNavigate} />
      )}
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} onNavigate={handleNavigate} />
      )}
      {screen === SCREENS.BATTLE && battleConfig && (
        <BattleScreen
          dragonId={battleConfig.dragonId}
          npcId={battleConfig.npcId}
          onBattleEnd={handleBattleEnd}
        />
      )}
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/App.jsx
git commit -m "feat: music transitions on screen changes"
```

---

## Task 5: Hatchery SFX Integration

**Files:**
- Modify: `src/HatcheryScreen.jsx`

- [ ] **Step 1: Add SFX to hatchery animation**

Read `src/HatcheryScreen.jsx`. Add import at top:

```jsx
import { playSound } from './soundEngine';
```

In the `animateHatch` function, add SFX calls to the hatch sequence. Find the `for (const step of HATCH_SEQUENCE)` loop and replace the entire `animateHatch` callback:

```jsx
  const animateHatch = useCallback(async (element) => {
    skippedRef.current = false;
    setEggSheet(eggSheets.generic);
    setEggFrame(0);
    setPhase(PHASES.HATCHING);

    await wait(300);
    if (skippedRef.current) return;

    setEggSheet(eggSheets[element] || eggSheets.generic);
    playSound('eggGlow');

    for (const step of HATCH_SEQUENCE) {
      if (skippedRef.current) return;
      setEggFrame(step.frame);

      // SFX per frame type
      if (step.frame === 1) playSound('eggGlow');
      else if (step.frame === 2 || step.frame === 3) playSound('eggCrack');
      else if (step.frame === 4 || step.frame === 5) playSound('eggShake');
      else if (step.frame === 6) playSound('hatchBurst');
      else if (step.frame === 7) playSound('dragonReveal');

      await wait(step.duration);
    }
  }, []);
```

Also add SFX to pull button clicks. In `handlePull1`, add at the start:
```jsx
    playSound('buttonClick');
```

In `handlePull10`, add at the start:
```jsx
    playSound('buttonClick');
```

- [ ] **Step 2: Commit**

```bash
git add src/HatcheryScreen.jsx
git commit -m "feat: SFX in hatchery — egg glow, crack, shake, burst, reveal sounds"
```

---

## Task 6: Battle SFX & Music Intensity

**Files:**
- Modify: `src/BattleScreen.jsx`

- [ ] **Step 1: Add SFX and music intensity to BattleScreen**

Read `src/BattleScreen.jsx`. Add import at top:

```jsx
import { playSound, playMusic, stopMusic } from './soundEngine';
```

In the `animateEvent` callback, add SFX. Find the defend section and add:
```jsx
    if (event.action === 'defend') {
      playSound('defend');
```

Find the TELEGRAPH comment and add after the `await wait(400)`:
```jsx
    playSound('attackLaunch', { element: actor.state?.element });
```
(Actually this needs to reference the event — use `event` context. Add `playSound('attackLaunch', { element: event.moveKey === 'basic_attack' ? 'neutral' : undefined })` right before the TELEGRAPH await. Simpler approach: just add it at the start of the non-defend branch.)

Replace the entire `animateEvent` callback with this version that includes SFX:

```jsx
  const animateEvent = useCallback(async (event, dispatch) => {
    const isPlayer = event.attacker === 'player';

    if (event.action === 'defend') {
      playSound('defend');
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
        await wait(400);
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      }
      return;
    }

    // TELEGRAPH phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-telegraph' });
    }
    playSound('attackLaunch');
    await wait(400);

    // IMPACT phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: 3 });
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_NPC_ATTACKING', value: true });
    }

    if (event.hit) {
      if (isPlayer) {
        dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
      } else {
        dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
      }
      // Hit SFX based on effectiveness
      if (event.effectiveness > 1.0) playSound('superEffective');
      else if (event.effectiveness < 1.0) playSound('resisted');
      else playSound('attackHit');
    } else {
      playSound('miss');
    }

    const dmgId = ++damageIdCounter;
    dispatch({
      type: 'ADD_DAMAGE_NUMBER',
      entry: {
        id: dmgId,
        damage: event.damage,
        effectiveness: event.effectiveness,
        hit: event.hit,
        target: isPlayer ? 'npc' : 'player',
      },
    });
    await wait(300);

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
    await wait(200);
  }, []);
```

In the `handleMoveSelect` function, add SFX to the victory/defeat sections. Find the victory block and add sounds:

After `dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' })`:
```jsx
      playSound('ko');
```

After `dispatch({ type: 'SET_VICTORY', ... })`:
```jsx
      stopMusic();
      playSound('victoryFanfare');
      playSound('xpGain');
      if (scrapsGained > 0) setTimeout(() => playSound('scrapsEarned'), 200);
      if (leveledUp) setTimeout(() => playSound('levelUp'), 400);
```

For defeat, after `dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-ko' })`:
```jsx
      playSound('ko');
```

After `dispatch({ type: 'SET_DEFEAT' })`:
```jsx
      stopMusic();
      playSound('defeatDrone');
```

Add music intensity check after each turn resolves. In the `RESET_TURN` branch (the `else` at the end), add HP check:

```jsx
    } else {
      // Check for low HP music intensity
      const playerHpPct = result.player.hp / state.playerMaxHp;
      const npcHpPct = result.npc.hp / state.npcMaxHp;
      if (playerHpPct < 0.25 || npcHpPct < 0.25) {
        playMusic('battleIntense');
      } else {
        playMusic('battle');
      }
      dispatch({ type: 'RESET_TURN' });
    }
```

Also add `playSound('buttonClick')` at the start of `handleMoveSelect` (before the animating check).

- [ ] **Step 2: Verify build**

Run: `npx vite build`
Expected: Clean build.

- [ ] **Step 3: Commit**

```bash
git add src/BattleScreen.jsx
git commit -m "feat: battle SFX — attack/hit/ko sounds + music intensity crossfade on low HP"
```

---

## Task 7: Battle Select SFX

**Files:**
- Modify: `src/BattleSelectScreen.jsx`

- [ ] **Step 1: Add SFX to battle select interactions**

Read `src/BattleSelectScreen.jsx`. Add import:

```jsx
import { playSound } from './soundEngine';
```

Add `playSound('buttonClick')` to card click handlers. In the dragon card `onClick`:
```jsx
onClick={() => { playSound('buttonClick'); setSelectedDragon(dragon); }}
```

In the NPC card `onClick`:
```jsx
onClick={() => { playSound('buttonClick'); setSelectedNpc(npc); }}
```

In `handleBegin`:
```jsx
  function handleBegin() {
    if (!selectedDragon || !selectedNpc) return;
    playSound('buttonClick');
    onBeginBattle({ dragonId: selectedDragon.id, npcId: selectedNpc.id });
  }
```

- [ ] **Step 2: Commit**

```bash
git add src/BattleSelectScreen.jsx
git commit -m "feat: SFX on battle select card clicks and begin battle button"
```

---

## Task 8: Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run all tests**

Run: `npx vitest run`
Expected: All tests PASS.

- [ ] **Step 2: Run production build**

Run: `npm run build`
Expected: Clean build, no errors.

- [ ] **Step 3: Manual playthrough**

Run: `npm run dev`
Verify:
1. Terminal boot sequence types out system lines with [OK]/[WARNING]/[FAIL] tags
2. Glitch flicker before Felix's message
3. Felix portrait appears, dialogue types out
4. Click to skip works during boot and Felix phases
5. INITIALIZE_SIMULATION.EXE button appears, click transitions to hatchery
6. Sound toggle works in NavBar and title screen
7. SFX plays on: button clicks, egg animation, hatch, combat attacks/hits/KO, victory/defeat
8. If music files exist in assets/music/, tracks crossfade between screens
9. If no music files, game works silently with only SFX
10. Low HP in battle triggers intense music crossfade (if track exists)
11. Mute toggle silences everything, preference persists on reload

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: terminal intro and sound system complete"
```
