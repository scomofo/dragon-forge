// @ts-nocheck
// Act I quest spine (design/quest-spine.md, Beats 1-9). Data-driven quest
// registry + state machine. Quest completion is derived from live save state
// via subtask `check` functions, so progress can never desync: a quest is
// complete exactly when its subtasks' conditions hold. `save.quests` only
// stores completion records, one-time ceremony flags, and Admin-noticed state.
import { getStageForLevel } from './battleEngine';
import { CAMPAIGN_NODES } from './campaignMap';

export function countOwnedDragons(save) {
  return Object.values(save?.dragons || {}).filter((d) => d?.owned).length;
}

export function getFireDragon(save) {
  const fire = save?.dragons?.fire;
  return fire?.owned ? fire : null;
}

export function countCores(save) {
  return Object.values(save?.inventory?.cores || {}).reduce((sum, n) => sum + (n || 0), 0);
}

// Beat 3: the first hatch is a story event, not a gacha tutorial. Each element
// names the Matrix layer its protocol stabilizes (lore-inventory.md §4).
export const ELEMENT_AWAKENING = {
  fire:   'FIRE renews. Somewhere in the Matrix, a layer flickers back to life.',
  ice:    'ICE preserves. A layer of the Matrix holds its breath — and keeps it.',
  storm:  'STORM carries the signal. The Matrix can hear itself think again.',
  stone:  'STONE anchors. A layer of the Matrix stops drifting.',
  venom:  'VENOM metabolizes. A layer of the Matrix starts digesting the rot.',
  shadow: 'SHADOW hides. A layer of the Matrix learns how to keep a secret.',
  void:   'VOID unmakes. Even the nothing has a job here.',
  light:  'LIGHT reveals. The Matrix looks at itself and does not flinch.',
};

export function getAwakeningLine(element) {
  return ELEMENT_AWAKENING[element] || ELEMENT_AWAKENING.fire;
}

function fragmentsUnlocked(save, ...ids) {
  const unlocked = save?.flags?.fragmentsUnlocked || [];
  return ids.every((id) => unlocked.includes(id));
}

export const QUESTS = [
  {
    // Beat 2 — the pinned main quest. Felix's briefing, tracked from minute one.
    id: 'dead-memory',
    beat: 2,
    title: 'Keep the rendered world from being classified as dead memory',
    giver: 'Prof. Felix',
    briefing: 'The Mirror Admin is preparing the world for deletion. The only argument it understands is a living one: hatch the guardians, hold the shelter together, and make the record show we were here.',
    availableWhen: () => true,
    subtasks: [
      {
        id: 'hatch',
        label: 'Hatch your first guardian at the Hatchery',
        target: 'hatchery',
        action: 'FREE PULL',
        why: 'A living elemental protocol is choosing you back. This is the whole job.',
        check: (s) => countOwnedDragons(s) > 0,
      },
      {
        id: 'first-battle',
        label: 'Win a battle in the Outer Grid',
        target: 'outerGrid',
        action: 'EXPLORE',
        why: 'Prove the shelter is alive. The Admin is watching the numbers.',
        check: (s) => (s?.stats?.battlesWon || 0) > 0,
      },
      {
        id: 'forge',
        label: 'Visit the Forge and hear Felix out',
        target: 'forge',
        action: 'MEET FELIX',
        why: 'Someone finally tells you the job instead of the weather.',
        check: (s) => !!s?.flags?.metFelix,
      },
    ],
    reward: { type: 'title', titleId: 'worldkeeper', text: 'Title unlocked: Worldkeeper' },
    completeText: 'Good. You exist in the record now — resident AND operator. The Admin cannot file you as dead memory anymore. — Felix',
    whatNext: 'The Matrix needs all six base elements stabilized. The campaign map is open — start at Signal Breach.',
  },
  {
    // Beat 3 — the first hatch, framed as a guardian protocol coming online.
    id: 'protocol-online',
    beat: 3,
    title: 'A protocol answers',
    giver: 'The Hatchery Ring',
    briefing: 'Guardian protocol eggs sleep inside a cable-ring matrix. They answer Skye before they answer Felix. Hatch one, and say what it is out loud: not a pet — a living elemental protocol.',
    availableWhen: (s) => countOwnedDragons(s) > 0,
    subtasks: [
      {
        id: 'witness',
        label: 'Witness the awakening',
        target: 'hatchery',
        action: 'WITNESS',
        why: 'Your first pull is a story event, not a gacha tutorial.',
        check: (s) => !!s?.quests?.seen?.['protocol-online'],
      },
    ],
    reward: null,
    completeText: 'One layer of the Elemental Matrix, back online. It chose you first. — Felix',
    whatNext: 'Felix: the Matrix needs all six base elements stabilized. The campaign map is open.',
  },
  {
    // Beat 4 — the Weaver's distress call. The docs name the Root Dragon; the
    // shipped roster has no such entity, so this beat reads your first fire
    // dragon as the Root Dragon in forced Magma-Core form (flagged bridge).
    id: 'weaver-distress',
    beat: 4,
    title: "The Weaver's distress call",
    giver: 'Prof. Felix',
    briefing: 'Distress call from the Hardware Husk — the Weaver is caught in a zero-clock rendering loop. Only a heat-core detonation breaks it. Take your fire dragon in and burn it into Magma-Core form. The docs call that dragon the Root Dragon. Maybe they are right about yours.',
    availableWhen: (s) => !!getFireDragon(s),
    subtasks: [
      {
        id: 'magma-core',
        label: 'Force your fire dragon into Magma-Core form (Stage 2, Lv. 8)',
        target: 'outerGrid',
        action: 'TRAIN',
        why: 'Evolution stops being a stat threshold — your dragon burns itself into a new shape to save a stranger.',
        check: (s) => {
          const fire = getFireDragon(s);
          return !!fire && getStageForLevel(fire.level || 1) >= 2;
        },
      },
    ],
    reward: null,
    completeText: "She doesn't talk much. She'll show you instead — her workshop is open. — Felix",
    whatNext: "The Weaver owes you her life. Her workshop is open at the Forge — and Felix has questions about your wrench.",
  },
  {
    // Beat 5 — the Forge Console holds the Captain's Log. Fragments 001/002
    // unlock on the first Forge visit (existing trigger); this quest makes
    // reading them an explicit step instead of an unread pile.
    id: 'captains-log',
    beat: 5,
    title: 'Read the record',
    giver: 'Prof. Felix',
    briefing: "The Forge Console holds the Captain's Log. Fragments 001 (The Rendered World) and 002 (The Mirror Admin) are decrypted. Read them — two minutes that reframe every battle from here on. You're not clearing monsters; you're holding a shelter together.",
    availableWhen: (s) => !!s?.flags?.metFelix,
    subtasks: [
      {
        id: 'read',
        label: "Read Captain's Log fragments 001 and 002 (Journal → Briefing)",
        target: 'journal',
        action: 'READ LOG',
        why: "Learn the world is worth saving because it's artificial, not despite it.",
        check: (s) => fragmentsUnlocked(s, '001', '002') && !!s?.flags?.journalBriefingSeen,
      },
    ],
    reward: null,
    completeText: 'Pastoral wrapper, real shelter, fraying at the edges. Now you know what the battles are for. — Felix',
    whatNext: "Fragment 003 (Skye Signal) unlocks after 3 battle wins — the log has started tracking you.",
  },
  {
    // Beat 6 — the 10mm wrench, granted narrative weight early: the one tool
    // the Mirror Admin cannot model, because it isn't digital.
    id: 'analog-bypass',
    beat: 6,
    title: 'The analog bypass',
    giver: 'Prof. Felix',
    briefing: "A 10mm wrench. Mundane, rusted, analog. The one tool the Mirror Admin cannot model — because it isn't digital. Reinforce it at the Forge. When it matters later, you'll be glad it was introduced early.",
    availableWhen: (s) => isQuestComplete(s, 'weaver-distress'),
    subtasks: [
      {
        id: 'wrench',
        label: "Upgrade Skye's wrench to Field Reinforced at the Forge",
        target: 'forge',
        action: 'UPGRADE',
        why: "The endgame's most important object, introduced in Act I.",
        check: (s) => (s?.skye?.wrenchTier || 1) >= 2,
      },
    ],
    reward: null,
    completeText: 'Analog. Unpatchable. The Admin can simulate everything except the thing in your hand. — Felix',
    whatNext: 'Felix points at the Southern Partition: a red binary curtain no dragon can burn through. The wrench can.',
  },
  {
    // Beat 7 — the Weaver speaks through her craft, so the meeting is a
    // crafting quest, not a cutscene. Her voice lives in the item description.
    id: 'friction-saddle',
    beat: 7,
    title: "The Weaver's price",
    giver: 'The Weaver',
    briefing: 'The Weaver has no spoken lines. She speaks through her craft. Bring her salvage — 3 elemental cores — and she will build you the Friction Saddle. Read the item description when she hands it over. That is her voice.',
    availableWhen: (s) => isQuestComplete(s, 'weaver-distress'),
    subtasks: [
      {
        id: 'salvage',
        label: 'Salvage 3 elemental cores for the Weaver',
        target: 'forge',
        action: 'DELIVER',
        why: 'You meet a major character through what she makes you — rarer and better than another dialogue box.',
        check: (s) => countCores(s) >= 3,
      },
    ],
    reward: { type: 'relic', relicId: 'friction_saddle', text: 'Relic earned: Friction Saddle' },
    completeText: 'Practical. Warm. Precise about grip and drift and surviving a dive. — The Weaver, via the item description',
    whatNext: 'The saddle is the key to the Southern Partition Gate dive. The gate is the key to what comes next.',
  },
  {
    // Beat 8 — the Great Breakout, Act I finale. The Recursive Gate node is
    // the Southern Partition Gate: a permission check, not a wall.
    id: 'southern-partition',
    beat: 8,
    title: 'The Great Breakout',
    giver: 'Prof. Felix',
    briefing: 'The path forward is blocked by the Southern Partition Gate — a red binary curtain, a permission check, not a wall. The Mirror Admin is dispatching Sub-routine Stalkers: wireframe Ghost Dragons that leech compile data off your dragon. Survive the chase, find the rusted physical access port, and pry it open with the 10mm wrench. It cannot patch the breach — it isn\'t digital.',
    availableWhen: (s) => isQuestComplete(s, 'analog-bypass') && isQuestComplete(s, 'friction-saddle'),
    subtasks: [
      {
        id: 'gate',
        label: 'Breach the Southern Partition Gate — defeat the Recursive Golem',
        target: 'map',
        action: 'BREAK OUT',
        why: "Dragon magic, system logic, and physical hardware solve different problems. You need all three — that's the game's thesis in one set piece.",
        check: (s) => (s?.defeatedNpcs || []).includes('recursive_golem'),
      },
    ],
    reward: null,
    completeText: "You beat a god with a wrench. The jungle is behind you. Don't look back. — Felix",
    whatNext: 'White-out on the horizon. Felix warns you about the purge cycle. Find a Physical Relay.',
  },
  {
    // Beat 9 — the first bounty kill. The Admin adds Skye to its threat model;
    // rollback ambushes begin (bridge: re-corrupting cleared nodes).
    id: 'threat-model',
    beat: 9,
    title: 'Noticed',
    giver: 'Prof. Felix',
    briefing: 'Bank a bounty — any boss relic drop. Then listen to Felix. The Admin will have noticed you properly, and the difficulty curve is about to get a narrator.',
    availableWhen: (s) => isQuestComplete(s, 'southern-partition'),
    subtasks: [
      {
        id: 'bounty',
        label: 'Bank your first bounty (a boss relic drop)',
        target: 'map',
        action: 'HUNT',
        why: "You're not hunting anymore. You're being hunted back.",
        check: (s) => (s?.skye?.bountiesCleared || 0) >= 1,
      },
    ],
    reward: { type: 'threat', text: 'The Admin has added Skye to its threat model' },
    completeText: 'First bounty banked. That means the Admin has noticed you properly. Congratulations, unfortunately. — Felix',
    whatNext: "The Admin's attention follows you from here. It stops hiding the machine. Watch cleared nodes — rollback ambushes have begun.",
  },
];

export function getQuestById(id) {
  return QUESTS.find((q) => q.id === id) || null;
}

export function isQuestComplete(save, questId) {
  return (save?.quests?.completed || []).includes(questId);
}

export function getQuestProgress(quest, save) {
  const subtasks = quest.subtasks.map((st) => ({ ...st, done: !!st.check(save) }));
  const done = subtasks.every((st) => st.done);
  const available = quest.availableWhen(save);
  const completed = isQuestComplete(save, quest.id);
  const status = completed || done ? 'complete' : available ? 'active' : 'locked';
  return { quest, subtasks, done, available, completed, status, doneCount: subtasks.filter((s) => s.done).length, total: subtasks.length };
}

export function getAvailableQuests(save) {
  return QUESTS.map((q) => getQuestProgress(q, save)).filter((p) => p.status !== 'locked');
}

// The pinned quest: the first incomplete quest in spine order. Its first
// incomplete subtask drives the guidance chip's what-next.
export function getTrackedQuest(save) {
  const ordered = QUESTS.map((q) => getQuestProgress(q, save));
  return ordered.find((p) => p.status === 'active') || null;
}

export function getTrackedStep(save) {
  const tracked = getTrackedQuest(save);
  if (!tracked) return null;
  const step = tracked.subtasks.find((st) => !st.done);
  if (!step) return null;
  return { quest: tracked.quest, step, progress: tracked };
}

// Applies completion to a (mutable) save: records completion, grants the
// reward, and for the Act I finale arms the Admin's threat model.
export function applyQuestCompletion(save, quest) {
  if (!save.quests) save.quests = { completed: [], seen: {}, recorrupted: [], adminNoticed: false };
  if (!save.quests.completed.includes(quest.id)) save.quests.completed.push(quest.id);
  const reward = quest.reward;
  let rewardText = null;
  if (reward?.type === 'title') {
    if (!Array.isArray(save.titles)) save.titles = [];
    if (!save.titles.includes(reward.titleId)) save.titles.push(reward.titleId);
    if (!save.equippedTitle) save.equippedTitle = reward.titleId;
    rewardText = reward.text;
  } else if (reward?.type === 'relic') {
    if (!save.skye) save.skye = {};
    if (!Array.isArray(save.skye.relicsOwned)) save.skye.relicsOwned = [];
    if (!save.skye.relicsOwned.includes(reward.relicId)) save.skye.relicsOwned.push(reward.relicId);
    rewardText = reward.text;
  } else if (reward?.type === 'threat') {
    save.quests.adminNoticed = true;
    const ambushed = rollRecorruption(save);
    rewardText = ambushed.length > 0
      ? `${reward.text} — rollback detected at ${ambushed.length} cleared ${ambushed.length === 1 ? 'node' : 'nodes'}`
      : reward.text;
  }
  return rewardText;
}

// Beat 9 bridge: once the Admin notices Skye, rollback ambushes begin — a few
// cleared campaign nodes re-corrupt until re-cleared. One roll per completion
// (no farming loop): up to 2 cleared nodes, chosen by the provided rng.
export function rollRecorruption(save, rng = Math.random) {
  if (!save.quests) save.quests = { completed: [], seen: {}, recorrupted: [], adminNoticed: false };
  if (!Array.isArray(save.quests.recorrupted)) save.quests.recorrupted = [];
  const cleared = CAMPAIGN_NODES
    .filter((n) => (save.defeatedNpcs || []).includes(n.npcId))
    .filter((n) => !save.quests.recorrupted.includes(n.npcId))
    .map((n) => n.npcId);
  // Fisher-Yates with the injected rng so tests are deterministic.
  for (let i = cleared.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [cleared[i], cleared[j]] = [cleared[j], cleared[i]];
  }
  const picked = cleared.slice(0, 2);
  save.quests.recorrupted.push(...picked);
  return picked;
}

export function isRecorrupted(save, npcId) {
  return (save?.quests?.recorrupted || []).includes(npcId);
}

export function clearRecorruption(save, npcId) {
  if (!Array.isArray(save?.quests?.recorrupted)) return false;
  const idx = save.quests.recorrupted.indexOf(npcId);
  if (idx === -1) return false;
  save.quests.recorrupted.splice(idx, 1);
  return true;
}
