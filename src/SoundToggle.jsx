import { useState } from 'react';
import { isMuted, toggleMute, getSfxVolume, getMusicVolume, setSfxVolume, setMusicVolume } from './soundEngine';

export default function SoundToggle() {
  const [muted, setMuted] = useState(isMuted());
  const [open, setOpen] = useState(false);
  const [sfxVol, setSfxVol] = useState(getSfxVolume());
  const [musicVol, setMusicVol] = useState(getMusicVolume());

  function handleToggle(e) {
    e.stopPropagation();
    const newMuted = toggleMute();
    setMuted(newMuted);
  }

  function handleOpen(e) {
    e.stopPropagation();
    setOpen(!open);
  }

  return (
    <div className="sound-controls" onClick={(e) => e.stopPropagation()}>
      <button className="sound-toggle" onClick={handleToggle} title={muted ? 'Unmute' : 'Mute'}>
        {muted ? '🔇' : '🔊'}
      </button>
      <button className="sound-settings-btn" onClick={handleOpen} title="Sound settings">
        ⚙
      </button>
      {open && (
        <div className="sound-settings-panel">
          <div className="sound-slider-row">
            <label>SFX</label>
            <input
              type="range"
              min="0"
              max="100"
              value={Math.round(sfxVol * 100)}
              onChange={(e) => {
                const val = e.target.value / 100;
                setSfxVol(val);
                setSfxVolume(val);
              }}
            />
            <span>{Math.round(sfxVol * 100)}%</span>
          </div>
          <div className="sound-slider-row">
            <label>Music</label>
            <input
              type="range"
              min="0"
              max="100"
              value={Math.round(musicVol * 100)}
              onChange={(e) => {
                const val = e.target.value / 100;
                setMusicVol(val);
                setMusicVolume(val);
              }}
            />
            <span>{Math.round(musicVol * 100)}%</span>
          </div>
        </div>
      )}
    </div>
  );
}
