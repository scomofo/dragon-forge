// Global battle animation speed. One module-level multiplier so the toggle
// (BattleScreen SPEED button) can retime every pacing source at once:
// the wait() choreography, the presentation timing tables, and all GSAP
// timelines (via gsap.globalTimeline.timeScale).
import gsap from 'gsap';

let battleSpeed = 1;

export function getBattleSpeed() {
  return battleSpeed;
}

export function setBattleSpeed(speed) {
  battleSpeed = speed === 2 ? 2 : 1;
  gsap.globalTimeline.timeScale(battleSpeed);
  return battleSpeed;
}

// Scaled wait — every fixed beat in the battle choreography goes through this
// so 2x actually halves a turn's wall-clock time.
export function battleWait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms / battleSpeed));
}
