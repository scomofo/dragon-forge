import { moves, typeChart } from './gameData';
import { getBossPattern } from './bossPatterns';
import { HYDRA_HEAD_COUNT } from './bossMechanics';

const tip = (title, detail) => ({ title, detail });
const effectiveness = (move, element) => typeChart[move.element]?.[element] ?? 1;

function getPatternAdvice(state, battleConfig, regularMoves) {
  const id = battleConfig.isMirrorAdmin ? 'mirror_admin_reset' : state.bossPatternId;
  if (!getBossPattern(id)?.executedByBattleEngine) return null;
  const boss = state.bossState || {};

  switch (id) {
    case 'firewall_sentinel':
      return tip('Open the packet shield', 'Next attempt, Defend first, then strike on the following turn. The shield blocks attacks until you wait out that cycle.');
    case 'crypto_crab':
      if (!boss.decrypted) return tip('Crack the cipher', 'Next attempt, land the same element twice to open the damage shield. Basic Attack can do this too; damage opens on following attacks.');
      break;
    case 'glitch_hydra':
      if ((boss.headsBroken ?? 0) < HYDRA_HEAD_COUNT) return tip('Break all three heads', 'Next attempt, aim for three super-effective hits to release the 30% HP lock. Repeated elements count; watch the head counter.');
      break;
    case 'logic_bomb':
      if (boss.fuseTurns <= 1) return tip('Watch the fuse', 'Next attempt, attack while the fuse is burning. When Final Detonation is primed, Defend to reduce its damage if you cannot finish the fight.');
      break;
    case 'bit_wraith':
      if (boss.pierceNext || state.battleLog?.some(line => line.includes('phases — its next hit ignores Defend'))) {
        return tip('Watch for guard piercing', 'Next attempt, watch the enemy signal after the wraith misses. Its next hit ignores Defend, so use that turn to attack instead.');
      }
      break;
    case 'memory_leak': {
      const iceMove = regularMoves.find(move => move.element === 'ice');
      if (boss.leakPips > 0 && iceMove) return tip('Clear the defense buildup', `Next attempt, use your party's ${iceMove.name} to clear the growing DEF bonus. A landed Ice hit resets the leak even when its damage is resisted.`);
      break;
    }
    case 'data_corruption':
      if (boss.garbledMoveKey && boss.garbledTurnsLeft > 0) return tip('Check the corrupted slot', `Next attempt, watch the enemy signal: ${moves[boss.garbledMoveKey]?.name || 'a corrupted move'} fires as Basic Attack while corrupted. Choose another move when you need its usual effect.`);
      break;
    case 'stack_overflow':
      if (boss.surgeUsed) return tip('Plan around the speed burst', 'Next attempt, Defend during the two-turn speed surge when you need to survive. It guards while recovering afterward; watch for a stored charge that can fire first.');
      break;
    case 'mirror_admin_reset': {
      const technique = [state.dragon, state.bench?.dragon].flatMap(dragon => dragon?.moveKeys || [])
        .find(key => ['restoration', 'recompile'].includes(key));
      if (state.currentPhase === 2 && boss.mirrorHealPunished && technique) return tip('Seal the Great Reset', `Next attempt, save ${moves[technique].name} for phase 3. Using it in that phase prevents the Great Reset from healing the enemy when a dragon falls.`);
      break;
    }
  }
  return null;
}

// Advice describes a known rule or measured result, never an inferred cause of
// defeat. Battle history contains executed move keys, not merely selected ones.
export function getDefeatAdvice(state, battleConfig = {}) {
  if (state?.phase !== 'defeat') return null;
  const partyKeys = new Set([state.dragon, state.bench?.dragon].flatMap(dragon => dragon?.moveKeys || []));
  const regularMoves = [...partyKeys].map(key => moves[key])
    .filter(move => move?.power > 0 && !move.isSignature);
  const patternAdvice = getPatternAdvice(state, battleConfig, regularMoves);
  if (patternAdvice) return patternAdvice;

  const resisted = [...(state.playerMoveHistory || [])].reverse().map(key => moves[key])
    .find(move => move?.power > 0 && !move.copyAdvantage && effectiveness(move, state.npc?.element) < 1);
  if (resisted) return tip('Try a neutral attack', `${resisted.name} is resisted by this enemy's current element. Next attempt, compare it with Basic Attack: neutral damage has no type penalty and 100% base accuracy.`);

  if (state.npcHp > 0 && state.npcMaxHp > 0 && state.npcHp / state.npcMaxHp <= 0.2) {
    const accurate = [...regularMoves, moves.basic_attack]
      .filter(move => effectiveness(move, state.npc?.element) >= 1)
      .sort((a, b) => b.accuracy - a.accuracy || b.power - a.power)[0];
    return tip('Choose accuracy near the finish', `The enemy had ${state.npcHp} HP left. Next attempt, consider ${accurate.name} (${accurate.accuracy}% base accuracy) when it is low. Blind can still reduce accuracy.`);
  }

  return tip('Read the enemy signal', 'Next attempt, check the signal before each command. Defend reduces incoming damage; use it against a charged attack unless the signal says it ignores Defend.');
}
