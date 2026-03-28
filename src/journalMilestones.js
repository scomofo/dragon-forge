export const MILESTONES = [
  {
    id: 'first_discovery',
    name: 'First Discovery',
    description: 'Discover any dragon',
    reward: 100,
    check: (save) => {
      const owned = Object.values(save.dragons).filter(d => d.owned).length;
      return { met: owned >= 1, progress: `${owned}/1` };
    },
  },
  {
    id: 'elemental_trio',
    name: 'Elemental Trio',
    description: 'Own 3 different dragons',
    reward: 200,
    check: (save) => {
      const owned = Object.values(save.dragons).filter(d => d.owned).length;
      return { met: owned >= 3, progress: `${owned}/3` };
    },
  },
  {
    id: 'full_roster',
    name: 'Full Roster',
    description: 'Own all 6 dragons',
    reward: 500,
    check: (save) => {
      const owned = Object.values(save.dragons).filter(d => d.owned).length;
      return { met: owned >= 6, progress: `${owned}/6` };
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
    id: 'elder_forged',
    name: 'Elder Forged',
    description: 'Reach Stage IV (Lv.50+)',
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
    id: 'win_streak_5',
    name: 'Hot Streak',
    description: 'Win 5 battles in a row',
    reward: 250,
    check: (save) => {
      const streak = save.records?.longestStreak || 0;
      return { met: streak >= 5, progress: `${Math.min(streak, 5)}/5` };
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
