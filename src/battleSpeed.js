// Global battle animation speed. One module-level multiplier so the toggle
// (BattleScreen SPEED button) can retime every pacing source at once:
// wait choreography and wall-clock sprite/VFX playback. GSAP timelines scale
// themselves through globalTimeline.timeScale, so receive unscaled durations.
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

// Convert an authored 1× duration exactly once at a wall-clock boundary.
export function scaleBattleDuration(ms) {
  return ms / battleSpeed;
}

// Profile durations and fixed choreography beats are both authored at 1×.
export function battleWait(ms) {
  return new Promise((resolve) => setTimeout(resolve, scaleBattleDuration(ms)));
}
