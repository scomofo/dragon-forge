// @ts-nocheck
import { FELIX_STAGE_PROSE, OPENING_FELIX_LINES } from './loreCanon';

function toQuotedLines(prose) {
  const words = String(prose || '').split(/\s+/).filter(Boolean);
  const wrapped = [];
  let current = '';
  for (const word of words) {
    const next = current ? `${current} ${word}` : word;
    if (next.length > 42 && current) {
      wrapped.push(current);
      current = word;
    } else {
      current = next;
    }
  }
  if (current) wrapped.push(current);
  if (wrapped.length === 0) return ['""'];
  if (wrapped.length === 1) return [`"${wrapped[0]}"`];
  return [`"${wrapped[0]}`, ...wrapped.slice(1, -1).map((line) => ` ${line}`), ` ${wrapped[wrapped.length - 1]}"`];
}

const TERMINAL_DIALOGUE = {
  0: OPENING_FELIX_LINES,
  1: toQuotedLines(FELIX_STAGE_PROSE[1]),
  2: toQuotedLines(FELIX_STAGE_PROSE[2]),
  3: toQuotedLines(FELIX_STAGE_PROSE[3]),
  4: toQuotedLines(FELIX_STAGE_PROSE[4]),
  5: toQuotedLines(FELIX_STAGE_PROSE[5]),
};

const TICKER_MESSAGES = {
  0: 'SYSTEM STATUS: NOMINAL',
  1: 'ANOMALY DETECTED \u2014 SECTOR 7',
  2: 'WARNING: ELEMENTAL FLUX RISING',
  3: 'ALERT: MATRIX INTEGRITY 62%',
  4: 'CRITICAL: MATRIX INTEGRITY 23%',
  5: '[BREACH DETECTED] \u2014 ALL SECTORS COMPROMISED',
};

export function getTerminalDialogue(stage) {
  return TERMINAL_DIALOGUE[stage] || TERMINAL_DIALOGUE[0];
}

export function getTickerMessage(stage) {
  return TICKER_MESSAGES[stage] || TICKER_MESSAGES[0];
}
