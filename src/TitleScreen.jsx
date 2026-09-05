import { useState, useEffect, useRef, useCallback } from 'react';
import { wait } from './utils';
import { playSound, playMusic } from './soundEngine';
import SoundToggle from './SoundToggle';
import { getSingularityStage } from './singularityProgress';
import { getTerminalDialogue } from './felixDialogue';
import { OPENING_BOOT_LINES } from './loreCanon';
import { markIntroSeen } from './persistence';
import useGamepadController from './useGamepadController';

export default function TitleScreen({ onStart, save }) {
  const [lines, setLines] = useState([]);
  const [typingText, setTypingText] = useState('');
  const [showCursor, setShowCursor] = useState(true);
  const [phase, setPhase] = useState('boot');
  const [felixVisible, setFelixVisible] = useState(false);
  const [felixLines, setFelixLines] = useState([]);
  const [showButton, setShowButton] = useState(false);
  const [glitching, setGlitching] = useState(false);
  const skippedRef = useRef(false);
  const containerRef = useRef(null);
  const hasBootedRef = useRef(false);
  const startedRef = useRef(false);

  const scrollToBottom = () => {
    if (containerRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight;
    }
  };

  const typeText = useCallback(async (text, charDelay = 50) => {
    for (let i = 0; i <= text.length; i++) {
      if (skippedRef.current) return text;
      setTypingText(text.slice(0, i));
      if (i < text.length) playSound('terminalType');
      await wait(charDelay);
      scrollToBottom();
    }
    return text;
  }, []);

  const runBootSequence = useCallback(async () => {
    const currentDialogue = getTerminalDialogue(getSingularityStage(save));

    for (const line of OPENING_BOOT_LINES) {
      if (skippedRef.current) break;
      await typeText(line.text);
      setTypingText('');

      let statusEl = null;
      if (line.status) {
        await wait(200);
        if (line.status === 'OK') playSound('terminalOk');
        else if (line.status === 'WARNING') playSound('terminalWarning');
        else if (line.status === 'FAIL') playSound('terminalFail');
        statusEl = line.status;
      }

      setLines((prev) => [...prev, { text: line.text, status: statusEl }]);
      if (!skippedRef.current) await wait(line.delay);
      scrollToBottom();
    }

    if (skippedRef.current) {
      setLines(OPENING_BOOT_LINES.map((l) => ({ text: l.text, status: l.status })));
      setTypingText('');
      return;
    }

    setPhase('glitch');
    setGlitching(true);
    playSound('terminalGlitch');
    await wait(300);
    if (skippedRef.current) return;
    setGlitching(false);

    setPhase('felix');
    setLines((prev) => [
      ...prev,
      { text: '> ==========================================', status: null },
      { text: '> EMERGENCY BROADCAST -- PROF. FELIX', status: null },
      { text: '> ==========================================', status: null },
    ]);
    scrollToBottom();
    await wait(400);

    setFelixVisible(true);
    scrollToBottom();

    if (skippedRef.current) {
      setFelixLines([...currentDialogue]);
      setTypingText('');
      setPhase('ready');
      setShowButton(true);
      setShowCursor(false);
      scrollToBottom();
      return;
    }

    for (const line of currentDialogue) {
      if (skippedRef.current) break;
      if (line === '') {
        setFelixLines((prev) => [...prev, '']);
        await wait(300);
        continue;
      }
      await typeText(line, 40);
      setTypingText('');
      setFelixLines((prev) => [...prev, line]);
      scrollToBottom();
    }

    if (skippedRef.current) {
      setFelixLines([...currentDialogue]);
      setTypingText('');
    }

    setPhase('ready');
    setShowButton(true);
    setShowCursor(false);
    scrollToBottom();
  }, [typeText, save]);

  useEffect(() => {
    if (hasBootedRef.current) return;
    hasBootedRef.current = true;
    // Returning players have already seen the boot wall — render it instantly, skip the ~10s typing.
    if (save?.introSeen) {
      skippedRef.current = true;
      setLines(OPENING_BOOT_LINES.map((l) => ({ text: l.text, status: l.status })));
      setFelixLines([...getTerminalDialogue(getSingularityStage(save))]);
      setFelixVisible(true);
      setPhase('ready');
      setShowButton(true);
      setShowCursor(false);
      return;
    }
    runBootSequence();
  }, [runBootSequence, save]);

  const handleClick = () => {
    // Retry music on first user interaction (autoplay policy requires click)
    playMusic('opening');
    if (phase === 'ready') return;
    skippedRef.current = true;
    setLines(OPENING_BOOT_LINES.map((l) => ({ text: l.text, status: l.status })));
    setFelixLines([...getTerminalDialogue(getSingularityStage(save))]);
    setFelixVisible(true);
    setTypingText('');
    setPhase('ready');
    setShowButton(true);
    setShowCursor(false);
    setGlitching(false);
  };

  const handleStart = (event) => {
    event?.stopPropagation();
    if (startedRef.current) return;
    startedRef.current = true;
    playSound('buttonClick');
    markIntroSeen();
    onStart();
  };

  const gamepad = useGamepadController({
    onButtonPress(button) {
      if (button !== 'A' && button !== 'START') return;
      if (phase === 'ready') handleStart();
      else handleClick();
    },
  });

  return (
    <div
      className={`terminal-screen ${glitching ? 'terminal-glitch' : ''}`}
      onClick={handleClick}
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.target !== e.currentTarget || !['Enter', ' '].includes(e.key)) return;
        e.preventDefault();
        if (phase === 'ready') handleStart();
        else handleClick();
      }}
    >
      <div className="terminal-sound-toggle">
        <SoundToggle />
      </div>
      {phase !== 'ready' && (
        <div style={{ position: 'absolute', bottom: 16, left: '50%', transform: 'translateX(-50%)', fontSize: 12, color: '#bbb', pointerEvents: 'none', userSelect: 'none', letterSpacing: '0.05em', width: 'calc(100% - 32px)', textAlign: 'center' }}>
          {gamepad ? 'A / START · skip introduction' : '▸ click or press Enter to skip'}
        </div>
      )}

      <div className="terminal-output" ref={containerRef}>
        {lines.map((line, i) => (
          <div key={i} className="terminal-line">
            <span className="terminal-text">{line.text}</span>
            {line.status && (
              <span className={`terminal-status ${line.status.toLowerCase()}`}>[{line.status}]</span>
            )}
          </div>
        ))}

        {typingText && !felixVisible && (
          <div className="terminal-line">
            <span className="terminal-text">
              {typingText}
              {showCursor && <span className="terminal-cursor" />}
            </span>
          </div>
        )}

        {felixVisible && (
          <div className="terminal-felix-section">
            <div className="terminal-felix-portrait">
              <img
                src={`${import.meta.env.BASE_URL}assets/felix_pixel.jpg`}
                alt="Professor Felix"
                className="pixelated"
              />
            </div>
            <div className="terminal-dialogue">
              {felixLines.map((line, i) => (
                <div key={i}>{line || '\u00A0'}</div>
              ))}
              {phase === 'felix' && typingText && (
                <div>
                  {typingText}
                  {showCursor && <span className="terminal-cursor" />}
                </div>
              )}
            </div>
          </div>
        )}

        {showButton && (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, marginTop: 20 }}>
            <button className="terminal-init-btn" onClick={handleStart}
              style={gamepad ? { outline: '3px solid #ffcc00', outlineOffset: 4 } : undefined}>
              INITIALIZE_SIMULATION.EXE
            </button>
            {gamepad && <span style={{ color: '#ddd', fontSize: 12 }}>A / START · begin</span>}
          </div>
        )}
      </div>
    </div>
  );
}
