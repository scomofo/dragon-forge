import { useEffect, useRef, useState } from 'react';
import NavBar from './NavBar';
import NpcSprite from './NpcSprite';
import { dragons, elementColors, getDragonSprite, npcs } from './gameData';
import { getCampaignNodeById } from './campaignMap';
import { getBossPattern } from './bossPatterns';
import { getStageForLevel, getTypeEffectiveness } from './battleEngine';
import { ADMIN_CORE_ROOMS } from './worldZones';
import { getAdminCoreBattleConfig, getAdminCoreExits, getAdminCoreObjective, getAdminCoreProgress, ADMIN_CORE_CACHE_REWARD, ADMIN_CORE_CLEAR_REWARD } from './adminCore';
import { actInAdminCore, loadSave } from './persistence';
import { playSound } from './soundEngine';
import { assetUrl } from './utils';
import useGamepadController from './useGamepadController';

// Per-encounter opening advice shown in the party briefing panel.
const OPENING_HINTS = {
  recursive_golem: 'It hardens in loops — DEF stacks show as nested brackets. Pierce the loop or out-tempo the stacks before they bury you.',
  protocol_vulture: 'At half HP it perches and the next action is Soul Drain. Bank a guard or your hardest strike for the perch turn.',
};

const LANTERN_LABELS = {
  hoarding: 'Hoarding lantern — the reliquary glows warm',
  memory: 'Memory lantern — the echo archive is lit',
  passage: 'Passage lantern — the open walk, and nothing else',
};

export default function AdminCoreScreen({ save, refreshSave, onNavigate, onBeginCampaignBattle }) {
  const progress = getAdminCoreProgress(save);
  const room = ADMIN_CORE_ROOMS[progress.roomId];
  const owned = Object.entries(save.dragons || {}).filter(([id, dragon]) => dragon.owned && dragons[id]);
  const [guardian, setGuardian] = useState(() => progress.guardianId || owned[0]?.[0] || '');
  const [reserve, setReserve] = useState(progress.reserveId || '');
  const [position, setPosition] = useState(28);
  const [activeAction, setActiveAction] = useState(null);
  const [message, setMessage] = useState('');
  // Room transit (walk off / walk in) + the bespoke fork arc-shut animation.
  const [transit, setTransit] = useState(null); // { dir, phase: 'out'|'in' }
  const [lanternFx, setLanternFx] = useState(null); // 'hoarding' | 'memory' | 'passage'
  const [faceDir, setFaceDir] = useState(1);
  const transitRef = useRef(null);
  const timersRef = useRef([]);
  const sceneRef = useRef(null);
  const reducedMotion = typeof window !== 'undefined'
    && window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  const node = getCampaignNodeById(room.nodeId);
  const npc = node ? npcs[node.npcId] : null;
  const cleared = npc && (save.defeatedNpcs || []).includes(npc.id);
  const pattern = npc ? getBossPattern(npc.id) : null;
  const hasGuardian = owned.some(([id]) => id === guardian);
  const canBattle = Boolean(getAdminCoreBattleConfig(save, guardian, reserve));
  const exits = getAdminCoreExits(save);

  function later(fn, ms) {
    const id = setTimeout(fn, ms);
    timersRef.current.push(id);
    return id;
  }

  useEffect(() => () => timersRef.current.forEach(clearTimeout), []);

  useEffect(() => {
    setActiveAction(null);
    setMessage('');
    sceneRef.current?.focus({ preventScroll: true });
    if (transitRef.current?.phase === 'in') {
      setPosition(transitRef.current.dir === 'right' ? 8 : 92);
      later(() => setPosition(28), 90);
      later(() => { transitRef.current = null; setTransit(null); }, 560);
    } else {
      setPosition(28);
    }
  }, [room.id]);

  function perform(action, value, feedback = '') {
    if (!actInAdminCore(action, value)) return false;
    playSound(action.startsWith('claim') ? 'shopPurchase' : 'mapNodeReach');
    refreshSave();
    setMessage(feedback);
    return true;
  }

  function travelTo(exit) {
    if (transitRef.current || lanternFx) return;
    if (reducedMotion) { perform('move', exit.to); return; }
    const dir = exit.x >= 50 ? 'right' : 'left';
    setFaceDir(dir === 'right' ? 1 : -1);
    transitRef.current = { dir, phase: 'out' };
    setTransit(transitRef.current);
    setActiveAction(null);
    later(() => {
      transitRef.current = { dir, phase: 'in' };
      setTransit(transitRef.current);
      perform('move', exit.to);
    }, 460);
  }

  // Bespoke lantern choice: the lit lantern flares warm while the other two
  // burn out cold, then the choice commits and its message lands.
  function chooseLantern(lantern, feedback) {
    if (lanternFx || transitRef.current) return;
    if (reducedMotion) { perform('choose-lantern', lantern, feedback); return; }
    playSound('shieldDeflectSting');
    setLanternFx(lantern);
    later(() => {
      perform('choose-lantern', lantern, feedback);
      setLanternFx(null);
    }, 1600);
  }

  function beginBattle() {
    const config = getAdminCoreBattleConfig(loadSave(), guardian, reserve);
    if (!config) return;
    actInAdminCore('party', { guardianId: guardian, reserveId: reserve });
    onBeginCampaignBattle(config);
  }

  const actions = [];
  if (room.inspect) {
    actions.push({
      id: 'inspect', label: room.id === 'echo-archive' ? 'Read draft zero' : room.id === 'mirror-vestibule' ? 'Read Felix’s line' : 'Inspect the room', x: 38,
      run: () => {
        if (room.id === 'echo-archive') perform('read-archive');
        playSound('uiConfirm');
        setMessage(room.inspect);
      },
    });
  }
  if (room.id === 'mirror-vestibule' && !owned.length) actions.push({ id: 'hatch', label: 'Hatch a guardian first', x: 64, run: () => onNavigate('hatchery') });
  if (room.id === 'cold-lanterns' && !progress.lantern) {
    actions.push({ id: 'lantern-hoarding', label: `Light the hoarding lantern · ${ADMIN_CORE_CACHE_REWARD} scraps`, x: 52, run: () => chooseLantern('hoarding', 'The hoarding lantern flares. The other two burn out cold.') });
    actions.push({ id: 'lantern-memory', label: 'Light the memory lantern · origin draft', x: 66, run: () => chooseLantern('memory', 'The memory lantern flares. The other two burn out cold.') });
    actions.push({ id: 'lantern-passage', label: 'Light the passage lantern · the open walk', x: 80, run: () => chooseLantern('passage', 'The passage lantern flares. The other two burn out cold.') });
  }
  if (room.id === 'reliquary-vault' && !progress.cacheClaimed) actions.push({ id: 'cache', label: `Open the reliquary · ${ADMIN_CORE_CACHE_REWARD} scraps`, x: 60, run: () => perform('claim-cache', null, `Claimed ${ADMIN_CORE_CACHE_REWARD} DataScraps of unspent saves. The vault stands empty.`) });
  if (room.id === 'reset-threshold') {
    if (!progress.rewardClaimed) actions.push({ id: 'reward', label: `Collect ${ADMIN_CORE_CLEAR_REWARD} scraps · one hatch`, x: 60, run: () => perform('claim-clear', null, 'Admin Core stabilized. Your next hatch is funded. Past the threshold, the Singularity notices you.') });
    else actions.push({ id: 'forge', label: 'Return to the Forge', x: 60, run: () => onNavigate('forge') });
  }
  if (npc && !cleared) actions.push({ id: 'battle', label: `Face ${npc.name}`, x: 66, disabled: !canBattle, run: beginBattle });
  for (const exit of exits) {
    if (exit.route && progress.lantern && exit.route !== progress.lantern) continue;
    actions.push({ id: `exit-${exit.to}`, label: exit.label, x: exit.x, disabled: !exit.open, hint: exit.reason, run: () => travelTo(exit) });
  }

  function walk(direction) {
    if (transitRef.current || lanternFx) return;
    setFaceDir(direction > 0 ? 1 : -1);
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
    if (transitRef.current || lanternFx) return;
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
    <div className="outer-grid-screen admin-core-screen">
      <NavBar activeScreen="map" onNavigate={onNavigate} save={save} />
      <main className="outer-grid-layout">
        <header className="outer-grid-header">
          <div><p className="outer-grid-kicker">SECTOR 04 · ADMIN CORE</p><h1>{room.name}</h1></div>
          <button type="button" onClick={() => onNavigate('map')}>CAMPAIGN MAP</button>
        </header>
        <div className="outer-grid-objective"><span>OBJECTIVE</span><p>{getAdminCoreObjective(save)}</p></div>
        <div className="outer-grid-body">
          <section className="outer-grid-exploration" aria-label="Room exploration">
            <div
              ref={sceneRef}
              className={`outer-grid-scene admin-core-scene${transit ? ` transit-${transit.phase}-${transit.dir}` : ''}`}
              tabIndex={0} role="group"
              aria-label={`${room.name}. Left and right to walk, up and down to choose an action, E or Enter to interact.`}
              onKeyDown={handleSceneKey}
              onClick={event => {
                if (event.target !== event.currentTarget || transitRef.current || lanternFx) return;
                sceneRef.current.focus({ preventScroll: true });
                const bounds = event.currentTarget.getBoundingClientRect();
                const next = Math.max(10, Math.min(90, (event.clientX - bounds.left) / bounds.width * 100));
                setFaceDir(next >= position ? 1 : -1);
                setPosition(next);
                setActiveAction(null);
              }}
              style={{ '--room-background': `url(${assetUrl(room.background)})` }}
            >
              <span className="outer-grid-room-kind">{cleared ? 'STABILIZED' : room.kind}</span>
              {npc && !cleared && <div className="outer-grid-enemy" aria-label={npc.name}><NpcSprite actorId={npc.id} idleSprite={npc.idleSprite} size={160} /></div>}
              <img
                className={`outer-grid-skye${transit ? ` transit-${transit.phase}` : ''}`}
                src={assetUrl('/assets/characters/skye.png')} alt="Skye" draggable={false}
                style={{
                  left: `${transit?.phase === 'out' ? (transit.dir === 'right' ? 106 : -6) : position}%`,
                  transform: `translateX(-50%) scaleX(${faceDir})`,
                }}
              />
              {lanternFx && (
                <div className="admin-lantern-fx" aria-hidden="true">
                  {['hoarding', 'memory', 'passage'].map(lantern => (
                    <span key={lantern} className={`lantern lantern-${lantern}${lantern === lanternFx ? ' is-lit' : ' is-out'}`} />
                  ))}
                </div>
              )}
              <div className="outer-grid-room-caption">{cleared ? room.clearedDescription : room.description}</div>
            </div>
            {[...new Set(actions.filter(action => action.disabled && action.hint).map(action => action.hint))].map(hint => <p key={hint} className="outer-grid-note">{hint}</p>)}
            <div className="outer-grid-actions" aria-label="Room actions">
              {actions.map(action => (
                <button key={action.id} type="button" className={activeAction === action.id ? 'is-selected' : ''}
                  disabled={action.disabled || Boolean(transit) || Boolean(lanternFx)} title={action.disabled ? action.hint : undefined}
                  onFocus={() => { setActiveAction(action.id); setPosition(action.x); }}
                  onClick={action.run}>
                  {action.label}
                </button>
              ))}
            </div>
            {room.id === 'cold-lanterns' && !progress.lantern && <p className="outer-grid-note">Light one lantern for this expedition. The other two burn out — what they guarded stays cold.</p>}
            {room.id === 'reliquary-vault' && progress.cacheClaimed && <p className="outer-grid-note">The reliquary stands empty.</p>}
            <p className="outer-grid-message" role="status" aria-live="polite">{message || 'Your room is saved as you explore.'}</p>
            <p className="outer-grid-controls">← → / A D walk · ↑ ↓ / W S choose · E / Enter interact · Tap any action<br />Gamepad: D-pad explore · A interact · LB/RB guardian · X reserve · Y inspect · B map</p>
          </section>
          <aside className="outer-grid-party" aria-label="Guardian and encounter briefing">
            <h2>YOUR GUARDIAN</h2>
            {owned.length ? <>
              <label htmlFor="ac-guardian">Primary</label>
              <select id="ac-guardian" value={guardian} onChange={event => { setGuardian(event.target.value); if (reserve === event.target.value) setReserve(''); }}>
                {owned.map(([id, data]) => <option key={id} value={id}>{data.nickname || dragons[id].name} · Lv.{data.level}</option>)}
              </select>
              {hasGuardian && <img className="outer-grid-guardian" src={getDragonSprite(guardian, getStageForLevel(save.dragons[guardian].level))} alt={dragons[guardian].name} />}
              <label htmlFor="ac-reserve">Reserve</label>
              <select id="ac-reserve" value={reserve} onChange={event => setReserve(event.target.value)}>
                <option value="">No reserve</option>
                {owned.filter(([id]) => id !== guardian).map(([id, data]) => <option key={id} value={id}>{data.nickname || dragons[id].name} · Lv.{data.level}</option>)}
              </select>
            </> : <button type="button" onClick={() => onNavigate('hatchery')}>HATCH A GUARDIAN</button>}
            {npc && !cleared && <div className="outer-grid-briefing">
              <h2>{npc.name}</h2>
              <p style={{ color: elementColors[npc.element]?.glow }}>{npc.element.toUpperCase()} · Lv.{npc.level}</p>
              {hasGuardian && <p>Element matchup: {getTypeEffectiveness(dragons[guardian].element, npc.element) > 1 ? 'Advantage' : getTypeEffectiveness(dragons[guardian].element, npc.element) < 1 ? 'Resisted — use guard and timing' : 'Even'}</p>}
              <h3>WATCH FOR</h3><p>{pattern?.tell}</p>
              <h3>YOUR OPENING</h3><p>{OPENING_HINTS[npc.id]}</p>
              {!canBattle && <p>Select an owned guardian to begin.</p>}
            </div>}
            <div className="outer-grid-route-summary"><h2>EXPEDITION</h2><p>{progress.visited.length} rooms visited</p><p>{progress.rewardClaimed ? 'Return reward collected' : `Return reward: ${ADMIN_CORE_CLEAR_REWARD} scraps`}</p><p>{progress.lantern ? LANTERN_LABELS[progress.lantern] : 'Lantern not yet lit'}</p></div>
          </aside>
        </div>
      </main>
    </div>
  );
}
