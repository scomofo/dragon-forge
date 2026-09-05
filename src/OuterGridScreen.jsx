import { useEffect, useRef, useState } from 'react';
import NavBar from './NavBar';
import NpcSprite from './NpcSprite';
import { dragons, elementColors, getDragonSprite, npcs } from './gameData';
import { getCampaignNodeById } from './campaignMap';
import { getBossPattern } from './bossPatterns';
import { getStageForLevel, getTypeEffectiveness } from './battleEngine';
import { OUTER_GRID_ROOMS } from './worldZones';
import { getOuterGridBattleConfig, getOuterGridExits, getOuterGridObjective, getOuterGridProgress, OUTER_GRID_CACHE_REWARD, OUTER_GRID_CLEAR_REWARD } from './outerGrid';
import { actInOuterGrid, loadSave } from './persistence';
import { playSound } from './soundEngine';
import { assetUrl } from './utils';
import useGamepadController from './useGamepadController';

export default function OuterGridScreen({ save, refreshSave, onNavigate, onBeginCampaignBattle }) {
  const progress = getOuterGridProgress(save);
  const room = OUTER_GRID_ROOMS[progress.roomId];
  const owned = Object.entries(save.dragons || {}).filter(([id, dragon]) => dragon.owned && dragons[id]);
  const [guardian, setGuardian] = useState(() => progress.guardianId || owned[0]?.[0] || '');
  const [reserve, setReserve] = useState(progress.reserveId || '');
  const [position, setPosition] = useState(28);
  const [activeAction, setActiveAction] = useState(null);
  const [message, setMessage] = useState('');
  const sceneRef = useRef(null);
  const node = getCampaignNodeById(room.nodeId);
  const npc = node ? npcs[node.npcId] : null;
  const cleared = npc && (save.defeatedNpcs || []).includes(npc.id);
  const pattern = npc ? getBossPattern(npc.id) : null;
  const hasGuardian = owned.some(([id]) => id === guardian);
  const canBattle = Boolean(getOuterGridBattleConfig(save, guardian, reserve));
  const exits = getOuterGridExits(save);

  useEffect(() => {
    setPosition(28);
    setActiveAction(null);
    setMessage('');
    sceneRef.current?.focus({ preventScroll: true });
  }, [room.id]);

  function perform(action, value, feedback = '') {
    if (!actInOuterGrid(action, value)) return false;
    playSound(action.startsWith('claim') ? 'shopPurchase' : 'mapNodeReach');
    refreshSave();
    setMessage(feedback);
    return true;
  }

  function beginBattle() {
    const config = getOuterGridBattleConfig(loadSave(), guardian, reserve);
    if (!config) return;
    actInOuterGrid('party', { guardianId: guardian, reserveId: reserve });
    onBeginCampaignBattle(config);
  }

  const actions = [];
  if (room.inspect) actions.push({
    id: 'inspect', label: room.id === 'field-locker' ? 'Read Felix’s note' : 'Inspect the room', x: 38,
    run: () => {
      if (room.id === 'field-locker') perform('read-note');
      playSound('uiConfirm');
      setMessage(room.inspect);
    },
  });
  if (room.id === 'field-locker' && !owned.length) actions.push({ id: 'hatch', label: 'Hatch your first guardian', x: 64, run: () => onNavigate('hatchery') });
  if (room.id === 'firewall-span' && !progress.spanRoute) {
    actions.push({ id: 'brace', label: 'Brace the span · direct route', x: 56, run: () => perform('choose-route', 'span', 'The upper brace holds. The direct crossing is open.') });
    actions.push({ id: 'crawlway', label: 'Open the crawlway · supply cache', x: 74, run: () => perform('choose-route', 'crawlway', 'You pry open the lower hatch. The maintenance cache lies below.') });
  }
  if (room.id === 'maintenance-cache' && !progress.cacheClaimed) actions.push({ id: 'cache', label: `Salvage cache · ${OUTER_GRID_CACHE_REWARD} scraps`, x: 60, run: () => perform('claim-cache', null, `Recovered ${OUTER_GRID_CACHE_REWARD} DataScraps. This cache is now empty.`) });
  if (room.id === 'return-gate') {
    if (!progress.rewardClaimed) actions.push({ id: 'reward', label: `Collect ${OUTER_GRID_CLEAR_REWARD} scraps · one hatch`, x: 60, run: () => perform('claim-clear', null, 'Outer Grid stabilized. Your next hatch is funded. Felix is waiting in the Forge.') });
    else actions.push({ id: 'forge', label: 'Return to the Forge', x: 60, run: () => onNavigate('forge') });
  }
  if (npc && !cleared) actions.push({ id: 'battle', label: `Face ${npc.name}`, x: 66, disabled: !canBattle, run: beginBattle });
  for (const exit of exits) {
    // Once the span choice is made, show the selected crossing only.
    if (exit.route && progress.spanRoute && exit.route !== progress.spanRoute) continue;
    actions.push({ id: `exit-${exit.to}`, label: exit.label, x: exit.x, disabled: !exit.open, hint: exit.reason, run: () => perform('move', exit.to) });
  }

  function walk(direction) {
    const next = Math.max(10, Math.min(90, position + direction * 6));
    setPosition(next);
    const nearest = actions.filter(action => !action.disabled).reduce((best, action) =>
      !best || Math.abs(action.x - next) < Math.abs(best.x - next) ? action : best, null);
    setActiveAction(nearest?.id || null);
  }

  function cycleAction(direction) {
    const available = actions.filter(action => !action.disabled);
    if (!available.length) return;
    const index = available.findIndex(action => action.id === activeAction);
    const action = available[(index + direction + available.length) % available.length];
    setActiveAction(action.id);
    setPosition(action.x);
  }

  function activate() {
    const action = actions.find(item => item.id === activeAction && !item.disabled);
    if (action) action.run();
    else cycleAction(1);
  }

  function cycleGuardian(direction) {
    if (!owned.length) return;
    const index = Math.max(0, owned.findIndex(([id]) => id === guardian));
    const id = owned[(index + direction + owned.length) % owned.length][0];
    setGuardian(id);
    if (reserve === id) setReserve('');
  }

  function cycleReserve() {
    const choices = ['', ...owned.filter(([id]) => id !== guardian).map(([id]) => id)];
    setReserve(choices[(Math.max(0, choices.indexOf(reserve)) + 1) % choices.length]);
  }

  useGamepadController({
    onDirectionPress: direction => {
      if (direction === 'LEFT') walk(-1);
      if (direction === 'RIGHT') walk(1);
      if (direction === 'UP') cycleAction(-1);
      if (direction === 'DOWN') cycleAction(1);
    },
    onButtonPress: button => {
      if (button === 'A' || button === 'START') activate();
      if (button === 'LB') cycleGuardian(-1);
      if (button === 'RB') cycleGuardian(1);
      if (button === 'X') cycleReserve();
      if (button === 'Y') actions.find(action => action.id === 'inspect')?.run();
      if (button === 'B') onNavigate('map');
    },
  });

  function handleSceneKey(event) {
    if (event.target !== event.currentTarget || event.altKey || event.ctrlKey || event.metaKey) return;
    const key = event.key.toLowerCase();
    if (!['arrowleft', 'arrowright', 'arrowup', 'arrowdown', 'a', 'd', 'w', 's', 'e', 'enter', ' ', 'escape'].includes(key)) return;
    event.preventDefault();
    if (['arrowleft', 'a'].includes(key)) walk(-1);
    else if (['arrowright', 'd'].includes(key)) walk(1);
    else if (['arrowup', 'w'].includes(key)) cycleAction(-1);
    else if (['arrowdown', 's'].includes(key)) cycleAction(1);
    else if (key === 'escape') onNavigate('map');
    else if (!event.repeat) activate();
  }

  return (
    <div className="outer-grid-screen">
      <NavBar activeScreen="map" onNavigate={onNavigate} save={save} />
      <main className="outer-grid-layout">
        <header className="outer-grid-header">
          <div><p className="outer-grid-kicker">SECTOR 01 · OUTER GRID</p><h1>{room.name}</h1></div>
          <button type="button" onClick={() => onNavigate('map')}>CAMPAIGN MAP</button>
        </header>
        <div className="outer-grid-objective"><span>OBJECTIVE</span><p>{getOuterGridObjective(save)}</p></div>
        <div className="outer-grid-body">
          <section className="outer-grid-exploration" aria-label="Room exploration">
            <div
              ref={sceneRef} className="outer-grid-scene" tabIndex={0} role="group"
              aria-label={`${room.name}. Left and right to walk, up and down to choose an action, E or Enter to interact.`}
              onKeyDown={handleSceneKey}
              onClick={event => {
                if (event.target !== event.currentTarget) return;
                sceneRef.current.focus({ preventScroll: true });
                const bounds = event.currentTarget.getBoundingClientRect();
                setPosition(Math.max(10, Math.min(90, (event.clientX - bounds.left) / bounds.width * 100)));
                setActiveAction(null);
              }}
              style={{ '--room-background': `url(${assetUrl(room.background)})` }}
            >
              <span className="outer-grid-room-kind">{cleared ? 'STABILIZED' : room.kind}</span>
              {npc && !cleared && <div className="outer-grid-enemy" aria-label={npc.name}><NpcSprite actorId={npc.id} idleSprite={npc.idleSprite} size={160} /></div>}
              <img className="outer-grid-skye" src={assetUrl('/assets/characters/skye.png')} alt="Skye" draggable={false} style={{ left: `${position}%` }} />
              <div className="outer-grid-room-caption">{cleared ? room.clearedDescription : room.description}</div>
            </div>
            {[...new Set(actions.filter(action => action.disabled && action.hint).map(action => action.hint))].map(hint => <p key={hint} className="outer-grid-note">{hint}</p>)}
            <div className="outer-grid-actions" aria-label="Room actions">
              {actions.map(action => (
                <button key={action.id} type="button" className={activeAction === action.id ? 'is-selected' : ''}
                  disabled={action.disabled} title={action.disabled ? action.hint : undefined}
                  onFocus={() => { setActiveAction(action.id); setPosition(action.x); }}
                  onClick={action.run}>
                  {action.label}
                </button>
              ))}
            </div>
            {room.id === 'firewall-span' && !progress.spanRoute && <p className="outer-grid-note">Choose one crossing for this expedition. The direct route saves a room; the crawlway contains extra supplies.</p>}
            {room.id === 'maintenance-cache' && progress.cacheClaimed && <p className="outer-grid-note">Supply cache recovered.</p>}
            <p className="outer-grid-message" role="status" aria-live="polite">{message || 'Your room is saved as you explore.'}</p>
            <p className="outer-grid-controls">← → / A D walk · ↑ ↓ / W S choose · E / Enter interact · Tap any action<br />Gamepad: D-pad explore · A interact · LB/RB guardian · X reserve · Y inspect · B map</p>
          </section>
          <aside className="outer-grid-party" aria-label="Guardian and encounter briefing">
            <h2>YOUR GUARDIAN</h2>
            {owned.length ? <>
              <label htmlFor="outer-guardian">Primary</label>
              <select id="outer-guardian" value={guardian} onChange={event => { setGuardian(event.target.value); if (reserve === event.target.value) setReserve(''); }}>
                {owned.map(([id, data]) => <option key={id} value={id}>{data.nickname || dragons[id].name} · Lv.{data.level}</option>)}
              </select>
              {hasGuardian && <img className="outer-grid-guardian" src={getDragonSprite(guardian, getStageForLevel(save.dragons[guardian].level))} alt={dragons[guardian].name} />}
              <label htmlFor="outer-reserve">Reserve</label>
              <select id="outer-reserve" value={reserve} onChange={event => setReserve(event.target.value)}>
                <option value="">No reserve</option>
                {owned.filter(([id]) => id !== guardian).map(([id, data]) => <option key={id} value={id}>{data.nickname || dragons[id].name} · Lv.{data.level}</option>)}
              </select>
            </> : <button type="button" onClick={() => onNavigate('hatchery')}>HATCH A GUARDIAN</button>}
            {npc && !cleared && <div className="outer-grid-briefing">
              <h2>{npc.name}</h2>
              <p style={{ color: elementColors[npc.element]?.glow }}>{npc.element.toUpperCase()} · Lv.{npc.level}</p>
              {hasGuardian && <p>Element matchup: {getTypeEffectiveness(dragons[guardian].element, npc.element) > 1 ? 'Advantage' : getTypeEffectiveness(dragons[guardian].element, npc.element) < 1 ? 'Resisted — use guard and timing' : 'Even'}</p>}
              <h3>WATCH FOR</h3><p>{pattern?.tell}</p>
              <h3>YOUR OPENING</h3><p>{npc.id === 'firewall_sentinel' ? 'Defend before your next strike to get past the packet shield. Read BLOCKED before spending your strongest move.' : 'Watch the heat counter. At four stacks, the vent forces an attack and burns itself. Guard when the heat peaks.'}</p>
              {!canBattle && <p>Select an owned guardian to begin.</p>}
            </div>}
            <div className="outer-grid-route-summary"><h2>EXPEDITION</h2><p>{progress.visited.length} rooms visited</p><p>{progress.rewardClaimed ? 'Return reward collected' : `Return reward: ${OUTER_GRID_CLEAR_REWARD} scraps`}</p><p>{progress.spanRoute === 'span' ? 'Upper crossing braced' : progress.spanRoute === 'crawlway' ? 'Lower crawlway open' : 'Crossing not yet chosen'}</p></div>
          </aside>
        </div>
      </main>
    </div>
  );
}
