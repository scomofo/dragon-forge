import { useCallback, useEffect, useState } from 'react';
import ForgeScene from './forge/ForgeScene';
import {
  AnvilOverlay,
  ConsoleOverlay,
  FelixOverlay,
  HatcheryRingOverlay,
  LanternOverlay,
} from './forge/ForgeOverlays';
import {
  getGamepadMovementDirection,
  getMovementDirection,
  isForgeCancelKey,
  isForgeInteractKey,
  moveSkye,
} from './forge/forgeMovement';
import {
  FORGE_PALETTE,
  FRAGMENT_TRIGGERS,
  STATION_IDS,
  findNearestStation,
  getBulkheadView,
  pickFelixLine,
} from './forgeData';
import {
  grantRelic,
  setFlag,
  unlockFragment,
} from './persistence';
import { playSound } from './soundEngine';
import useGamepadController from './useGamepadController';

function bootstrapForgeSave(save) {
  let mutated = false;

  if (!save?.flags?.metFelix) {
    setFlag('metFelix', true);
    mutated = true;
  }

  for (const [id, predicate] of Object.entries(FRAGMENT_TRIGGERS)) {
    if (save?.flags?.fragmentsUnlocked?.includes(id)) continue;
    try {
      if (predicate(save) || ['001', '002'].includes(id)) {
        unlockFragment(id);
        mutated = true;
      }
    } catch {
      // Fragment predicates are intentionally best-effort against old saves.
    }
  }

  if ((save?.skye?.relicsOwned?.length || 0) === 0) {
    grantRelic('iron_knuckle');
    mutated = true;
  }

  return mutated;
}

export default function ForgeScreen({ onNavigate, save, refreshSave }) {
  const [skyePos, setSkyePos] = useState({ x: 30, y: 75 });
  const [activeStation, setActiveStation] = useState(null);
  const [overlay, setOverlay] = useState(null);
  const [felixLine, setFelixLine] = useState(null);

  const act = save?.flags?.currentAct || 1;
  const view = getBulkheadView(act);
  const nearest = findNearestStation(skyePos);

  useEffect(() => {
    if (bootstrapForgeSave(save)) refreshSave?.();
    // Run once per Forge mount so first-visit migrations stay explicit.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const closeOverlay = useCallback(() => {
    setOverlay(null);
    setFelixLine(null);
    playSound('navSwitch');
  }, []);

  const interact = useCallback(() => {
    if (!nearest) return;
    playSound('buttonClick');
    setActiveStation(nearest.id);

    if (nearest.id === STATION_IDS.FELIX) {
      setFelixLine(pickFelixLine(save));
      setOverlay('felix');
    } else if (nearest.id === STATION_IDS.BULKHEAD) {
      playSound('screenTransition');
      onNavigate?.('map');
    } else if (nearest.id === STATION_IDS.SAVE_LANTERN) {
      setOverlay('lantern');
    } else if (nearest.id === STATION_IDS.ANVIL) {
      setOverlay('anvil');
    } else if (nearest.id === STATION_IDS.CONSOLE) {
      setOverlay('console');
    } else if (nearest.id === STATION_IDS.HATCHERY_RING) {
      setOverlay('hatcheryRing');
    }
  }, [nearest, onNavigate, save]);

  const move = useCallback((direction) => {
    if (overlay) return;
    setSkyePos((pos) => moveSkye(pos, direction));
  }, [overlay]);

  useEffect(() => {
    function onKeyDown(event) {
      if (overlay) {
        if (isForgeCancelKey(event.key)) {
          event.preventDefault();
          closeOverlay();
        }
        return;
      }

      const direction = getMovementDirection(event.key);
      if (direction) {
        event.preventDefault();
        move(direction);
        return;
      }

      if (isForgeInteractKey(event.key)) {
        event.preventDefault();
        interact();
      }
    }

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [closeOverlay, interact, move, overlay]);

  useGamepadController({
    onDirectionPress(direction) {
      const mapped = getGamepadMovementDirection(direction);
      if (mapped) move(mapped);
    },
    onButtonPress(button) {
      if (overlay && (button === 'B' || button === 'SELECT')) closeOverlay();
      else if (!overlay && (button === 'A' || button === 'X' || button === 'START')) interact();
    },
  });

  return (
    <div
      className="forge-screen"
      style={{
        '--forge-wall': FORGE_PALETTE.wallShadow,
        '--forge-floor': FORGE_PALETTE.floor,
        '--forge-floor-accent': FORGE_PALETTE.floorAccent,
      }}
      data-active-station={activeStation || ''}
    >
      <ForgeScene skyePos={skyePos} nearest={nearest} view={view} />

      {overlay === 'anvil' && <AnvilOverlay save={save} onClose={closeOverlay} refreshSave={refreshSave} />}
      {overlay === 'console' && <ConsoleOverlay save={save} onClose={closeOverlay} onNavigate={onNavigate} />}
      {overlay === 'hatcheryRing' && (
        <HatcheryRingOverlay save={save} onClose={closeOverlay} onNavigate={onNavigate} refreshSave={refreshSave} />
      )}
      {overlay === 'lantern' && <LanternOverlay save={save} onClose={closeOverlay} refreshSave={refreshSave} />}
      {overlay === 'felix' && <FelixOverlay line={felixLine} onClose={closeOverlay} />}
    </div>
  );
}
