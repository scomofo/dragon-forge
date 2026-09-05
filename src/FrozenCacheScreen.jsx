import { useEffect, useRef, useState } from 'react';
import NavBar from './NavBar';
import NpcSprite from './NpcSprite';
import { dragons, elementColors, getDragonSprite, npcs } from './gameData';
import { getCampaignNodeById } from './campaignMap';
import { getBossPattern } from './bossPatterns';
import { getStageForLevel, getTypeEffectiveness } from './battleEngine';
import { FROZEN_CACHE_ROOMS } from './worldZones';
import { getFrozenCacheBattleConfig, getFrozenCacheExits, getFrozenCacheObjective, getFrozenCacheProgress, FROZEN_CACHE_VAULT_REWARD, FROZEN_CACHE_CLEAR_REWARD } from './frozenCache';
import { actInFrozenCache, loadSave } from './persistence';
import { playSound } from './soundEngine';
import { assetUrl } from './utils';
import useGamepadController from './useGamepadController';

// The three talking remnants of the Cold Archive — each one foreshadows the
// encounter that froze it. (Boss tells from src/bossPatterns.js.)
const REMNANT_LINES = [
  'Remnant of a runner: "I ran from the warm shadow. It missed me once — and after that my guard was made of nothing."',
  'Remnant of a listener: "A voice below offered me a bench that was already empty. I answered it. Do not."',
  'Remnant of a locksmith: "The crab does not read your key. It reads the last one you used. Bring the same element twice."',
];

// Per-encounter opening advice shown in the party briefing panel.
const OPENING_HINTS = {
  bit_wraith: 'Land your hits. When the wraith phases after a miss, guard will not save you — strike true or weather it.',
  phishing_siren: 'The lure flash lies. Check the actual field before you answer a swap that never happened.',
  crypto_crab: 'Its shell reads ENCRYPTED until you repeat the last element you struck with. Pick one and commit.',
};

export default function FrozenCacheScreen({ save, refreshSave, onNavigate, onBeginCampaignBattle }) {
  const progress = getFrozenCacheProgress(save);
  const room = FROZEN_CACHE_ROOMS[progress.roomId];
  const owned = Object.entries(save.dragons || {}).filter(([id, dragon]) => dragon.owned && dragons[id]);
  const [guardian, setGuardian] = useState(() => progress.guardianId || owned[0]?.[0] || '');
  const [reserve, setReserve] = useState(progress.reserveId || '');
  const [position, setPosition] = useState(28);
  const [activeAction, setActiveAction] = useState(null);
  const [message, setMessage] = useState('');
  // Room transit (walk off / walk in) + the bespoke thaw-junction animation.
  const [transit, setTransit] = useState(null); // { dir, phase: 'out'|'in' }
  const [junctionFx, setJunctionFx] = useState(null); // 'thaw' | 'crack'
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
  const canBattle = Boolean(getFrozenCacheBattleConfig(save, guardian, reserve));
  const exits = getFrozenCacheExits(save);

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
    if (!actInFrozenCache(action, value)) return false;
    playSound(action.startsWith('claim') ? 'shopPurchase' : 'mapNodeReach');
    refreshSave();
    setMessage(feedback);
    return true;
  }

  function travelTo(exit) {
    if (transitRef.current || junctionFx) return;
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

  // Bespoke thaw-junction crossing: the thaw/crack animation plays first,
  // then the choice commits and its message lands.
  function chooseJunction(route, feedback) {
    if (junctionFx || transitRef.current) return;
    if (reducedMotion) { perform('choose-route', route, feedback); return; }
    playSound(route === 'thaw' ? 'shieldDeflectSting' : 'eggCrack');
    setJunctionFx(route);
    later(() => {
      perform('choose-route', route, feedback);
      setJunctionFx(null);
    }, 1500);
  }

  function hearRemnant(index) {
    // Lore is free to re-read; the save only records first contact.
    if (progress.remnantsHeard.includes(index)) {
      playSound('uiConfirm');
      setMessage(REMNANT_LINES[index]);
      return;
    }
    perform('hear-remnant', index, REMNANT_LINES[index]);
  }

  function beginBattle() {
    const config = getFrozenCacheBattleConfig(loadSave(), guardian, reserve);
    if (!config) return;
    actInFrozenCache('party', { guardianId: guardian, reserveId: reserve });
    onBeginCampaignBattle(config);
  }

  const actions = [];
  if (room.id === 'cold-archive') {
    REMNANT_LINES.forEach((line, i) => {
      actions.push({ id: `remnant-${i}`, label: progress.remnantsHeard.includes(i) ? `Remnant ${i + 1} (heard)` : `Listen to remnant ${i + 1}`, x: 30 + i * 16, run: () => hearRemnant(i) });
    });
    if (!owned.length) actions.push({ id: 'hatch', label: 'Hatch a guardian first', x: 64, run: () => onNavigate('hatchery') });
  } else if (room.inspect) {
    actions.push({
      id: 'inspect', label: 'Inspect the room', x: 38,
      run: () => { playSound('uiConfirm'); setMessage(room.inspect); },
    });
  }
  if (room.id === 'thaw-junction' && !progress.junctionRoute) {
    actions.push({ id: 'thaw', label: 'Hold the slow thaw · direct route', x: 56, run: () => chooseJunction('thaw', 'The thaw holds. A clear corridor opens toward the Siren Loop.') });
    actions.push({ id: 'crack', label: 'Crack the deep freeze · frozen vault', x: 74, run: () => chooseJunction('crack', 'The deep freeze splits. Cold air rises from the vault below.') });
  }
  if (room.id === 'frozen-vault' && !progress.vaultClaimed) actions.push({ id: 'vault', label: `Salvage vault · ${FROZEN_CACHE_VAULT_REWARD} scraps`, x: 60, run: () => perform('claim-vault', null, `Recovered ${FROZEN_CACHE_VAULT_REWARD} DataScraps. The vault is bare.`) });
  if (room.id === 'thaw-gate') {
    if (!progress.rewardClaimed) actions.push({ id: 'reward', label: `Collect ${FROZEN_CACHE_CLEAR_REWARD} scraps · one hatch`, x: 60, run: () => perform('claim-clear', null, 'Frozen Cache stabilized. Your next hatch is funded. The Forge is warm.') });
    else actions.push({ id: 'forge', label: 'Return to the Forge', x: 60, run: () => onNavigate('forge') });
  }
  if (npc && !cleared) actions.push({ id: 'battle', label: `Face ${npc.name}`, x: 66, disabled: !canBattle, run: beginBattle });
  for (const exit of exits) {
    if (exit.route && progress.junctionRoute && exit.route !== progress.junctionRoute) continue;
    actions.push({ id: `exit-${exit.to}`, label: exit.label, x: exit.x, disabled: !exit.open, hint: exit.reason, run: () => travelTo(exit) });
  }

  function walk(direction) {
    if (transitRef.current || junctionFx) return;
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
    if (transitRef.current || junctionFx) return;
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
      if (button === 'Y') actions.find(action => action.id.startsWith('remnant-') || action.id === 'inspect')?.run();
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
    <div className="outer-grid-screen frozen-cache-screen">
      <NavBar activeScreen="map" onNavigate={onNavigate} save={save} />
      <main className="outer-grid-layout">
        <header className="outer-grid-header">
          <div><p className="outer-grid-kicker">SECTOR 02 · FROZEN CACHE</p><h1>{room.name}</h1></div>
          <button type="button" onClick={() => onNavigate('map')}>CAMPAIGN MAP</button>
        </header>
        <div className="outer-grid-objective"><span>OBJECTIVE</span><p>{getFrozenCacheObjective(save)}</p></div>
        <div className="outer-grid-body">
          <section className="outer-grid-exploration" aria-label="Room exploration">
            <div
              ref={sceneRef}
              className={`outer-grid-scene frozen-cache-scene${transit ? ` transit-${transit.phase}-${transit.dir}` : ''}`}
              tabIndex={0} role="group"
              aria-label={`${room.name}. Left and right to walk, up and down to choose an action, E or Enter to interact.`}
              onKeyDown={handleSceneKey}
              onClick={event => {
                if (event.target !== event.currentTarget || transitRef.current || junctionFx) return;
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
              {junctionFx && (
                <div className={`frozen-junction-fx frozen-junction-fx-${junctionFx}`} aria-hidden="true">
                  {junctionFx === 'thaw'
                    ? (<><span className="thaw-glow" /><span className="thaw-glow thaw-glow-late" /></>)
                    : (<><span className="crack-line crack-line-a" /><span className="crack-line crack-line-b" /><span className="crack-flash" /></>)}
                </div>
              )}
              <div className="outer-grid-room-caption">{cleared ? room.clearedDescription : room.description}</div>
            </div>
            {[...new Set(actions.filter(action => action.disabled && action.hint).map(action => action.hint))].map(hint => <p key={hint} className="outer-grid-note">{hint}</p>)}
            <div className="outer-grid-actions" aria-label="Room actions">
              {actions.map(action => (
                <button key={action.id} type="button" className={activeAction === action.id ? 'is-selected' : ''}
                  disabled={action.disabled || Boolean(transit) || Boolean(junctionFx)} title={action.disabled ? action.hint : undefined}
                  onFocus={() => { setActiveAction(action.id); setPosition(action.x); }}
                  onClick={action.run}>
                  {action.label}
                </button>
              ))}
            </div>
            {room.id === 'thaw-junction' && !progress.junctionRoute && <p className="outer-grid-note">Choose one crossing for this expedition. The slow thaw is direct; the deep freeze hides a vault of supplies.</p>}
            {room.id === 'frozen-vault' && progress.vaultClaimed && <p className="outer-grid-note">Vault salvaged.</p>}
            <p className="outer-grid-message" role="status" aria-live="polite">{message || 'Your room is saved as you explore.'}</p>
            <p className="outer-grid-controls">← → / A D walk · ↑ ↓ / W S choose · E / Enter interact · Tap any action<br />Gamepad: D-pad explore · A interact · LB/RB guardian · X reserve · Y inspect · B map</p>
          </section>
          <aside className="outer-grid-party" aria-label="Guardian and encounter briefing">
            <h2>YOUR GUARDIAN</h2>
            {owned.length ? <>
              <label htmlFor="fc-guardian">Primary</label>
              <select id="fc-guardian" value={guardian} onChange={event => { setGuardian(event.target.value); if (reserve === event.target.value) setReserve(''); }}>
                {owned.map(([id, data]) => <option key={id} value={id}>{data.nickname || dragons[id].name} · Lv.{data.level}</option>)}
              </select>
              {hasGuardian && <img className="outer-grid-guardian" src={getDragonSprite(guardian, getStageForLevel(save.dragons[guardian].level))} alt={dragons[guardian].name} />}
              <label htmlFor="fc-reserve">Reserve</label>
              <select id="fc-reserve" value={reserve} onChange={event => setReserve(event.target.value)}>
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
            <div className="outer-grid-route-summary"><h2>EXPEDITION</h2><p>{progress.visited.length} rooms visited</p><p>{progress.remnantsHeard.length} of 3 remnants heard</p><p>{progress.rewardClaimed ? 'Return reward collected' : `Return reward: ${FROZEN_CACHE_CLEAR_REWARD} scraps`}</p><p>{progress.junctionRoute === 'thaw' ? 'Slow thaw held' : progress.junctionRoute === 'crack' ? 'Deep freeze cracked' : 'Crossing not yet chosen'}</p></div>
          </aside>
        </div>
      </main>
    </div>
  );
}
