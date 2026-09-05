import { useEffect, useRef, useState } from 'react';
import { getPressedGamepadInputs, snapshotGamepadButtons } from './gamepadInput';

export default function useGamepadController(handlers = {}, enabled = true) {
  const handlersRef = useRef(handlers);
  const [connectedGamepad, setConnectedGamepad] = useState(null);

  useEffect(() => {
    handlersRef.current = handlers;
  }, [handlers]);

  useEffect(() => {
    if (!enabled || typeof window === 'undefined' || typeof navigator === 'undefined') return undefined;
    let previousButtons = {};
    let previousAxes = { x: 0, y: 0 };
    let previousGamepad = null;
    let frame;
    let stopped = false;

    function getPrimaryGamepad() {
      return Array.from(navigator.getGamepads?.() || []).find(Boolean) || null;
    }

    function poll() {
      if (stopped) return;
      const gamepad = getPrimaryGamepad();
      setConnectedGamepad((current) => {
        if (current?.index === gamepad?.index && current?.id === gamepad?.id) return current;
        return gamepad ? { id: gamepad.id, index: gamepad.index } : null;
      });

      if (gamepad) {
        const input = getPressedGamepadInputs(gamepad, previousButtons, previousAxes);
        const sameController = previousGamepad && previousGamepad.index === gamepad.index && previousGamepad.id === gamepad.id;
        // A screen/overlay handoff, re-enable or reconnection may arrive while
        // Confirm is still held. First observe that state; only a new press
        // may activate this screen's actions (including paid hatch buttons).
        if (sameController) {
          input.buttons.forEach((button) => {
            if (stopped) return;
            if (button === 'DPAD_UP') handlersRef.current.onDirectionPress?.('UP', gamepad);
            else if (button === 'DPAD_DOWN') handlersRef.current.onDirectionPress?.('DOWN', gamepad);
            else if (button === 'DPAD_LEFT') handlersRef.current.onDirectionPress?.('LEFT', gamepad);
            else if (button === 'DPAD_RIGHT') handlersRef.current.onDirectionPress?.('RIGHT', gamepad);
            else handlersRef.current.onButtonPress?.(button, gamepad);
          });
          input.axisPresses.forEach((direction) => {
            if (!stopped) handlersRef.current.onDirectionPress?.(direction, gamepad);
          });
        }
        previousButtons = snapshotGamepadButtons(gamepad);
        previousAxes = input.axes;
        previousGamepad = { id: gamepad.id, index: gamepad.index };
      } else {
        previousButtons = {};
        previousAxes = { x: 0, y: 0 };
        previousGamepad = null;
      }

      if (!stopped) frame = window.requestAnimationFrame(poll);
    }

    frame = window.requestAnimationFrame(poll);
    return () => {
      stopped = true;
      window.cancelAnimationFrame(frame);
    };
  }, [enabled]);

  return connectedGamepad;
}
