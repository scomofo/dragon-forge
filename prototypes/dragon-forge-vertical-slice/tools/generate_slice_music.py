#!/usr/bin/env python3
"""Generate original NES-style music cues for the Dragon Forge vertical slice."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIO_DIR = ROOT / "assets" / "audio"
SAMPLE_RATE = 44_100

NOTE_OFFSETS = {
    "C": -9,
    "C#": -8,
    "D": -7,
    "D#": -6,
    "E": -5,
    "F": -4,
    "F#": -3,
    "G": -2,
    "G#": -1,
    "A": 0,
    "A#": 1,
    "B": 2,
}


def note_frequency(name: str) -> float:
    pitch = name[:-1]
    octave = int(name[-1])
    semitones = NOTE_OFFSETS[pitch] + (octave - 4) * 12
    return 440.0 * (2.0 ** (semitones / 12.0))


def new_buffer(seconds: float) -> list[float]:
    return [0.0 for _ in range(int(seconds * SAMPLE_RATE))]


def envelope(position: float, total: float, attack: float = 0.006, release: float = 0.028) -> float:
    if position < attack:
        return position / attack
    remaining = total - position
    if remaining < release:
        return max(0.0, remaining / release)
    return 1.0


def add_square(
    buffer: list[float],
    start: float,
    length: float,
    note: str,
    amp: float,
    duty: float = 0.50,
    octave_shift: int = 0,
) -> None:
    freq = note_frequency(_shift_octave(note, octave_shift))
    start_i = max(0, int(start * SAMPLE_RATE))
    end_i = min(len(buffer), int((start + length) * SAMPLE_RATE))
    for i in range(start_i, end_i):
        t = (i - start_i) / SAMPLE_RATE
        phase = (t * freq) % 1.0
        sample = 1.0 if phase < duty else -1.0
        buffer[i] += sample * amp * envelope(t, length)


def add_triangle(buffer: list[float], start: float, length: float, note: str, amp: float) -> None:
    freq = note_frequency(note)
    start_i = max(0, int(start * SAMPLE_RATE))
    end_i = min(len(buffer), int((start + length) * SAMPLE_RATE))
    for i in range(start_i, end_i):
        t = (i - start_i) / SAMPLE_RATE
        phase = (t * freq) % 1.0
        sample = 4.0 * abs(phase - 0.5) - 1.0
        buffer[i] += sample * amp * envelope(t, length, 0.004, 0.020)


def add_noise(buffer: list[float], start: float, length: float, amp: float, seed: int) -> None:
    rng = random.Random(seed)
    start_i = max(0, int(start * SAMPLE_RATE))
    end_i = min(len(buffer), int((start + length) * SAMPLE_RATE))
    last = 0.0
    for i in range(start_i, end_i):
        t = (i - start_i) / SAMPLE_RATE
        if i % 11 == 0:
            last = rng.uniform(-1.0, 1.0)
        buffer[i] += last * amp * envelope(t, length, 0.001, 0.045)


def add_kick(buffer: list[float], start: float, amp: float = 0.40) -> None:
    length = 0.10
    start_i = max(0, int(start * SAMPLE_RATE))
    end_i = min(len(buffer), int((start + length) * SAMPLE_RATE))
    for i in range(start_i, end_i):
        t = (i - start_i) / SAMPLE_RATE
        freq = 110.0 - 58.0 * min(1.0, t / length)
        sample = math.sin(t * freq * math.tau)
        buffer[i] += sample * amp * envelope(t, length, 0.001, 0.080)


def _shift_octave(note: str, shift: int) -> str:
    if shift == 0:
        return note
    return f"{note[:-1]}{int(note[-1]) + shift}"


def add_pattern(buffer: list[float], notes: list[str], beat: float, step: float, amp: float, duty: float) -> None:
    for index, note in enumerate(notes):
        if note == "-":
            continue
        add_square(buffer, beat + index * step, step * 0.86, note, amp, duty)


def add_bass(buffer: list[float], notes: list[str], beat: float, step: float, amp: float = 0.24) -> None:
    for index, note in enumerate(notes):
        if note == "-":
            continue
        add_triangle(buffer, beat + index * step, step * 0.94, note, amp)


def add_drums(buffer: list[float], total_steps: int, step: float, snare_seed: int) -> None:
    for index in range(total_steps):
        start = index * step
        if index % 8 == 0:
            add_kick(buffer, start, 0.34)
        if index % 8 == 4:
            add_noise(buffer, start, step * 1.2, 0.18, snare_seed + index)
        if index % 2 == 1:
            add_noise(buffer, start, step * 0.45, 0.07, snare_seed * 3 + index)


def normalize(buffer: list[float], ceiling: float = 0.88) -> None:
    peak = max(0.01, max(abs(sample) for sample in buffer))
    gain = ceiling / peak
    for i, sample in enumerate(buffer):
        buffer[i] = max(-1.0, min(1.0, sample * gain))
    fade = int(SAMPLE_RATE * 0.012)
    for i in range(fade):
        scale = i / float(fade)
        buffer[i] *= scale
        buffer[-i - 1] *= scale


def write_wav(path: Path, buffer: list[float]) -> None:
    normalize(buffer)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        frames = b"".join(struct.pack("<h", int(sample * 32767.0)) for sample in buffer)
        handle.writeframes(frames)


def forge_ready_room() -> list[float]:
    bpm = 150
    step = 60.0 / bpm / 2.0
    buffer = new_buffer(step * 64)
    lead = [
        "E4", "G4", "B4", "G4", "C5", "B4", "G4", "E4",
        "A4", "C5", "E5", "C5", "D5", "C5", "A4", "G4",
    ] * 4
    counter = [
        "B3", "-", "D4", "-", "E4", "-", "D4", "-",
        "C4", "-", "E4", "-", "F4", "-", "E4", "-",
    ] * 4
    bass = ["E2", "E2", "B2", "B2", "C3", "C3", "B2", "B2"] * 8
    add_pattern(buffer, lead, 0.0, step, 0.15, 0.36)
    add_pattern(buffer, counter, step * 0.5, step, 0.08, 0.25)
    add_bass(buffer, bass, 0.0, step, 0.20)
    add_drums(buffer, 64, step, 17)
    return buffer


def map_node_select() -> list[float]:
    bpm = 168
    step = 60.0 / bpm / 2.0
    buffer = new_buffer(step * 48)
    lead = [
        "C5", "E5", "G5", "E5", "A4", "C5", "G4", "E5",
        "D5", "F5", "A5", "F5", "B4", "D5", "A4", "F5",
    ] * 3
    pulse = ["C3", "-", "G2", "-", "A2", "-", "G2", "-"] * 6
    add_pattern(buffer, lead, 0.0, step, 0.16, 0.30)
    add_bass(buffer, pulse, 0.0, step, 0.22)
    add_drums(buffer, 48, step, 41)
    return buffer


def battle_data_bout() -> list[float]:
    bpm = 184
    step = 60.0 / bpm / 2.0
    buffer = new_buffer(step * 128)
    lead = [
        "D5", "-", "F5", "G#5", "F5", "-", "E5", "C#5",
        "D5", "-", "F5", "A5", "G#5", "F5", "E5", "-",
        "D5", "F5", "-", "G#5", "A5", "-", "G#5", "F5",
        "E5", "-", "F5", "C#5", "D5", "-", "C5", "A4",
    ] * 4
    alarm = [
        "-", "A5", "-", "G#5", "-", "A5", "-", "C6",
        "-", "A5", "-", "G#5", "-", "A#5", "-", "G#5",
    ] * 8
    counter = [
        "D4", "C#4", "D4", "-", "F4", "E4", "F4", "-",
        "G#4", "F4", "E4", "-", "D4", "C#4", "C4", "-",
    ] * 8
    bass = ["D2", "D2", "D2", "F2", "G#2", "G#2", "F2", "C#2"] * 16
    add_pattern(buffer, lead, 0.0, step, 0.13, 0.18)
    add_pattern(buffer, alarm, 0.0, step, 0.08, 0.12)
    add_pattern(buffer, counter, step * 0.5, step, 0.07, 0.42)
    add_bass(buffer, bass, 0.0, step, 0.30)
    add_drums(buffer, 128, step, 73)
    for index in range(0, 128, 16):
        add_noise(buffer, index * step + step * 12, step * 3.0, 0.11, 311 + index)
    for index in range(4, 128, 8):
        add_kick(buffer, index * step, 0.20)
    return buffer


def victory_scrap_jingle() -> list[float]:
    bpm = 152
    step = 60.0 / bpm / 2.0
    buffer = new_buffer(step * 24)
    lead = [
        "G4", "B4", "D5", "G5", "E5", "C5", "D5", "G5",
        "B5", "G5", "E5", "C5", "D5", "-", "G5", "-",
    ]
    harmony = [
        "D4", "-", "G4", "-", "C5", "-", "B4", "-",
        "G4", "-", "C5", "-", "B4", "-", "D5", "-",
    ]
    bass = ["G2", "G2", "D3", "D3", "C3", "C3", "D3", "D3"] * 3
    add_pattern(buffer, lead, 0.0, step, 0.18, 0.28)
    add_pattern(buffer, harmony, 0.0, step, 0.09, 0.50)
    add_bass(buffer, bass, 0.0, step, 0.18)
    add_kick(buffer, 0.0, 0.28)
    add_noise(buffer, step * 8, step * 2.5, 0.16, 109)
    return buffer


def main() -> None:
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    tracks = {
        "music_forge_ready_room.wav": forge_ready_room(),
        "music_map_node_select.wav": map_node_select(),
        "music_battle_data_bout.wav": battle_data_bout(),
        "music_victory_scrap_jingle.wav": victory_scrap_jingle(),
    }
    for name, buffer in tracks.items():
        write_wav(AUDIO_DIR / name, buffer)
        print(f"wrote {AUDIO_DIR / name}")


if __name__ == "__main__":
    main()
