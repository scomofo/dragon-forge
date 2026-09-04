import { vi } from 'vitest';

export function createAudioContext() {
  const nodes = [];
  function parameter() {
    return { value: 0, setValueAtTime: vi.fn(), linearRampToValueAtTime: vi.fn(), exponentialRampToValueAtTime: vi.fn() };
  }
  function node(kind) {
    const value = {
      kind, gain: parameter(), frequency: parameter(), detune: parameter(), Q: parameter(),
      connect: vi.fn(), disconnect: vi.fn(), start: vi.fn(), stop: vi.fn(),
    };
    nodes.push(value);
    return value;
  }
  return {
    nodes, currentTime: 0, destination: {}, state: 'running', resume: vi.fn().mockResolvedValue(),
    createGain: () => node('gain'),
    createBiquadFilter: () => node('filter'),
    createOscillator: () => node('oscillator'),
  };
}
