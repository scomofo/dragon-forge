import { useEffect, useRef, useState, useSyncExternalStore } from 'react';
import {
  getCurrentTrack, getSoundPreferences, playMusic, stopMusic, subscribeSoundPreferences,
} from './soundEngine';
import { MUSIC_SCORES } from './musicScores';

const TRACKS = [
  { id: 'heartforge', label: 'Heartforge', description: 'The question, the fracture, and the promise.' },
  { id: 'mirrorAdmin', label: 'The Caretaker', description: 'The same memory, slower and heavier.' },
];

export default function SoundRoom() {
  const [selected, setSelected] = useState('heartforge');
  const [audition, setAudition] = useState(null);
  const activeRef = useRef(null);
  const returnTrackRef = useRef(null);
  const { muted, musicVolume } = useSyncExternalStore(
    subscribeSoundPreferences, getSoundPreferences, getSoundPreferences,
  );

  useEffect(() => () => {
    // App sets the destination's music before this screen unmounts. Never
    // stop that new track as part of cleaning up an old audition.
    if (activeRef.current && getCurrentTrack() === activeRef.current) stopMusic();
  }, []);

  function play() {
    if (!activeRef.current) returnTrackRef.current = getCurrentTrack();
    playMusic(selected, true);
    activeRef.current = selected;
    setAudition(selected);
  }

  function stop() {
    if (getCurrentTrack() === activeRef.current) {
      if (returnTrackRef.current) playMusic(returnTrackRef.current, true);
      else stopMusic();
    }
    activeRef.current = null;
    setAudition(null);
  }

  const selectedTrack = TRACKS.find(track => track.id === selected);
  const activeTrack = TRACKS.find(track => track.id === audition);
  const status = muted ? 'Audio is muted. Unmute to listen.'
    : musicVolume === 0 ? 'Music volume is at zero.'
      : activeTrack ? `Playing: ${activeTrack.label}` : 'Choose a theme to listen.';

  return (
    <section className="settings-section sound-room" aria-labelledby="sound-room-title">
      <h3 className="settings-section-title" id="sound-room-title">SOUND ROOM</h3>
      <label className="sound-room-label" htmlFor="sound-room-track">Theme</label>
      <select id="sound-room-track" value={selected} onChange={event => setSelected(event.target.value)}>
        {TRACKS.map(track => <option key={track.id} value={track.id}>{track.label}</option>)}
      </select>
      <p className="sound-room-description">{selectedTrack.description}</p>
      <p className="sound-room-tempo">{MUSIC_SCORES[selected].bpm} BPM · 16 bars</p>
      <div className="sound-room-actions">
        <button type="button" className="settings-btn" onClick={play} disabled={muted || musicVolume === 0}>
          PLAY THEME
        </button>
        <button type="button" className="settings-btn" onClick={stop} disabled={!audition}>
          STOP
        </button>
      </div>
      <p className="sound-room-status" role="status">{status}</p>
    </section>
  );
}
