export function stageToRoman(stage) {
  return { 1: 'I', 2: 'II', 3: 'III', 4: 'IV' }[stage] || 'I';
}

export function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Resolve asset paths with Vite's base URL for production deployment
const BASE = import.meta.env.BASE_URL || '/';
export function assetUrl(path) {
  // If path already starts with the base, return as-is
  if (path.startsWith(BASE)) return path;
  // Strip leading slash and prepend base
  return BASE + path.replace(/^\//, '');
}
