import { dragons, elementColors, ELEMENTS } from './gameData';
import { getStageForLevel } from './battleEngine';
import NavBar from './NavBar';

export default function StatsScreen({ onNavigate, save }) {
  const stats = save.stats || {};
  const ownedDragons = ELEMENTS.filter(el => save.dragons[el]?.owned);

  // Find highest level dragon
  let highestDragon = null;
  let highestLevel = 0;
  for (const el of ELEMENTS) {
    const d = save.dragons[el];
    if (d?.owned && d.level > highestLevel) {
      highestLevel = d.level;
      highestDragon = el;
    }
  }

  // Count shinies
  const shinyCount = ELEMENTS.filter(el => save.dragons[el]?.owned && save.dragons[el]?.shiny).length;

  // Total cores
  const cores = save.inventory?.cores || {};
  const totalCores = Object.values(cores).reduce((sum, n) => sum + n, 0);

  return (
    <div>
      <NavBar activeScreen="stats" onNavigate={onNavigate} save={save} />

      <div className="stats-layout">
        <div className="stats-title">FORGE STATISTICS</div>

        <div className="stats-grid">
          <div className="stats-card">
            <div className="stats-card-label">Battles Won</div>
            <div className="stats-card-value">{stats.battlesWon || 0}</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Battles Lost</div>
            <div className="stats-card-value">{stats.battlesLost || 0}</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Win Rate</div>
            <div className="stats-card-value">
              {(stats.battlesWon || 0) + (stats.battlesLost || 0) > 0
                ? `${Math.round(((stats.battlesWon || 0) / ((stats.battlesWon || 0) + (stats.battlesLost || 0))) * 100)}%`
                : '—'}
            </div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Total Pulls</div>
            <div className="stats-card-value">{stats.totalPulls || 0}</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Fusions</div>
            <div className="stats-card-value">{stats.fusionsCompleted || 0}</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">DataScraps Earned</div>
            <div className="stats-card-value" style={{ color: '#ffcc00' }}>{stats.totalScrapsEarned || 0} ◆</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Dragons Owned</div>
            <div className="stats-card-value">{ownedDragons.length}/{ELEMENTS.length}</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Shiny Dragons</div>
            <div className="stats-card-value" style={{ color: '#ffcc00' }}>{shinyCount} ★</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Highest Dragon</div>
            <div className="stats-card-value" style={{ color: highestDragon ? elementColors[highestDragon]?.glow : '#888' }}>
              {highestDragon ? `${(save.dragons[highestDragon]?.nickname || dragons[highestDragon].name)} Lv.${highestLevel}` : '—'}
            </div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Element Cores</div>
            <div className="stats-card-value" style={{ color: '#44aaff' }}>{totalCores}</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">Current DataScraps</div>
            <div className="stats-card-value" style={{ color: '#ffcc00' }}>{save.dataScraps} ◆</div>
          </div>
          <div className="stats-card">
            <div className="stats-card-label">NPCs Defeated</div>
            <div className="stats-card-value">{(save.defeatedNpcs || []).length}</div>
          </div>
        </div>

        {save.singularityComplete && (
          <div className="stats-singularity-badge">
            🏆 SINGULARITY CONTAINED
          </div>
        )}
      </div>
    </div>
  );
}
