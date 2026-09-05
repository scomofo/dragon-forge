#!/usr/bin/env python3
"""Score-driven chiptune renderer for Dragon Forge P2 music (SNES-AAA).

A score is a Python module with a SCORE dict:

    SCORE = {
        'bpm': 108,
        'voices': [
            {'wave': 'pulse25', 'gain': 0.5, 'echo': 0.35, 'vibrato': (5.5, 0.35),
             'notes': [('C4', 1), ('Eb4', 1), ('R', 0.5), ...]},
            ...
        ],
        'percussion': [  # optional; grid of 16th-note steps per bar
            {'type': 'kick',  'gain': 0.8, 'steps': [1,0,0,0, ...]},
            {'type': 'hat',   'gain': 0.3, 'steps': [...]},
            {'type': 'snare', 'gain': 0.5, 'steps': [...]},
        ],
    }

Notes are (name, beats) tuples; 'R' is a rest. Beats are quarter-note units at
the score's BPM. Note names use scientific pitch notation (C4 = middle C,
A4 = 440 Hz); sharps as 'C#4', flats as 'Db4'.

Voices are SNES-flavored: pulse12/pulse25/pulse50 (duty-cycle square),
triangle (bass), sine (flute lead), noise. An SNES-style feedback echo and a
gentle master lowpass keep it out of NES territory. Renders 44.1kHz 16-bit
stereo WAV; ffmpeg converts to mp3 (see render_score()).

Usage:  python3 tools/music/render.py tools/music/scores/mirror_admin.py
"""
from __future__ import annotations

import importlib.util
import math
import struct
import subprocess
import sys
import wave
from pathlib import Path

SR = 44100
REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / 'public' / 'assets' / 'music'

NOTE_BASE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def note_hz(name: str) -> float:
    """'C4' / 'F#3' / 'Bb5' -> frequency in Hz (A4 = 440)."""
    if name == 'R':
        return 0.0
    base = NOTE_BASE[name[0].upper()]
    i = 1
    if len(name) > 1 and name[1] in '#b':
        base += 1 if name[1] == '#' else -1
        i = 2
    octave = int(name[i:])
    midi = (octave + 1) * 12 + base
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))


def _osc(wave_kind: str, phase: float) -> float:
    """Bandlimited-ish oscillators. phase in cycles [0,1)."""
    p = phase % 1.0
    if wave_kind == 'pulse12':
        return 1.0 if p < 0.125 else -1.0
    if wave_kind == 'pulse25':
        return 1.0 if p < 0.25 else -1.0
    if wave_kind == 'pulse50':
        return 1.0 if p < 0.5 else -1.0
    if wave_kind == 'triangle':
        return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p
    if wave_kind == 'sine':
        return math.sin(2.0 * math.pi * p)
    if wave_kind == 'saw':
        return 2.0 * p - 1.0
    return math.sin(2.0 * math.pi * p)


def _envelope(t: float, dur: float, attack: float = 0.008, release_frac: float = 0.18) -> float:
    """Linear attack / sustain / linear release over the note's duration."""
    if t < attack:
        return t / attack
    rel = dur * release_frac
    if t > dur - rel:
        return max(0.0, (dur - t) / rel)
    return 1.0


def _render_voice(voice: dict, beat_s: float) -> list[float]:
    wave_kind = voice.get('wave', 'pulse25')
    gain = voice.get('gain', 0.4)
    vib_hz, vib_depth = voice.get('vibrato', (0.0, 0.0))  # Hz, semitone fraction
    notes = voice['notes']
    total_s = sum(b for _, b in notes) * beat_s
    n = int(total_s * SR)
    out = [0.0] * n

    idx = 0
    for name, beats in notes:
        dur = beats * beat_s
        count = int(dur * SR)
        if name != 'R':
            hz = note_hz(name)
            legato = voice.get('legato', False)
            phase = 0.0
            for i in range(count):
                t = i / SR
                # True FM vibrato: advance phase by the instantaneous frequency
                # (±vib_depth semitones at vib_hz), not by rescaling time.
                if vib_hz and t > 0.12:  # vibrato fades in
                    inst = hz * (2.0 ** (vib_depth * math.sin(2 * math.pi * vib_hz * t) / 12.0))
                else:
                    inst = hz
                phase += inst / SR
                env = _envelope(t, dur, release_frac=0.06 if legato else 0.18)
                j = idx + i
                if j < n:
                    out[j] += _osc(wave_kind, phase) * env * gain
        idx += count
    return out


def _noise_hit(kind: str) -> tuple[float, float]:
    """(pitch-ish filter freq, decay seconds) per percussion type."""
    return {'kick': (120.0, 0.14), 'snare': (1800.0, 0.11), 'hat': (7000.0, 0.045)}[kind]


def _render_percussion(perc: list[dict], beat_s: float, bars: float) -> list[float]:
    """16th-note-step grid percussion. One bar = 16 steps."""
    import random
    rng = random.Random(7)
    bar_s = beat_s * 4.0
    total_s = bar_s * bars
    n = int(total_s * SR)
    out = [0.0] * n
    for lane in perc:
        kind = lane['type']
        gain = lane.get('gain', 0.5)
        steps = lane['steps']
        freq, decay = _noise_hit(kind)
        for step_i, on in enumerate(steps):
            if not on:
                continue
            start = (step_i / 16.0) * bar_s
            i0 = int(start * SR)
            count = int(decay * 4 * SR)
            for i in range(count):
                j = i0 + i
                if j >= n:
                    break
                t = i / SR
                if kind == 'kick':
                    hz = freq * (1.0 - min(1.0, t / decay) * 0.6)
                    s = math.sin(2 * math.pi * hz * t) * math.exp(-t / decay)
                else:
                    s = (rng.random() * 2 - 1) * math.exp(-t / decay)
                    if kind == 'snare':
                        s *= 0.8
                out[j] += s * gain
    return out


def _echo(buf: list[float], delay_s: float, feedback: float, mix: float) -> list[float]:
    """SNES-style mono feedback echo, returns wet buffer to sum in."""
    d = int(delay_s * SR)
    wet = [0.0] * len(buf)
    for i in range(d, len(buf)):
        wet[i] = buf[i - d] + wet[i - d] * feedback
    return [w * mix for w in wet]


def _lowpass(buf: list[float], cutoff_hz: float) -> list[float]:
    """One-pole lowpass to soften digital edges."""
    rc = 1.0 / (2 * math.pi * cutoff_hz)
    dt = 1.0 / SR
    alpha = dt / (rc + dt)
    out = [0.0] * len(buf)
    prev = 0.0
    for i, x in enumerate(buf):
        prev = prev + alpha * (x - prev)
        out[i] = prev
    return out


def render_score(score: dict) -> tuple[list[tuple[float, float]], float]:
    """Returns (stereo samples [(L,R)], duration_seconds)."""
    bpm = score['bpm']
    beat_s = 60.0 / bpm
    voices = score.get('voices', [])
    perc = score.get('percussion', [])

    rendered = []
    max_len = 0
    for v in voices:
        buf = _render_voice(v, beat_s)
        echo_mix = v.get('echo', 0.0)
        if echo_mix:
            wet = _echo(buf, beat_s * 0.75, 0.35, echo_mix)
            buf = [a + b for a, b in zip(buf, wet)]
        rendered.append((buf, v.get('pan', 0.0)))
        max_len = max(max_len, len(buf))

    if perc:
        bars = (max_len / SR) / (beat_s * 4.0)
        pbuf = _render_percussion(perc, beat_s, bars)
        max_len = max(max_len, len(pbuf))
        rendered.append((pbuf, 0.0))

    total = max_len + int(beat_s * SR * 2)  # tail for echo ring-out
    left = [0.0] * total
    right = [0.0] * total
    for buf, pan in rendered:
        lg = math.cos((pan + 1) * math.pi / 4)
        rg = math.sin((pan + 1) * math.pi / 4)
        for i, s in enumerate(buf):
            left[i] += s * lg
            right[i] += s * rg

    left = _lowpass(left, 5200.0)
    right = _lowpass(right, 5200.0)

    # Normalize to -3 dBFS peak, hard-guard against clipping.
    peak = max(1e-9, max(max(map(abs, left)), max(map(abs, right))))
    scale = 0.7 / peak
    stereo = [(max(-1.0, min(1.0, left[i] * scale)), max(-1.0, min(1.0, right[i] * scale)))
              for i in range(total)]
    return stereo, total / SR


def write_wav(stereo: list[tuple[float, float]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b''.join(
            struct.pack('<hh', int(l * 32767), int(r * 32767)) for l, r in stereo
        )
        w.writeframes(frames)


def render_module(score_path: Path, mp3_name: str) -> None:
    spec = importlib.util.spec_from_file_location('score', score_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    stereo, dur = render_module_score(mod.SCORE)
    wav_path = OUT_DIR / f'{mp3_name}.wav'
    mp3_path = OUT_DIR / f'{mp3_name}.mp3'
    write_wav(stereo, wav_path)
    subprocess.run(
        ['ffmpeg', '-y', '-i', str(wav_path), '-codec:a', 'libmp3lame', '-b:a', '128k', str(mp3_path)],
        check=True, capture_output=True,
    )
    wav_path.unlink()
    print(f'[music] {mp3_path.name}  {dur:.1f}s  {mp3_path.stat().st_size // 1024} KB')


def render_module_score(score: dict):
    return render_score(score)


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit('usage: render.py <score.py> [out_name]')
    score_path = Path(sys.argv[1])
    out_name = sys.argv[2] if len(sys.argv) > 2 else score_path.stem
    render_module(score_path, out_name)


if __name__ == '__main__':
    main()
