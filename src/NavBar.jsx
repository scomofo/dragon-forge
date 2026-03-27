import { loadSave } from './persistence';

export default function NavBar({ activeScreen, onNavigate }) {
  const save = loadSave();

  return (
    <div className="nav-bar">
      <div className="nav-tabs">
        <button
          className={`nav-tab ${activeScreen === 'hatchery' ? 'active' : ''}`}
          onClick={() => onNavigate('hatchery')}
        >
          HATCHERY
        </button>
        <button
          className={`nav-tab ${activeScreen === 'battleSelect' ? 'active' : ''}`}
          onClick={() => onNavigate('battleSelect')}
        >
          BATTLES
        </button>
      </div>
      <div className="nav-scraps">
        ◆ {save.dataScraps}
      </div>
    </div>
  );
}
