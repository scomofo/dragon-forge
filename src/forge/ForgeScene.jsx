import { FORGE_PALETTE, FORGE_STATIONS, STATION_IDS } from '../forgeData';
import { assetUrl } from '../utils';

export default function ForgeScene({ skyePos, nearest, view }) {
  return (
    <>
      <WallTexture />
      <CeilingBand />
      <ForgeAtmosphere />
      <BulkheadView view={view} />
      <ForgeFloorHorizon />
      <ForgeFloorZones />
      <CablePaths />
      <FloorGrid />
      {FORGE_STATIONS.map((station) => (
        <Station key={station.id} station={station} highlighted={nearest?.id === station.id} />
      ))}
      <SkyeSprite pos={skyePos} />
      <StationIndex nearest={nearest} />
      <ProximityHud nearest={nearest} />
      <ControlsHint />
      <ForgeScanlines />
    </>
  );
}

function WallTexture() {
  return <div className="forge-wall-texture" aria-hidden />;
}

function CeilingBand() {
  return <div className="forge-ceiling-band" aria-hidden />;
}

function ForgeFloorHorizon() {
  return <div className="forge-floor-horizon" aria-hidden />;
}

function ForgeScanlines() {
  return <div className="forge-scanlines" aria-hidden />;
}

function ForgeAtmosphere() {
  return (
    <>
      <div className="forge-atmosphere" aria-hidden />
      <div className="forge-light-slice" aria-hidden />
    </>
  );
}

function BulkheadView({ view }) {
  return (
    <div
      className="forge-bulkhead-view"
      style={{
        '--bulkhead-top': view.palette[0],
        '--bulkhead-mid': view.palette[1],
        '--bulkhead-bottom': view.palette[2],
      }}
      aria-hidden
    >
      <div className="forge-bulkhead-scanlines" />
    </div>
  );
}

function ForgeFloorZones() {
  const zones = [
    { left: '16%', top: '19%', width: '28%', height: '23%', color: FORGE_PALETTE.hatcheryCyan, label: 'HATCHERY' },
    { left: '19%', top: '50%', width: '25%', height: '26%', color: FORGE_PALETTE.coalGlow, label: 'ANVIL' },
    { left: '45%', top: '49%', width: '22%', height: '28%', color: FORGE_PALETTE.consoleGreen, label: 'CONSOLE' },
    { left: '63%', top: '19%', width: '16%', height: '20%', color: FORGE_PALETTE.lanternWarm, label: 'SAVE' },
  ];

  return (
    <>
      {zones.map((zone) => (
        <div
          key={zone.label}
          className="forge-floor-zone"
          aria-hidden
          style={{
            left: zone.left,
            top: zone.top,
            width: zone.width,
            height: zone.height,
            '--zone-color': zone.color,
          }}
        />
      ))}
      <div className="forge-front-platform" aria-hidden />
    </>
  );
}

function CablePaths() {
  const shadow = (points, w) => (
    <polyline points={points} fill="none" stroke="rgba(0,0,0,0.55)" strokeWidth={w}
      strokeLinecap="square" strokeLinejoin="miter" />
  );
  const cable = (points, color, width) => (
    <polyline points={points} fill="none" stroke={color} strokeWidth={width}
      strokeLinecap="square" strokeLinejoin="miter" opacity="0.78" />
  );
  const box = (x, y, color) => (
    <rect x={x - 1.2} y={y - 1.2} width={2.4} height={2.4}
      fill="rgba(0,0,0,0.7)" stroke={color} strokeWidth={0.4} opacity="0.85" />
  );

  return (
    <svg className="forge-cables" aria-hidden viewBox="0 0 100 100" preserveAspectRatio="none">
      {/* Shadows first */}
      {shadow('30,75 30,60 42,60 55,60', 1.3)}
      {shadow('30,75 30,60 30,30 30,8', 1.3)}
      {shadow('55,60 70,60 70,28 70,8', 1.15)}
      {shadow('55,60 76,56 88,50', 1.15)}
      {shadow('22,78 30,75', 1.1)}
      {shadow('55,60 55,8', 1.1)}
      {shadow('42,60 42,8', 1.1)}

      {/* Colour cables */}
      {cable('30,75 30,60 42,60 55,60', '#5cff8a', 0.48)}
      {cable('30,75 30,60 30,30 30,8', '#5edcff', 0.52)}
      {cable('55,60 70,60 70,28 70,8', '#ffcd6b', 0.44)}
      {cable('55,60 76,56 88,50', '#8fcf6c', 0.52)}
      {cable('22,78 30,75', '#c9a567', 0.40)}
      {cable('55,60 55,8', '#5cff8a', 0.36)}
      {cable('42,60 42,8', '#5edcff', 0.36)}

      {/* Junction boxes at key intersections */}
      {box(30, 60, '#5edcff')}
      {box(55, 60, '#5cff8a')}
      {box(70, 60, '#ffcd6b')}
      {box(42, 60, '#5edcff')}
      {box(30, 30, '#5edcff')}
    </svg>
  );
}

function FloorGrid() {
  return <div className="forge-floor-grid" aria-hidden />;
}

function Station({ station, highlighted }) {
  const { pos, size, glow, label, pulseMs } = station;
  const isRing = station.id === STATION_IDS.HATCHERY_RING;

  return (
    <div
      className={`forge-station ${highlighted ? 'is-highlighted' : ''} ${isRing ? 'is-ring' : ''}`}
      data-station-id={station.id}
      style={{
        left: `${pos.x - size.w / 2}%`,
        top: `${pos.y - size.h / 2}%`,
        width: `${size.w}%`,
        height: `${size.h}%`,
        '--station-glow': glow || '#d7ad4b',
        '--station-pulse-ms': `${pulseMs || 0}ms`,
      }}
    >
      <StationSilhouette type={station.id} highlighted={highlighted} glow={glow} />
      <span className="forge-station-label">{label}</span>
    </div>
  );
}

function StationSilhouette({ type, glow, highlighted }) {
  const color = glow || '#c9a567';
  const style = { '--silhouette-color': color };

  if (type === STATION_IDS.HATCHERY_RING) {
    return (
      <div className={`forge-silhouette hatchery ${highlighted ? 'is-highlighted' : ''}`} style={style}>
        <div className="ring" />
        <div className="egg" />
        <div className="h-line" />
        <div className="v-line" />
      </div>
    );
  }

  return <div className={`forge-silhouette ${type} ${highlighted ? 'is-highlighted' : ''}`} style={style} />;
}

function SkyeSprite({ pos }) {
  return (
    <div
      className="forge-skye"
      style={{ left: `${pos.x - 2}%`, top: `${pos.y - 10}%` }}
      aria-label="Skye"
      data-testid="forge-skye"
    >
      <img
        src={assetUrl('/assets/characters/skye.png')}
        className="forge-skye-sprite"
        alt=""
        draggable={false}
      />
    </div>
  );
}

function ProximityHud({ nearest }) {
  if (!nearest) return null;
  return (
    <div className="forge-proximity-hud" data-testid="forge-proximity">
      <span>[E]</span> <strong>{nearest.label}</strong>{' '}
      <small>{nearest.description}</small>
    </div>
  );
}

function StationIndex({ nearest }) {
  return (
    <div className="forge-station-index" aria-label="Station guide">
      {FORGE_STATIONS.map((station) => (
        <div
          key={station.id}
          className={`forge-index-row ${nearest?.id === station.id ? 'is-active' : ''}`}
          style={{ '--index-color': station.glow || '#c9a567' }}
        >
          <span className="forge-index-pip" aria-hidden="true" />
          <div className="forge-index-copy">
            <strong>{station.label}</strong>
            <small>{station.hint}</small>
          </div>
        </div>
      ))}
    </div>
  );
}

function ControlsHint() {
  return <div className="forge-controls-hint">WASD / arrows to walk &nbsp;|&nbsp; E to interact &nbsp;|&nbsp; Esc to close</div>;
}
