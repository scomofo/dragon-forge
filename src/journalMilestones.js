import { CAMPAIGN_NODES } from './campaignMap';
import { CORRUPTION_REMNANTS } from './singularityBosses';
import { ASCENDANT_RECORD_LORE } from './loreCanon';
import { rarityTiers, JOURNAL_DRAGON_IDS } from './gameData';

// === CODEX TITLES (gameplay plan #9) ===
// Cosmetic-only player titles granted by collection milestones. Pure flavor:
// they show under the player header on the Stats screen and are selectable in
// the Journal. No stat effects, no gameplay power. Portrait frames were
// considered for the same reward slots and deferred: the dragon portrait path
// has no frame layer, and titles deliver the same showcase with far less risk.
export const TITLES = {
  hearth_warden:    { id: 'hearth_warden',    name: 'Hearth Warden',    flavor: 'Keeper of the primal pair — fire and ice, the first sparks.' },
  wildcaller:       { id: 'wildcaller',       name: 'Wildcaller',       flavor: 'The storm, the venom, and the stone answer when called.' },
  umbral_scholar:   { id: 'umbral_scholar',   name: 'Umbral Scholar',   flavor: 'Studied the shadow long enough to be studied back.' },
  rift_walker:      { id: 'rift_walker',      name: 'Rift Walker',      flavor: 'Walked the tear in the simulation and came back changed.' },
  prismatic_warden: { id: 'prismatic_warden', name: 'Prismatic Warden', flavor: 'Every dragon, every color, every impossible shine.' },
  awakened:         { id: 'awakened',         name: 'the Awakened',     flavor: 'One bond carried all the way through the forge.' },
  ascendant:        { id: 'ascendant',        name: 'the Ascendant',    flavor: 'Three awakened dragons. Felix is taking notes.' },
  transcendent:     { id: 'transcendent',     name: 'the Transcendent', flavor: 'Every dragon fully awakened. The codex is complete.' },
};

export function getTitleName(titleId) {
  return TITLES[titleId]?.name || null;
}

// Rarity tiers come from the single gameData source of truth so milestone
// thresholds can never drift from the hatchery's actual tiers.
const tierElements = (tierName) =>
  rarityTiers.find((t) => t.name === tierName)?.elements || [];

// Fully Awakened: owned, max level, and shiny. All three, no shortcuts.
export function countFullyAwakened(save) {
  return Object.values(save.dragons || {}).filter(
    (d) => d.owned && d.level >= 50 && d.shiny,
  ).length;
}

export const MILESTONES = [
  {
    id: 'first_discovery',
    name: 'First Discovery',
    description: 'Discover any dragon',
    reward: 100,
    check: (save) => {
      // Count discovered (ever-owned), not currently-owned, so fusion never reverts it.
      const discovered = Object.values(save.dragons).filter(d => d.discovered).length;
      return { met: discovered >= 1, progress: `${discovered}/1` };
    },
  },
  {
    id: 'elemental_trio',
    name: 'Elemental Trio',
    description: 'Discover 3 different dragons',
    reward: 200,
    check: (save) => {
      const discovered = Object.values(save.dragons).filter(d => d.discovered).length;
      return { met: discovered >= 3, progress: `${discovered}/3` };
    },
  },
  {
    id: 'full_roster',
    name: 'Full Roster',
    description: 'Discover all 8 dragons',
    reward: 500,
    check: (save) => {
      const discovered = Object.values(save.dragons).filter(d => d.discovered).length;
      return { met: discovered >= 8, progress: `${discovered}/8` };
    },
  },
  {
    id: 'shiny_hunter',
    name: 'Shiny Hunter',
    description: 'Own a shiny dragon',
    reward: 300,
    check: (save) => {
      const shinies = Object.values(save.dragons).filter(d => d.owned && d.shiny).length;
      return { met: shinies >= 1, progress: `${shinies}/1` };
    },
  },
  {
    id: 'shiny_collector',
    name: 'Shiny Collector',
    description: 'Own 3 shiny dragons',
    reward: 1000,
    check: (save) => {
      const shinies = Object.values(save.dragons).filter(d => d.owned && d.shiny).length;
      return { met: shinies >= 3, progress: `${shinies}/3` };
    },
  },
  {
    id: 'shiny_completionist',
    name: 'Shiny Completionist',
    description: 'Own all 8 shiny dragons',
    reward: 2000,
    check: (save) => {
      const shinies = Object.values(save.dragons).filter(d => d.owned && d.shiny).length;
      return { met: shinies >= 8, progress: `${shinies}/8` };
    },
  },
  {
    id: 'elder_forged',
    name: 'Elder Forged',
    description: 'Raise a dragon to Lv.50',
    reward: 250,
    check: (save) => {
      const hasElder = Object.values(save.dragons).some(d => d.owned && d.level >= 50);
      return { met: hasElder, progress: hasElder ? '1/1' : '0/1' };
    },
  },
  {
    id: 'fusion_master',
    name: 'Fusion Master',
    description: 'Complete a fusion',
    reward: 200,
    check: (save) => {
      const hasFused = Object.values(save.dragons).some(d => d.owned && d.fusedBaseStats);
      return { met: hasFused, progress: hasFused ? '1/1' : '0/1' };
    },
  },
  {
    id: 'battle_veteran',
    name: 'Battle Veteran',
    description: 'Win 10 battles',
    reward: 150,
    check: (save) => {
      const wins = save.stats?.battlesWon || 0;
      return { met: wins >= 10, progress: `${Math.min(wins, 10)}/10` };
    },
  },
  {
    id: 'battle_champion',
    name: 'Battle Champion',
    description: 'Win 50 battles',
    reward: 500,
    check: (save) => {
      const wins = save.stats?.battlesWon || 0;
      return { met: wins >= 50, progress: `${Math.min(wins, 50)}/50` };
    },
  },
  {
    id: 'core_collector',
    name: 'Core Collector',
    description: 'Collect 50 element cores',
    reward: 200,
    check: (save) => {
      const cores = save.inventory?.cores || {};
      const total = Object.values(cores).reduce((sum, n) => sum + n, 0);
      return { met: total >= 50, progress: `${Math.min(total, 50)}/50` };
    },
  },
  {
    id: 'scraps_hoarder',
    name: 'DataScraps Hoarder',
    description: 'Earn 5000 total DataScraps',
    reward: 300,
    check: (save) => {
      const earned = save.stats?.totalScrapsEarned || 0;
      return { met: earned >= 5000, progress: `${Math.min(earned, 5000)}/5000` };
    },
  },
  {
    id: 'pull_addict',
    name: 'Pull Addict',
    description: 'Complete 50 hatchery pulls',
    reward: 200,
    check: (save) => {
      const pulls = save.stats?.totalPulls || 0;
      return { met: pulls >= 50, progress: `${Math.min(pulls, 50)}/50` };
    },
  },
  {
    id: 'void_hunter',
    name: 'Void Hunter',
    description: 'Obtain the Void Dragon',
    reward: 500,
    check: (save) => {
      const hasVoid = save.dragons.void?.owned;
      return { met: hasVoid, progress: hasVoid ? '1/1' : '0/1' };
    },
  },
  {
    id: 'light_bearer',
    name: 'Light Bearer',
    description: 'Obtain the Light Dragon',
    reward: 500,
    check: (save) => {
      const hasLight = !!save.dragons.light?.owned;
      return { met: hasLight, progress: hasLight ? '1/1' : '0/1' };
    },
  },
  {
    id: 'win_streak_5',
    name: 'Hot Streak',
    description: 'Win 5 battles in a row',
    reward: 250,
    check: (save) => {
      const streak = save.records?.longestStreak || 0;
      return { met: streak >= 5, progress: `${Math.min(streak, 5)}/5` };
    },
  },
  // === Daily-streak milestones (the retention chase) ===
  {
    id: 'daily_streak_7',
    name: 'Weekly Circuit',
    description: 'Hold a 7-day Daily Challenge streak',
    reward: 350,
    check: (save) => {
      const streak = save.dailyStreak || 0;
      return { met: streak >= 7, progress: `${Math.min(streak, 7)}/7` };
    },
  },
  {
    id: 'daily_streak_14',
    name: 'Fortnight Protocol',
    description: 'Hold a 14-day Daily Challenge streak',
    reward: 700,
    check: (save) => {
      const streak = save.dailyStreak || 0;
      return { met: streak >= 14, progress: `${Math.min(streak, 14)}/14` };
    },
  },
  {
    id: 'daily_streak_30',
    name: 'Persistent Signal',
    description: 'Hold a 30-day Daily Challenge streak',
    reward: 1500,
    check: (save) => {
      const streak = save.dailyStreak || 0;
      return { met: streak >= 30, progress: `${Math.min(streak, 30)}/30` };
    },
  },
  // === Post-game milestones (the endgame chase) ===
  {
    id: 'singularity_contained',
    name: 'Singularity Contained',
    description: 'Stop the Singularity',
    reward: 1000,
    check: (save) => {
      const done = !!save.singularityComplete;
      return { met: done, progress: done ? '1/1' : '0/1' };
    },
  },
  {
    id: 'mirror_shattered',
    name: 'Reflection Shattered',
    description: 'Defeat the Mirror Admin',
    reward: 1500,
    check: (save) => {
      const done = !!save.mirrorAdminDefeated;
      return { met: done, progress: done ? '1/1' : '0/1' };
    },
  },
  {
    id: 'remnants_purged',
    name: 'Remnants Purged',
    description: 'Clear all 3 Corruption Remnants',
    reward: 1000,
    check: (save) => {
      const cleared = (save.remnantDefeated || []).length;
      return { met: cleared >= 3, progress: `${Math.min(cleared, 3)}/3` };
    },
  },
  {
    id: 'synthesis_born',
    name: 'Synthesis Achieved',
    description: 'Forge the Synthesis Dragon',
    reward: 750,
    check: (save) => {
      const has = !!save.dragons.synthesis?.owned;
      return { met: has, progress: has ? '1/1' : '0/1' };
    },
  },
  {
    id: 'apex_roster',
    name: 'Apex Roster',
    description: 'Raise all 9 dragons to Stage IV (Lv.50)',
    reward: 2000,
    check: (save) => {
      const all = Object.values(save.dragons);
      const maxed = all.filter(d => d.owned && d.level >= 50).length;
      return { met: maxed >= all.length, progress: `${maxed}/${all.length}` };
    },
  },
  {
    id: 'rank_perfect',
    name: 'Rank Perfect',
    description: 'Earn an S rank on every campaign node',
    reward: 1500,
    check: (save) => {
      const campaignNpcIds = CAMPAIGN_NODES.map((node) => node.npcId);
      const total = campaignNpcIds.length;
      const sCount = campaignNpcIds.filter((id) => save.bestRanks?.[id] === 'S').length;
      return {
        met: total > 0 && sCount >= total,
        progress: `${sCount}/${total}`,
      };
    },
  },
  // --- NEW GAME+ LORE-COMPLETION CHASE (gameplay plan #8) ---
  // NG+-exclusive milestones: each check gates on save.ngPlus >= 1 so they can
  // never complete in the first loop. Rewards are lore-only — reward: 0 pays
  // no DataScraps; the reward is the Felix prose in `loreReward`, surfaced in
  // the Archive's Ascendant Record. `ngPlus: true` tags them for the Journal's
  // separate NG+ chase-track section (shown only while an NG+ run is active).
  {
    id: 'ngplus_depth_1',
    name: 'A Footstep Past the Shadow',
    description: 'In a New Game+ run, push the archive record one step deeper',
    reward: 0,
    ngPlus: true,
    loreReward: ASCENDANT_RECORD_LORE.ngplus_depth_1,
    check: (save) => {
      const depth = save.ngPlusLoreDepth || 0;
      const met = (save.ngPlus || 0) >= 1 && depth >= 1;
      return { met, progress: `${Math.min(depth, 1)}/1` };
    },
  },
  {
    id: 'ngplus_depth_3',
    name: 'The Record Deepens',
    description: 'In New Game+ runs, push the archive record 3 steps deeper',
    reward: 0,
    ngPlus: true,
    loreReward: ASCENDANT_RECORD_LORE.ngplus_depth_3,
    check: (save) => {
      const depth = save.ngPlusLoreDepth || 0;
      const met = (save.ngPlus || 0) >= 1 && depth >= 3;
      return { met, progress: `${Math.min(depth, 3)}/3` };
    },
  },
  {
    id: 'ngplus_depth_5',
    name: 'The Mirror Remembers',
    description: 'In New Game+ runs, push the archive record 5 steps deeper',
    reward: 0,
    ngPlus: true,
    loreReward: ASCENDANT_RECORD_LORE.ngplus_depth_5,
    check: (save) => {
      const depth = save.ngPlusLoreDepth || 0;
      const met = (save.ngPlus || 0) >= 1 && depth >= 5;
      return { met, progress: `${Math.min(depth, 5)}/5` };
    },
  },
  {
    id: 'ngplus_ascendant_remnants',
    name: 'Ascendant Echoes',
    description: 'In New Game+ runs, quiet all 3 Corruption Remnants a second time',
    reward: 0,
    ngPlus: true,
    loreReward: ASCENDANT_RECORD_LORE.ngplus_ascendant_remnants,
    check: (save) => {
      const need = CORRUPTION_REMNANTS.map((r) => r.id);
      const have = Array.isArray(save.ngPlusRemnantClears) ? save.ngPlusRemnantClears : [];
      const count = need.filter((id) => have.includes(id)).length;
      const met = (save.ngPlus || 0) >= 1 && count >= need.length;
      return { met, progress: `${count}/${need.length}` };
    },
  },
  // === Codex depth (gameplay plan #9): elemental attunement ===
  // Each of the six hatchery elements maps 1:1 to a dragon, so an element's
  // "completion" is discovering that dragon. Void, Light, and Synthesis are
  // deliberately excluded here — void_hunter, light_bearer, and
  // synthesis_born already grant milestones for those ids.
  {
    id: 'attune_fire',
    name: 'Flame Attunement',
    description: 'Discover the Fire Dragon',
    reward: 150,
    check: (save) => {
      const done = !!save.dragons.fire?.discovered;
      return { met: done, progress: done ? '1/1' : '0/1' };
    },
  },
  {
    id: 'attune_ice',
    name: 'Frost Attunement',
    description: 'Discover the Ice Dragon',
    reward: 150,
    check: (save) => {
      const done = !!save.dragons.ice?.discovered;
      return { met: done, progress: done ? '1/1' : '0/1' };
    },
  },
  {
    id: 'attune_storm',
    name: 'Tempest Attunement',
    description: 'Discover the Storm Dragon',
    reward: 150,
    check: (save) => {
      const done = !!save.dragons.storm?.discovered;
      return { met: done, progress: done ? '1/1' : '0/1' };
    },
  },
  {
    id: 'attune_stone',
    name: 'Bastion Attunement',
    description: 'Discover the Stone Dragon',
    reward: 150,
    check: (save) => {
      const done = !!save.dragons.stone?.discovered;
      return { met: done, progress: done ? '1/1' : '0/1' };
    },
  },
  {
    id: 'attune_venom',
    name: 'Venom Attunement',
    description: 'Discover the Venom Dragon',
    reward: 150,
    check: (save) => {
      const done = !!save.dragons.venom?.discovered;
      return { met: done, progress: done ? '1/1' : '0/1' };
    },
  },
  {
    id: 'attune_shadow',
    name: 'Shadow Attunement',
    description: 'Discover the Shadow Dragon',
    reward: 150,
    check: (save) => {
      const done = !!save.dragons.shadow?.discovered;
      return { met: done, progress: done ? '1/1' : '0/1' };
    },
  },
  // === Codex depth: rarity-tier completion ===
  // Each grants a cosmetic player title via `titleReward`, consumed at claim.
  {
    id: 'tier_common',
    name: 'Primal Pair',
    description: 'Discover all Common dragons (Fire, Ice)',
    reward: 250,
    titleReward: 'hearth_warden',
    check: (save) => {
      const ids = tierElements('Common');
      const found = ids.filter((id) => save.dragons[id]?.discovered).length;
      return { met: ids.length > 0 && found >= ids.length, progress: `${found}/${ids.length}` };
    },
  },
  {
    id: 'tier_uncommon',
    name: 'Wild Triad',
    description: 'Discover all Uncommon dragons (Storm, Venom, Stone)',
    reward: 400,
    titleReward: 'wildcaller',
    check: (save) => {
      const ids = tierElements('Uncommon');
      const found = ids.filter((id) => save.dragons[id]?.discovered).length;
      return { met: ids.length > 0 && found >= ids.length, progress: `${found}/${ids.length}` };
    },
  },
  {
    id: 'tier_rare',
    name: 'Into the Dark',
    description: 'Discover all Rare dragons (Shadow)',
    reward: 500,
    titleReward: 'umbral_scholar',
    check: (save) => {
      const ids = tierElements('Rare');
      const found = ids.filter((id) => save.dragons[id]?.discovered).length;
      return { met: ids.length > 0 && found >= ids.length, progress: `${found}/${ids.length}` };
    },
  },
  {
    id: 'tier_exotic',
    name: 'Beyond the Veil',
    description: 'Discover all Exotic dragons (Void)',
    reward: 750,
    titleReward: 'rift_walker',
    check: (save) => {
      const ids = tierElements('Exotic');
      const found = ids.filter((id) => save.dragons[id]?.discovered).length;
      return { met: ids.length > 0 && found >= ids.length, progress: `${found}/${ids.length}` };
    },
  },
  {
    id: 'shiny_perfection',
    name: 'Prismatic Set',
    description: 'Own all 9 shiny dragons',
    reward: 2500,
    titleReward: 'prismatic_warden',
    check: (save) => {
      const total = JOURNAL_DRAGON_IDS.length;
      const shinies = JOURNAL_DRAGON_IDS.filter((id) => save.dragons[id]?.owned && save.dragons[id]?.shiny).length;
      return { met: shinies >= total, progress: `${shinies}/${total}` };
    },
  },
  // === Codex depth: Fully Awakened (Lv.50 AND shiny) ===
  {
    id: 'awakened_one',
    name: 'Fully Awakened',
    description: 'Fully awaken 1 dragon (Lv.50 + shiny)',
    reward: 750,
    titleReward: 'awakened',
    check: (save) => {
      const n = countFullyAwakened(save);
      return { met: n >= 1, progress: `${Math.min(n, 1)}/1` };
    },
  },
  {
    id: 'awakened_three',
    name: 'Fully Awakened ×3',
    description: 'Fully awaken 3 dragons (Lv.50 + shiny)',
    reward: 1500,
    titleReward: 'ascendant',
    check: (save) => {
      const n = countFullyAwakened(save);
      return { met: n >= 3, progress: `${Math.min(n, 3)}/3` };
    },
  },
  {
    id: 'awakened_all',
    name: 'Fully Awakened: Complete',
    description: 'Fully awaken all 9 dragons (Lv.50 + shiny)',
    reward: 3000,
    titleReward: 'transcendent',
    check: (save) => {
      const n = countFullyAwakened(save);
      return { met: n >= JOURNAL_DRAGON_IDS.length, progress: `${Math.min(n, JOURNAL_DRAGON_IDS.length)}/${JOURNAL_DRAGON_IDS.length}` };
    },
  },
];

export function checkMilestones(save) {
  return MILESTONES.map((milestone) => {
    const claimed = save.milestones.includes(milestone.id);
    const { met, progress } = milestone.check(save);
    return {
      ...milestone,
      claimed,
      newlyClaimed: !claimed && met,
      progress,
    };
  });
}
