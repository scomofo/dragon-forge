import { getScoreDuration, noteFrequency } from './musicScores';

const VOICES = {
  lead: { wave: 'triangle', level: 0.24, attack: 0.025, cutoff: 2600 },
  bass: { wave: 'triangle', level: 0.3, attack: 0.018, cutoff: 650 },
  pad: { wave: 'sine', level: 0.12, attack: 0.15, cutoff: 1200 },
  bell: { wave: 'sine', level: 0.25, attack: 0.006, cutoff: 4200 },
  tick: { wave: 'square', level: 0.035, attack: 0.004, cutoff: 500 },
};

// Schedule against the audio clock; a late UI frame cannot move individual
// notes. Only a short window is queued, and every queued voice is disposable.
export function startScore(ctx, score, volume, { onEnded } = {}) {
  const master = ctx.createGain();
  master.gain.value = volume * score.gain;
  master.connect(ctx.destination);
  const voices = new Set();
  const beatSeconds = 60 / score.bpm;
  const duration = getScoreDuration(score);
  let origin = ctx.currentTime + 0.03;
  let index = 0;
  let stopped = false;
  let timer = null;

  function schedule(event, when) {
    const spec = VOICES[event.voice];
    const oscillator = ctx.createOscillator();
    const envelope = ctx.createGain();
    const filter = ctx.createBiquadFilter();
    oscillator.type = spec.wave;
    oscillator.frequency.value = noteFrequency(event.pitch);
    filter.type = 'lowpass';
    filter.frequency.value = spec.cutoff;
    filter.Q.value = 0.5;
    const end = when + event.duration * beatSeconds;
    const attack = Math.min(spec.attack, (end - when) / 3);
    envelope.gain.setValueAtTime(0, when);
    envelope.gain.linearRampToValueAtTime(event.velocity * spec.level, when + attack);
    envelope.gain.exponentialRampToValueAtTime(0.0001, end);
    oscillator.connect(filter);
    filter.connect(envelope);
    envelope.connect(master);
    const voice = { oscillator, filter, envelope };
    voices.add(voice);
    oscillator.onended = () => {
      oscillator.disconnect();
      filter.disconnect();
      envelope.disconnect();
      voices.delete(voice);
    };
    oscillator.start(when);
    oscillator.stop(end);
  }

  function stop() {
    if (stopped) return;
    stopped = true;
    clearInterval(timer);
    master.gain.value = 0;
    for (const { oscillator, filter, envelope } of voices) {
      oscillator.onended = null;
      try { oscillator.stop(); } catch { /* already ended */ }
      oscillator.disconnect();
      filter.disconnect();
      envelope.disconnect();
    }
    voices.clear();
    master.disconnect();
  }

  function tick() {
    if (stopped) return;
    const now = ctx.currentTime;
    // If background-tab throttling missed a whole loop, advance the musical
    // clock without bursting through minutes of obsolete notes on return.
    if (score.loop && now >= origin + duration) {
      origin += Math.floor((now - origin) / duration) * duration;
      index = 0;
    }
    while (!stopped) {
      if (index === score.events.length) {
        if (now + 0.12 < origin + duration) break;
        if (!score.loop) {
          if (now >= origin + duration) { stop(); onEnded?.(); }
          break;
        }
        origin += duration;
        index = 0;
      }
      const event = score.events[index];
      const when = origin + event.beat * beatSeconds;
      if (when >= now + 0.12) break;
      if (when >= now - 0.02) schedule(event, Math.max(now, when));
      index += 1;
    }
  }

  tick();
  timer = setInterval(tick, 25);
  return {
    stop,
    setVolume(value) { if (!stopped) master.gain.value = value * score.gain; },
  };
}
