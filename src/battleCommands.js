// Keep the visible command order and keyboard/controller choices in agreement.
// IDs survive a dual tech disappearing or a reserve changing the move list.
export function getBattleCommands({
  moves = [], signatureUsed = false, hasBench = false, benchHp = 0,
  isResolving = false, autoBattleAllowed = true,
} = {}) {
  return [
    ...moves.map(move => ({
      id: move.key,
      disabled: Boolean(isResolving || (move.isSignature && signatureUsed)),
    })),
    { id: 'defend', disabled: Boolean(isResolving) },
    ...(hasBench ? [{ id: 'swap', disabled: Boolean(isResolving || benchHp <= 0) }] : []),
    { id: 'speed', disabled: false },
    { id: 'auto', disabled: !autoBattleAllowed },
  ];
}

export function cycleBattleCommand(commands, currentId, direction) {
  if (!commands.length) return null;
  const step = direction < 0 ? -1 : 1;
  const index = commands.findIndex(command => command.id === currentId);
  // A removed command has no successor in this list; start at the nearest end.
  const start = index >= 0 ? index : (step > 0 ? -1 : 0);
  for (let distance = 1; distance <= commands.length; distance++) {
    const command = commands[(start + distance * step + commands.length) % commands.length];
    if (!command.disabled) return command.id;
  }
  return null;
}

/**
 * Return intent without cancelling browser behavior. The caller checks the
 * current command's disabled state before executing and calls preventDefault
 * only for handled intents. Native Enter/Space activation belongs to the actual
 * focused control, including save-retry/download buttons above the battle.
 */
export function getBattleKeyboardCommand(event) {
  if (event.defaultPrevented || event.repeat || event.altKey || event.ctrlKey || event.metaKey || event.isComposing) return null;
  const target = event.target;
  if (target?.isContentEditable || target?.closest?.('input, select, textarea, [contenteditable], [role="textbox"]')) return null;

  const interactive = target?.closest?.('button, a, [role="button"], [role="link"], summary');
  if (interactive && (event.key === 'Enter' || event.key === ' ')) return null;
  if (interactive && !interactive.closest?.('[data-battle-command]')) return null;

  if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') return { type: 'cycle', direction: -1 };
  if (event.key === 'ArrowRight' || event.key === 'ArrowDown') return { type: 'cycle', direction: 1 };
  if (event.key === 'Enter' || event.key === ' ') return { type: 'activate' };
  const id = { d: 'defend', s: 'speed', a: 'auto' }[event.key?.toLowerCase()];
  return id ? { type: 'activate', id } : null;
}
