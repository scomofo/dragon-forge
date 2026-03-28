export function stageToRoman(stage) {
  return { 1: 'I', 2: 'II', 3: 'III', 4: 'IV' }[stage] || 'I';
}

export function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
