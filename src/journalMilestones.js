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
