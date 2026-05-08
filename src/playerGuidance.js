function getOwnedDragons(save) {
  return Object.entries(save?.dragons || {}).filter(([, dragon]) => dragon?.owned);
}

function hasCores(save) {
  return Object.values(save?.inventory?.cores || {}).some((count) => count > 0);
}

export function getPlayerGuidance(save) {
  const ownedDragons = getOwnedDragons(save);

  if (ownedDragons.length === 0) {
    return {
      target: 'hatchery',
      action: 'FREE PULL',
      title: 'Hatch your first guardian',
    };
  }

  if ((save?.defeatedNpcs || []).length === 0) {
    return {
      target: 'map',
      action: 'FIRST BATTLE',
      title: 'Stabilize Signal Breach',
    };
  }

  if ((save?.dataScraps || 0) > 0 || hasCores(save)) {
    return {
      target: 'shop',
      action: 'SPEND REWARDS',
      title: 'Turn scraps and cores into power',
    };
  }

  const fusionReady = ownedDragons.length >= 2 && ownedDragons.some(([, dragon]) => (dragon?.level || 1) >= 10);
  if (fusionReady) {
    return {
      target: 'fusion',
      action: 'FUSE',
      title: 'Create a stronger lineage',
    };
  }

  const singularityUnlocked = (save?.flags?.currentAct || 1) >= 3 && !save?.singularityComplete;
  const hasSingularityProgress = (save?.singularityProgress?.defeated || []).length > 0;
  if (singularityUnlocked && !hasSingularityProgress) {
    return {
      target: 'singularity',
      action: 'SINGULARITY',
      title: 'Check the unstable breach',
    };
  }

  return null;
}
