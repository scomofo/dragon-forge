import { useState } from 'react';
import { isMuted, toggleMute } from './soundEngine';

export default function SoundToggle() {
  const [muted, setMuted] = useState(isMuted());

  function handleToggle(e) {
    e.stopPropagation();
    const newMuted = toggleMute();
    setMuted(newMuted);
  }

  return (
    <button className="sound-toggle" onClick={handleToggle} title={muted ? 'Unmute' : 'Mute'}>
      {muted ? '🔇' : '🔊'}
    </button>
  );
}
