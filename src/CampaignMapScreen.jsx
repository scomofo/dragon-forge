import { useMemo, useState } from 'react';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';
import { calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { CAMPAIGN_NODES, getCampaignNodeState, getCampaignNodeStates } from './campaignMap';
import { dragons, elementColors, npcs } from './gameData';
import { playSound } from './soundEngine';
import { assetUrl } from './utils';
import { findDirectionalNode } from './gamepadInput';
import useGamepadController from './useGamepadController';

const CONNECTIONS = CAMPAIGN_NODES.flatMap((node) =>
  node.prerequisiteIds.map((fromId) => ({ fromId, toId: node.id }))
);

const TERRAIN_BEACONS = [
  { id: 'forge', label: 'FORGE', tone: 'forge', position: { x: 14, y: 28 } },
  { id: 'archive', label: 'ARCHIVE', tone: 'archive', position: { x: 50, y: 18 } },
  { id: 'swamp', label: 'VENOM', tone: 'venom', position: { x: 72, y: 78 } },
  { id: 'gate', label: 'GATE', tone: 'gate', position: { x: 91, y: 28 } },
];

const SIGNAL_SPARKS = [
  { id: 'spark-a', position: { x: 33, y: 28 }, delay: '0s' },
  { id: 'spark-b', position: { x: 63, y: 41 }, delay: '-0.8s' },
  { id: 'spark-c', position: { x: 79, y: 61 }, delay: '-1.4s' },
  { id: 'spark-d', position: { x: 28, y: 73 }, delay: '-2s' },
];

const STAT_CAP = 130;

function getRouteLaneStyle(from, to) {
  const dx = to.position.x - from.position.x;
  const dy = to.position.y - from.position.y;
  const distance = Math.sqrt(dx * dx + dy * dy);
  const angle = Math.atan2(dy, dx) * (180 / Math.PI);
  return {
    '--route-x': `${from.position.x}%`,
    '--route-y': `${from.position.y}%`,
    '--route-length': distance,
    '--route-angle': `${angle}deg`,
  };
}

function isSelectedConnection(link, selectedNodeId) {
  return link.fromId === selectedNodeId || link.toId === selectedNodeId;
}

function getNodeTypeGlyph(type) {
  if (type === 'boss') return 'B';
  if (type === 'elite') return 'E';
  return 'N';
}

function getStatPercent(value) {
  return `${Math.min(100, Math.round((value / STAT_CAP) * 100))}%`;
}

function getRouteChipLabel(node) {
  return node.label
    .split(' ')
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();
}

export default function CampaignMapScreen({ save, onNavigate, onBeginCampaignBattle }) {
  const nodeStates = useMemo(() => getCampaignNodeStates(save), [save]);
  const firstActionable = CAMPAIGN_NODES.find((node) => nodeStates[node.id] === 'available') || CAMPAIGN_NODES[0];
  const [selectedNodeId, setSelectedNodeId] = useState(firstActionable.id);
  const [selectedDragonId, setSelectedDragonId] = useState(null);

  const selectedNode = CAMPAIGN_NODES.find((node) => node.id === selectedNodeId) || firstActionable;
  const selectedState = getCampaignNodeState(selectedNode, save);
  const selectedNpc = npcs[selectedNode.npcId];
  const selectedColor = elementColors[selectedNode.element] || elementColors.neutral;
  const clearedCount = Object.values(nodeStates).filter((state) => state === 'cleared').length;
  const availableCount = Object.values(nodeStates).filter((state) => state === 'available').length;
  const signalPressure = Math.max(0, 100 - Math.round((clearedCount / CAMPAIGN_NODES.length) * 100));
  const ownedDragons = Object.entries(save.dragons)
    .filter(([, progress]) => progress.owned)
    .map(([id, progress]) => ({ id, progress, data: dragons[id] }))
    .filter((entry) => entry.data);
  const selectedDragonEntry = ownedDragons.find((entry) => entry.id === selectedDragonId);
  const selectedDragon = selectedDragonId ? dragons[selectedDragonId] : null;
  const selectedDragonStats = selectedDragonEntry
    ? calculateStatsForLevel(
        selectedDragonEntry.progress.fusedBaseStats || selectedDragonEntry.data.baseStats,
        selectedDragonEntry.progress.level,
        selectedDragonEntry.progress.shiny
      )
    : null;
  const canBegin = selectedState === 'available' && selectedDragonId;
  const routeChainNodes = [
    ...selectedNode.prerequisiteIds
      .map((id) => CAMPAIGN_NODES.find((node) => node.id === id))
      .filter(Boolean),
    selectedNode,
  ];

  function selectNode(node) {
    playSound('buttonClick');
    setSelectedNodeId(node.id);
  }

  function selectDragon(dragonId) {
    playSound('buttonClick');
    setSelectedDragonId(dragonId);
  }

  function beginBattle() {
    if (!canBegin) return;
    playSound('buttonClick');
    onBeginCampaignBattle({
      nodeId: selectedNode.id,
      dragonId: selectedDragonId,
      npcId: selectedNode.npcId,
    });
  }

  function cycleDragon(direction) {
    if (ownedDragons.length === 0) return;
    const currentIndex = Math.max(0, ownedDragons.findIndex((entry) => entry.id === selectedDragonId));
    const nextIndex = (currentIndex + direction + ownedDragons.length) % ownedDragons.length;
    selectDragon(ownedDragons[nextIndex].id);
  }

  useGamepadController({
    onDirectionPress: (direction) => {
      const nextNode = findDirectionalNode(CAMPAIGN_NODES, selectedNode.id, direction);
      if (nextNode && nextNode.id !== selectedNode.id) selectNode(nextNode);
    },
    onButtonPress: (button) => {
      if (button === 'LB') cycleDragon(-1);
      if (button === 'RB' || button === 'Y') cycleDragon(1);
      if (button === 'A' || button === 'START') {
        if (!selectedDragonId && ownedDragons.length > 0) {
          selectDragon(ownedDragons[0].id);
        } else {
          beginBattle();
        }
      }
      if (button === 'B') onNavigate?.('battleSelect');
    },
  });

  return (
    <div className="campaign-map-screen">
      <NavBar activeScreen="map" onNavigate={onNavigate} save={save} />

      <div className="campaign-map-shell">
        <section className="campaign-map-stage" aria-label="Campaign map">
          <div className="campaign-map-header">
            <div>
              <div className="campaign-kicker">ELEMENTAL MATRIX</div>
              <h1>CAMPAIGN MAP</h1>
            </div>
            <div className="campaign-progress-panel">
              <div className="campaign-progress">
                {clearedCount}/{CAMPAIGN_NODES.length} STABILIZED
              </div>
              <div className="campaign-progress-rail" aria-hidden="true">
                {CAMPAIGN_NODES.map((node, index) => (
                  <span
                    key={node.id}
                    className={`${nodeStates[node.id]} ${selectedNode.id === node.id ? 'selected' : ''}`}
                    style={{ '--rail-delay': `${index * 0.07}s` }}
                  />
                ))}
              </div>
            </div>
          </div>

          <div
            className="matrix-route"
            style={{ '--campaign-map-bg': `url(${assetUrl('/assets/map/campaign_matrix.png')})` }}
          >
            <div className="matrix-vignette" aria-hidden="true" />
            <div className="matrix-sector sector-forge" aria-hidden="true">FORGE RIM</div>
            <div className="matrix-sector sector-archive" aria-hidden="true">ARCHIVE FAULT</div>
            <div className="matrix-sector sector-gate" aria-hidden="true">BOSS GATE</div>
            <div className="boss-pressure" aria-hidden="true" />
            <div className="matrix-weather weather-a" aria-hidden="true" />
            <div className="matrix-weather weather-b" aria-hidden="true" />
            <div className="corruption-field field-a" aria-hidden="true" />
            <div className="corruption-field field-b" aria-hidden="true" />
            <div className="map-telemetry" aria-hidden="true">
              <span><strong>{availableCount}</strong> LIVE</span>
              <span><strong>{signalPressure}%</strong> NOISE</span>
              <span><strong>{selectedNode.element.toUpperCase()}</strong> TRACE</span>
            </div>
            {SIGNAL_SPARKS.map((spark) => (
              <span
                key={spark.id}
                className="signal-spark"
                style={{
                  '--spark-x': `${spark.position.x}%`,
                  '--spark-y': `${spark.position.y}%`,
                  '--spark-delay': spark.delay,
                }}
                aria-hidden="true"
              />
            ))}
            {TERRAIN_BEACONS.map((beacon) => (
              <div
                key={beacon.id}
                className={`terrain-beacon ${beacon.tone}`}
                style={{
                  '--beacon-x': `${beacon.position.x}%`,
                  '--beacon-y': `${beacon.position.y}%`,
                }}
                aria-hidden="true"
              >
                <span />
                <strong>{beacon.label}</strong>
              </div>
            ))}
            <svg className="route-links" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
              {CONNECTIONS.map((link) => {
                const from = CAMPAIGN_NODES.find((node) => node.id === link.fromId);
                const to = CAMPAIGN_NODES.find((node) => node.id === link.toId);
                const active = nodeStates[from.id] === 'cleared';
                const selected = isSelectedConnection(link, selectedNode.id);
                return (
                  <line
                    key={`${link.fromId}-${link.toId}`}
                    x1={from.position.x}
                    y1={from.position.y}
                    x2={to.position.x}
                    y2={to.position.y}
                    className={`route-link ${active ? 'active' : ''} ${selected ? 'selected' : ''}`}
                  />
                );
              })}
            </svg>
            <div className="route-energy" aria-hidden="true">
              {CONNECTIONS.map((link, index) => {
                const from = CAMPAIGN_NODES.find((node) => node.id === link.fromId);
                const to = CAMPAIGN_NODES.find((node) => node.id === link.toId);
                const active = nodeStates[from.id] === 'cleared';
                const selected = isSelectedConnection(link, selectedNode.id);
                return (
                  <span
                    key={`${link.fromId}-${link.toId}-energy`}
                    className={`route-energy-lane ${active ? 'active' : 'dormant'} ${selected ? 'selected' : ''}`}
                    style={{
                      ...getRouteLaneStyle(from, to),
                      '--route-delay': `${index * 0.22}s`,
                    }}
                  />
                );
              })}
            </div>

            {CAMPAIGN_NODES.map((node) => {
              const state = nodeStates[node.id];
              const color = elementColors[node.element] || elementColors.neutral;
              const isSelected = selectedNode.id === node.id;
              return (
                <button
                  key={node.id}
                  className={`campaign-node ${state} ${node.type} ${isSelected ? 'selected controller-focus' : ''}`}
                  style={{
                    '--node-x': `${node.position.x}%`,
                    '--node-y': `${node.position.y}%`,
                    '--node-color': color.primary,
                    '--node-glow': color.glow,
                  }}
                  onClick={() => selectNode(node)}
                  aria-label={`${node.label} ${state}`}
                >
                  <span className={`node-type-badge ${node.type}`}>{getNodeTypeGlyph(node.type)}</span>
                  <span className="node-orb">{state === 'locked' ? 'LOCK' : state === 'cleared' ? 'OK' : color.icon}</span>
                  <span className="node-label">{node.label}</span>
                </button>
              );
            })}
            <div
              className={`selected-node-scanner ${selectedState}`}
              style={{
                '--scan-x': `${selectedNode.position.x}%`,
                '--scan-y': `${selectedNode.position.y}%`,
                '--scan-color': elementColors[selectedNode.element]?.primary || '#ff8844',
              }}
              aria-hidden="true"
            >
              <span className="scanner-axis horizontal" />
              <span className="scanner-axis vertical" />
              <span className="scanner-core" />
            </div>
            <div
              className={`selected-map-card ${selectedState}`}
              style={{
                '--callout-x': `${selectedNode.position.x}%`,
                '--callout-y': `${selectedNode.position.y}%`,
                '--callout-color': selectedColor.primary,
                '--callout-glow': selectedColor.glow,
              }}
              aria-hidden="true"
            >
              <span>{selectedState.toUpperCase()}</span>
              <strong>{selectedNode.label}</strong>
              <small>{selectedNpc?.name || 'Unknown Signal'}</small>
            </div>
            <div className="map-legend" aria-hidden="true">
              <span><i className="legend-available" /> ACTIVE</span>
              <span><i className="legend-locked" /> LOCKED</span>
              <span><i className="legend-cleared" /> STABLE</span>
            </div>
          </div>
        </section>

        <aside className="campaign-detail">
          <div className={`detail-state ${selectedState}`}>{selectedState.toUpperCase()}</div>
          <h2>{selectedNode.label}</h2>
          <p>{selectedNode.description}</p>

          <div className="selected-route-chain">
            <span>ROUTE TRACE</span>
            <div>
              {routeChainNodes.map((node) => (
                <i
                  key={node.id}
                  className={`${nodeStates[node.id]} ${node.id === selectedNode.id ? 'selected' : ''}`}
                  style={{
                    '--chain-color': (elementColors[node.element] || elementColors.neutral).primary,
                  }}
                >
                  {getRouteChipLabel(node)}
                </i>
              ))}
            </div>
          </div>

          <div
            className={`enemy-signal-card ${selectedNode.type}`}
            style={{
              '--enemy-color': elementColors[selectedNode.element]?.primary || '#ff8844',
              '--enemy-glow': elementColors[selectedNode.element]?.glow || '#ffaa66',
            }}
          >
            <div className="enemy-signal-portrait">
              {selectedNpc?.idleSprite && (
                <img src={selectedNpc.idleSprite} alt={selectedNpc.name} className="pixelated" />
              )}
            </div>
            <div className="enemy-signal-copy">
              <span>{selectedNode.type.toUpperCase()} SIGNAL</span>
              <strong>{selectedNpc?.name || 'Unknown Signal'}</strong>
              <small>{selectedNode.element.toUpperCase()} · {selectedNode.difficulty}</small>
            </div>
          </div>

          {selectedNpc?.stats && (
            <div className="signal-stat-stack" aria-label={`${selectedNpc.name} combat profile`}>
              {Object.entries(selectedNpc.stats).map(([stat, value]) => (
                <div
                  key={stat}
                  className="signal-stat"
                  style={{
                    '--stat-fill': getStatPercent(value),
                    '--stat-color': selectedColor.primary,
                  }}
                >
                  <span>{stat.toUpperCase()}</span>
                  <strong>{value}</strong>
                  <i />
                </div>
              ))}
            </div>
          )}

          <div className="detail-grid">
            <div>
              <span>ENEMY</span>
              <strong>{selectedNpc?.name || 'Unknown Signal'}</strong>
            </div>
            <div>
              <span>THREAT</span>
              <strong>{selectedNpc ? `Lv.${selectedNpc.level} · ${selectedNode.difficulty}` : selectedNode.difficulty}</strong>
            </div>
            <div>
              <span>ELEMENT</span>
              <strong style={{ color: elementColors[selectedNode.element]?.glow }}>{selectedNode.element.toUpperCase()}</strong>
            </div>
            <div>
              <span>REWARD</span>
              <strong>{selectedNode.rewardPreview}</strong>
            </div>
          </div>

          {selectedState === 'locked' && (
            <div className="unlock-note">
              Clear {selectedNode.prerequisiteIds.map(id => CAMPAIGN_NODES.find(node => node.id === id)?.label).filter(Boolean).join(' + ')} to unlock.
            </div>
          )}

          <div className="dragon-picker-title">CHOOSE GUARDIAN</div>
          <div className="campaign-dragon-list">
            {ownedDragons.length === 0 && (
              <div className="empty-dragons">Pull a dragon from the Hatchery to enter the campaign.</div>
            )}
            {ownedDragons.map(({ id, progress, data }) => {
              const stage = getStageForLevel(progress.level);
              const stats = calculateStatsForLevel(progress.fusedBaseStats || data.baseStats, progress.level, progress.shiny);
              const color = elementColors[data.element];
              return (
                <button
                  key={id}
                  className={`campaign-dragon ${selectedDragonId === id ? 'selected controller-focus' : ''}`}
                  style={{ '--dragon-color': color.primary, '--dragon-glow': color.glow }}
                  onClick={() => selectDragon(id)}
                >
                  <DragonSprite
                    spriteSheet={data.stageSprites?.[stage] || data.spriteSheet}
                    stage={stage}
                    size={{ width: 74, height: 52 }}
                    shiny={progress.shiny}
                    element={data.element}
                  />
                  <span>
                    <strong>{color.icon} {progress.nickname || data.name}</strong>
                    <small>Lv.{progress.level} · HP {stats.hp} · ATK {stats.atk}</small>
                  </span>
                </button>
              );
            })}
          </div>

          <div
            className={`guardian-link ${selectedDragonEntry ? 'online' : 'offline'}`}
            style={{
              '--guardian-color': selectedDragonEntry
                ? (elementColors[selectedDragonEntry.data.element] || elementColors.neutral).primary
                : '#666',
              '--guardian-glow': selectedDragonEntry
                ? (elementColors[selectedDragonEntry.data.element] || elementColors.neutral).glow
                : '#888',
            }}
          >
            <div>
              <span>GUARDIAN LINK</span>
              <strong>
                {selectedDragonEntry
                  ? selectedDragonEntry.progress.nickname || selectedDragonEntry.data.name
                  : 'NO DRAGON SELECTED'}
              </strong>
            </div>
            {selectedDragonStats ? (
              <div className="guardian-stat-grid">
                {Object.entries(selectedDragonStats).map(([stat, value]) => (
                  <i key={stat}>
                    <span>{stat.toUpperCase()}</span>
                    <strong>{value}</strong>
                  </i>
                ))}
              </div>
            ) : (
              <small>Select a guardian to synchronize battle systems.</small>
            )}
          </div>

          <button className={`campaign-begin ${canBegin ? 'ready' : ''}`} disabled={!canBegin} onClick={beginBattle}>
            {selectedState === 'cleared' ? 'NODE STABILIZED' : selectedState === 'locked' ? 'SIGNAL LOCKED' : selectedDragon ? 'BEGIN BATTLE' : 'SELECT DRAGON'}
          </button>
        </aside>
      </div>
    </div>
  );
}
