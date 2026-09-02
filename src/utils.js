export function stageToRoman(stage) {
  return { 1: 'I', 2: 'II', 3: 'III', 4: 'IV' }[stage] || 'I';
}

export function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Resolve asset paths with Vite's base URL for production deployment
const BASE = import.meta.env.BASE_URL || '/';
export function assetUrl(path) {
  let resolved = path;
  if (!resolved.startsWith(BASE)) {
    resolved = BASE + resolved.replace(/^\//, '');
  }
  return resolved.replace(/\.png$/i, '.webp');
}
