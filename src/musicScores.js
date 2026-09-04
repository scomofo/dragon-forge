// Fixed, editable arrangements. Beats are quarter notes in 4/4, pitches are
// MIDI note numbers. No random composition or dependency on the render loop.
// These are synthesized score drafts, not claims of mastered SNES samples.
export const HEARTFORGE_BPM = 112;
export const HEARTFORGE_MOTIF = [
  [0, 60, 1], [1, 63, 1], [2, 67, 1], [3, 68, 1],
  [4, 67, 1], [5, 65, 1], [6, 63, 1], [7, 62, 1],
  [8, 63, 1], [9, 65, 1], [10, 67, 1], [11, 72, 1],
  [12, 59, 1], [13, 60, 3],
];

const FRACTURE = [
  [0, 68, 2], [2, 67, 1], [3, 63, 1],
  [4, 65, 1.5], [5.5, 63, 0.5], [6, 62, 2],
  [8, 60, 1], [9, 62, 1], [10, 63, 2],
  [12, 62, 1], [13, 59, 1], [14, 55, 2],
];
const PROMISE = [
  [0, 63, 1], [1, 67, 1], [2, 72, 2],
  [4, 70, 1], [5, 68, 1], [6, 67, 2],
  [8, 65, 1], [9, 63, 1], [10, 62, 1], [11, 59, 1],
  [12, 60, 3],
];

function phrase(events, notes, at, transpose = 0, velocity = 0.8) {
  for (const [beat, pitch, duration] of notes) {
    events.push({ beat: at + beat, pitch: pitch + transpose,
      duration: duration * 0.9, voice: 'lead', velocity });
  }
}

function harmony(events, bars, { mirror = false } = {}) {
  bars.forEach(([bass, chord], bar) => {
    const beat = bar * 4;
    events.push({ beat, pitch: bass, duration: 3.7, voice: 'bass', velocity: 0.65 });
    chord.forEach(pitch => events.push({ beat: beat + 0.05, pitch,
      duration: 3.5, voice: 'pad', velocity: mirror ? 0.35 : 0.28 }));
    // Broken chords answer the lead; the half-time version leaves more air.
    const offsets = mirror ? [1.5, 3.5] : [0.5, 1.5, 2.5, 3.5];
    offsets.forEach((offset, i) => events.push({ beat: beat + offset,
      pitch: chord[(bar + i) % chord.length] + 12,
      duration: 0.4, voice: 'bell', velocity: mirror ? 0.28 : 0.4 }));
    if (mirror) {
      // No percussion on beat one: the caretaker's missing heartbeat.
      events.push({ beat: beat + 2, pitch: 48, duration: 0.16, voice: 'tick', velocity: 0.3 });
    }
  });
}

const Cm = [48, 51, 55];
const Ab = [48, 51, 56];
const Fm = [48, 53, 56];
const G = [47, 50, 55];

function arrange(mirror) {
  const events = [];
  phrase(events, HEARTFORGE_MOTIF, 0);
  phrase(events, FRACTURE, 16, mirror ? -12 : 0, 0.72);
  phrase(events, HEARTFORGE_MOTIF, 32, 0, 0.9);
  phrase(events, PROMISE, 48, 0, 0.75);
  const opening = mirror
    ? [[32, Ab], [41, Fm], [36, Cm], [31, G]]
    : [[36, Cm], [32, Ab], [41, Fm], [31, G]];
  harmony(events, [
    ...opening,
    [32, Ab], [41, Fm], [36, Cm], [31, G],
    ...opening,
    [32, Ab], [41, Fm], [31, G], [36, Cm],
  ], { mirror });
  return events.sort((a, b) => a.beat - b.beat);
}

export const MUSIC_SCORES = {
  heartforge: {
    title: 'Heartforge — Motif Study', bpm: HEARTFORGE_BPM, beats: 64,
    gain: 0.34, loop: true, events: arrange(false),
    sections: ['Question', 'Fracture', 'Return', 'Promise'],
  },
  mirrorAdmin: {
    title: 'The Caretaker — Mirror Arrangement', bpm: HEARTFORGE_BPM / 2, beats: 64,
    gain: 0.34, loop: true, events: arrange(true),
    sections: ['Remember', 'Fracture', 'Recognize', 'Let Go'],
  },
};

export function getScoreDuration(score) {
  return score.beats * 60 / score.bpm;
}

export function noteFrequency(pitch) {
  return 440 * 2 ** ((pitch - 69) / 12);
}
