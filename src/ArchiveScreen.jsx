// @ts-nocheck
// Archive codex (gameplay plan #8): the Journal's lore-completion loop, made
// visible. Every boss felled, remnant quieted, fragment decrypted, and final
// encounter survived is written down here from EXISTING save flags — no new
// tracking for the first loop. Locked entries are silhouettes; unlocked ones
// show the lore text already in the codebase. The NG+ chase track (lore
// depth + ascendant remnant clears + lore-only milestones) renders here, and
// only while an NG+ run is active (save.ngPlus >= 1).
import {
  SINGULARITY_BOSSES,
  FINAL_BOSS,
  MIRROR_ADMIN,
  CORRUPTION_REMNANTS,
} from './singularityBosses';
import { CAPTAINS_LOG_FRAGMENTS, getCaptainLogDisplay } from './forgeData';
import { FELIX_CONTEXT_LINES, ASCENDANT_RECORD_LORE } from './loreCanon';
import { isNgPlusRunActive } from './persistence';

// Archive group definitions: title + the blurb framing the fantasy as
// completing the lore record (not power, not proof).
export const ARCHIVE_GROUPS = [
  { id: 'bosses', title: 'BOSSES', blurb: 'Threats felled in the Singularity. Each one left a scar on the Matrix — and a page here.' },
  { id: 'remnants', title: 'REMNANTS', blurb: 'Echoes of old bosses, quieted in the dead sectors after the war was won.' },
  { id: 'fragments', title: "CAPTAIN'S LOG", blurb: 'Decrypted signal from the Astraeus. The truth about the world, in the captain\u2019s own words.' },
  { id: 'beats', title: 'MIRROR ADMIN BEATS', blurb: 'The final encounters. Read them so the Reset can never claim they didn\u2019t happen.' },
];

// NG+ chase-track milestone ids, in display order.
export const NGPLUS_MILESTONE_IDS = [
  'ngplus_depth_1',
  'ngplus_depth_3',
  'ngplus_depth_5',
  'ngplus_ascendant_remnants',
];

// Pure mapping: save flags -> archive entries. Unlocked entries carry the
// lore text already in the codebase; locked ones are silhouettes.
export function getArchiveEntries(save) {
  const defeated = save?.singularityProgress?.defeated || [];
  const remnants = Array.isArray(save?.remnantDefeated) ? save.remnantDefeated : [];
  const fragments = save?.flags?.fragmentsUnlocked || [];
  const ngPlusRemnants = Array.isArray(save?.ngPlusRemnantClears) ? save.ngPlusRemnantClears : [];

  const bosses = SINGULARITY_BOSSES.map((b) => ({
    group: 'bosses',
    id: b.id,
    name: b.name,
    sub: b.element ? `${b.element.toUpperCase()} · SINGULARITY` : 'SINGULARITY',
    unlocked: defeated.includes(b.id),
    body: b.felixQuote,
  }));

  const remnantEntries = CORRUPTION_REMNANTS.map((r) => ({
    group: 'remnants',
    id: r.id,
    name: r.name,
    sub: `REMNANT · ${String(r.phases?.[0]?.element || r.element || '').toUpperCase()} · ${r.phases?.length || 1} PHASES`,
    unlocked: remnants.includes(r.id),
    body: r.felixQuote,
    // Cleared while an NG+ run was active: feeds both depth and the archive.
    ascendant: ngPlusRemnants.includes(r.id),
  }));

  const fragmentEntries = CAPTAINS_LOG_FRAGMENTS.map((f) => {
    const display = getCaptainLogDisplay(f, fragments);
    return {
      group: 'fragments',
      id: `fragment_${f.id}`,
      name: display.heading,
      sub: display.isUnlocked ? 'DECRYPTED' : display.status,
      unlocked: display.isUnlocked,
      body: display.body,
    };
  });

  const beats = [
    {
      group: 'beats',
      id: 'the_singularity',
      name: FINAL_BOSS.name,
      sub: 'FINAL',
      unlocked: save?.singularityComplete === true,
      body: FINAL_BOSS.felixQuote,
    },
    {
      group: 'beats',
      id: 'mirror_admin',
      name: MIRROR_ADMIN.name,
      sub: 'TRUE FINAL',
      unlocked: save?.mirrorAdminDefeated === true,
      body: `${MIRROR_ADMIN.felixQuote}\n\nRecovered transmissions:\n${MIRROR_ADMIN.phaseLines.map((l) => `\u201C${l}\u201D`).join('\n')}`,
    },
  ];

  return { bosses, remnants: remnantEntries, fragments: fragmentEntries, beats };
}

export function getArchiveCompletion(entries) {
  const all = [...entries.bosses, ...entries.remnants, ...entries.fragments, ...entries.beats];
  const unlocked = all.filter((e) => e.unlocked).length;
  return {
    unlocked,
    total: all.length,
    pct: all.length ? Math.round((unlocked / all.length) * 100) : 0,
  };
}

function ArchiveEntry({ entry }) {
  return (
    <article className={`archive-entry ${entry.unlocked ? 'is-unlocked' : 'is-locked'}`}>
      <div className="archive-entry-head">
        <h4>{entry.unlocked ? entry.name : '???'}</h4>
        <span className="archive-entry-sub">{entry.unlocked ? entry.sub : 'UNDISCOVERED'}</span>
      </div>
      <p className="archive-entry-body">
        {entry.unlocked ? entry.body : 'No record yet. The Archive only keeps what you have witnessed.'}
      </p>
      {entry.unlocked && entry.ascendant && (
        <div className="archive-ascendant-tag">◈ ASCENDANT — QUIETED IN THE SECOND LOOP</div>
      )}
      {entry.unlocked && entry.group === 'beats' && entry.id === 'mirror_admin' && (
        <p className="archive-entry-note">{FELIX_CONTEXT_LINES.mirrorAdminDefeated}</p>
      )}
    </article>
  );
}

export default function ArchiveScreen({ save, milestones = [], onClaim }) {
  const entries = getArchiveEntries(save);
  const { unlocked, total, pct } = getArchiveCompletion(entries);
  const ngPlusActive = isNgPlusRunActive(save);
  const depth = save?.ngPlusLoreDepth || 0;
  const ngMilestones = milestones.filter((m) => m.ngPlus);
  const claimed = save?.milestones || [];

  const nextDepthMilestone = ngMilestones
    .filter((m) => m.id.startsWith('ngplus_depth_') && !claimed.includes(m.id))
    .sort((a, b) => {
      const da = Number(a.id.split('_').pop());
      const db = Number(b.id.split('_').pop());
      return da - db;
    })[0];

  return (
    <div className="archive">
      <div className="archive-header">
        <p className="archive-kicker">THE ARCHIVE</p>
        <p className="archive-flavor">
          Every boss felled, every fragment decrypted, every echo quieted — written down
          so the Reset can never claim it didn&apos;t happen. Complete the record.
        </p>
        <div className="archive-completion">
          <div className="archive-completion-bar">
            <div className="archive-completion-fill" style={{ width: `${pct}%` }} />
          </div>
          <span className="archive-completion-text">{unlocked}/{total} · {pct}%</span>
        </div>
      </div>

      {ARCHIVE_GROUPS.map((group) => (
        <section key={group.id} className="archive-group">
          <div className="archive-group-head">
            <h3>{group.title}</h3>
            <span className="archive-group-count">
              {entries[group.id].filter((e) => e.unlocked).length}/{entries[group.id].length}
            </span>
          </div>
          <p className="archive-group-blurb">{group.blurb}</p>
          <div className="archive-entry-list">
            {entries[group.id].map((entry) => (
              <ArchiveEntry key={entry.id} entry={entry} />
            ))}
          </div>
        </section>
      ))}

      {ngPlusActive && (
        <section className="archive-ngplus">
          <p className="archive-kicker">SECOND LOOP — THE DEEPENING RECORD</p>
          <p className="archive-flavor">
            The first loop proved this world is alive. The second loop is writing it down:
            each step past the Mirror Admin&apos;s shadow is a page the Reset cannot burn.
            Depth is the record growing longer — not a stronger sword.
          </p>
          <div className="archive-depth">
            <div className="archive-depth-row">
              <span className="archive-depth-label">LORE DEPTH</span>
              <span className="archive-depth-value">{depth}</span>
            </div>
            {nextDepthMilestone && (
              <div className="archive-depth-next">
                Next page: {nextDepthMilestone.name} — {nextDepthMilestone.progress}
              </div>
            )}
          </div>

          <div className="archive-chase-list">
            {ngMilestones.map((m) => {
              const isClaimed = m.claimed || claimed.includes(m.id);
              const claimable = m.newlyClaimed && !isClaimed;
              return (
                <div
                  key={m.id}
                  className={`milestone-badge ${isClaimed ? 'claimed' : ''} ${claimable ? 'claimable' : ''}`}
                  title={m.loreReward ? `${m.description} — reward: ${m.loreReward.title}` : m.description}
                >
                  {isClaimed ? '✓ ' : ''}{m.name}
                  {claimable && onClaim ? (
                    <button className="milestone-claim-btn" onClick={() => onClaim(m)}>
                      RECORD 📜
                    </button>
                  ) : (
                    !isClaimed && <span style={{ display: 'block', fontSize: 6, color: '#444' }}>{m.progress}</span>
                  )}
                </div>
              );
            })}
          </div>

          <div className="archive-ascendant">
            <h3>ASCENDANT RECORD</h3>
            <p className="archive-group-blurb">
              Felix&apos;s field notes from the second loop. Claimed pages are written in full;
              unclaimed ones are still silence.
            </p>
            {NGPLUS_MILESTONE_IDS.map((id) => {
              const lore = ASCENDANT_RECORD_LORE[id];
              const isClaimed = claimed.includes(id);
              return (
                <article key={id} className={`archive-lore-entry ${isClaimed ? 'is-unlocked' : 'is-locked'}`}>
                  <h4>{isClaimed ? lore.title : '???'}</h4>
                  <p>
                    {isClaimed ? `\u201C${lore.body}\u201D` : 'Undiscovered. Push the record deeper in a New Game+ run.'}
                  </p>
                  {isClaimed && <span className="archive-entry-note">— Professor Felix</span>}
                </article>
              );
            })}
          </div>
        </section>
      )}
    </div>
  );
}
