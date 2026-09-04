import { useId, useState, useSyncExternalStore } from 'react';
import { getSoundPreferences, subscribeSoundPreferences, toggleMute, setSfxVolume, setMusicVolume } from './soundEngine';

export default function SoundToggle() {
  const { muted, sfxVolume: sfxVol, musicVolume: musicVol } = useSyncExternalStore(
    subscribeSoundPreferences, getSoundPreferences, getSoundPreferences,
  );
  const id = useId();
  const [open, setOpen] = useState(false);

  function handleToggle(e) {
    e.stopPropagation();
    toggleMute();
  }

  function handleOpen(e) {
    e.stopPropagation();
    setOpen(!open);
  }

  return (
    <div className="sound-controls" onClick={(e) => e.stopPropagation()} onKeyDown={(e) => e.stopPropagation()}>
      <button className="sound-toggle" onClick={handleToggle} title={muted ? 'Unmute' : 'Mute'} aria-label={muted ? 'Unmute audio' : 'Mute audio'} aria-pressed={muted}>
        {muted ? '🔇' : '🔊'}
      </button>
      <button className="sound-settings-btn" onClick={handleOpen} title="Sound settings" aria-label="Sound settings" aria-expanded={open} aria-controls={`${id}-panel`}>
        ⚙
      </button>
      {open && (
        <div className="sound-settings-panel" id={`${id}-panel`}>
          <div className="sound-slider-row">
            <label htmlFor={`${id}-sfx`}>SFX</label>
            <input
              id={`${id}-sfx`}
              type="range"
              min="0"
              max="100"
              value={Math.round(sfxVol * 100)}
              onChange={(e) => {
                const val = e.target.value / 100;
                setSfxVolume(val);
              }}
            />
            <span>{Math.round(sfxVol * 100)}%</span>
          </div>
          <div className="sound-slider-row">
            <label htmlFor={`${id}-music`}>Music</label>
            <input
              id={`${id}-music`}
              type="range"
              min="0"
              max="100"
              value={Math.round(musicVol * 100)}
              onChange={(e) => {
                const val = e.target.value / 100;
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
