import { useEffect, useRef, useState } from 'react';
import { getPressedGamepadInputs, snapshotGamepadButtons } from './gamepadInput';

export default function useGamepadController(handlers = {}, enabled = true) {
  const handlersRef = useRef(handlers);
  const previousButtonsRef = useRef({});
  const previousAxesRef = useRef({ x: 0, y: 0 });
  const frameRef = useRef(null);
  const [connectedGamepad, setConnectedGamepad] = useState(null);

  useEffect(() => {
    handlersRef.current = handlers;
  }, [handlers]);

  useEffect(() => {
    if (!enabled || typeof window === 'undefined' || typeof navigator === 'undefined') return undefined;

    function getPrimaryGamepad() {
      return Array.from(navigator.getGamepads?.() || []).find(Boolean) || null;
    }

    function poll() {
      const gamepad = getPrimaryGamepad();
      setConnectedGamepad((current) => {
        if (current?.index === gamepad?.index && current?.id === gamepad?.id) return current;
        return gamepad ? { id: gamepad.id, index: gamepad.index } : null;
      });

      if (gamepad) {
        const input = getPressedGamepadInputs(gamepad, previousButtonsRef.current, previousAxesRef.current);
        input.buttons.forEach((button) => {
          if (button === 'DPAD_UP') handlersRef.current.onDirectionPress?.('UP', gamepad);
          else if (button === 'DPAD_DOWN') handlersRef.current.onDirectionPress?.('DOWN', gamepad);
          else if (button === 'DPAD_LEFT') handlersRef.current.onDirectionPress?.('LEFT', gamepad);
          else if (button === 'DPAD_RIGHT') handlersRef.current.onDirectionPress?.('RIGHT', gamepad);
          else handlersRef.current.onButtonPress?.(button, gamepad);
        });
        input.axisPresses.forEach((direction) => handlersRef.current.onDirectionPress?.(direction, gamepad));
        previousButtonsRef.current = snapshotGamepadButtons(gamepad);
        previousAxesRef.current = input.axes;
      } else {
        previousButtonsRef.current = {};
        previousAxesRef.current = { x: 0, y: 0 };
      }

      frameRef.current = window.requestAnimationFrame(poll);
    }

    frameRef.current = window.requestAnimationFrame(poll);
    return () => {
      if (frameRef.current) window.cancelAnimationFrame(frameRef.current);
    };
  }, [enabled]);

  return connectedGamepad;
}
