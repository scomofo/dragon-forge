import { OPENING_FELIX_LINES } from './loreCanon';

const TERMINAL_DIALOGUE = {
  0: OPENING_FELIX_LINES,
  1: [
    '"Interesting... I\'m picking up anomalous',
    ' readings in the Matrix.',
    ' Probably nothing. Keep forging."',
  ],
  2: [
    '"The anomalies are getting stronger.',
    ' Something is feeding on the elemental',
    ' energy. We need more dragons, fast."',
  ],
  3: [
    '"All six elements are online, but the',
    ' Matrix is destabilizing. I\'m detecting',
    ' a pattern in the noise — it\'s not',
    ' random. It\'s intelligent."',
  ],
  4: [
    '"An Elder dragon... magnificent.',
    ' But its power is attracting something.',
    ' The readings are off the charts.',
    ' Brace yourself."',
  ],
  5: [
    '"It\'s here. The Singularity has breached',
    ' the Matrix. Everything I\'ve built,',
    ' everything we\'ve forged — it all',
    ' comes down to this."',
  ],
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
