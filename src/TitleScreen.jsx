import { useState, useEffect, useRef, useCallback } from 'react';
import { wait } from './utils';
import { playSound, playMusic } from './soundEngine';
import SoundToggle from './SoundToggle';
import { getSingularityStage } from './singularityProgress';
import { getTerminalDialogue } from './felixDialogue';

const BOOT_LINES = [
  { text: '> DRAGON FORGE SYSTEMS v2.7.1', status: null, delay: 600 },
  { text: '> INITIALIZING KERNEL...', status: 'OK', delay: 800 },
  { text: '> LOADING ELEMENTAL MATRIX...', status: 'OK', delay: 1000 },
  { text: '> CALIBRATING QUANTUM RESONANCE...', status: 'OK', delay: 900 },
  { text: '> SCANNING FOR DRAGON SIGNATURES...', status: 'WARNING', delay: 1200 },
  { text: '> STABILITY INDEX: 23% — CRITICAL', status: 'FAIL', delay: 800 },
];

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
    playMusic('title');
    const currentDialogue = getTerminalDialogue(getSingularityStage(save));

    for (const line of BOOT_LINES) {
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
      await wait(line.delay);
      scrollToBottom();
    }

    if (skippedRef.current) {
      setLines(BOOT_LINES.map((l) => ({ text: l.text, status: l.status })));
      setTypingText('');
    }

    setPhase('glitch');
    setGlitching(true);
    playSound('terminalGlitch');
    await wait(300);
    setGlitching(false);

    setPhase('felix');
    setLines((prev) => [
      ...prev,
      { text: '> ==========================================', status: null },
      { text: '> EMERGENCY BROADCAST — DR. FELIX', status: null },
      { text: '> ==========================================', status: null },
    ]);
    scrollToBottom();
    await wait(400);

    setFelixVisible(true);
    scrollToBottom();

    skippedRef.current = false;
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
    runBootSequence();
  }, [runBootSequence]);

  const handleClick = () => {
    if (phase === 'boot') {
      skippedRef.current = true;
    } else if (phase === 'felix') {
      skippedRef.current = true;
    }
  };

  const handleStart = () => {
    playSound('buttonClick');
    onStart();
  };

  return (
    <div className={`terminal-screen ${glitching ? 'terminal-glitch' : ''}`} onClick={handleClick}>
      <div className="terminal-sound-toggle">
        <SoundToggle />
      </div>

      <div className="terminal-output" ref={containerRef}>
        {lines.map((line, i) => (
          <div key={i} className="terminal-line">
            <span className="terminal-text">{line.text}</span>
            {line.status && (
              <span className={`terminal-status ${line.status.toLowerCase()}`}>[{line.status}]</span>
            )}
          </div>
        ))}

        {typingText && (
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
                src="/assets/felix_pixel.jpg"
                alt="Professor Felix"
                className="pixelated"
                style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
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
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 20 }}>
            <button className="terminal-init-btn" onClick={handleStart}>
              INITIALIZE_SIMULATION.EXE
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
