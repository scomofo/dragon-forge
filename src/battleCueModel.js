import { moves, npcs, typeChart } from './gameData';
import { CHARGE_ATK_MULTIPLIER } from './battleEngine';
import { HYDRA_HEAD_COUNT } from './bossMechanics';

const name = value => value ? value[0].toUpperCase() + value.slice(1) : 'Unknown';
const cue = (id, title, detail, tone = 'warning', meter = null) => ({ id, title, detail, tone, meter });
const meter = (value, max) => ({ value, max });

function getPatternCue(state, playerDefendedLastTurn, isMirrorAdmin) {
  const bs = state.bossState || {};
  switch (state.bossPatternId) {
    case 'firewall_sentinel': {
      const canPierce = state.dragon?.moveKeys.includes('phase_strike') && !state.playerSignatureUsed?.[state.dragonId];
      return playerDefendedLastTurn
        ? cue('shield', 'Shield open', 'Your next strike can land. Attack now.', 'opening')
        : cue('shield', 'Shield closed', `Defend, then strike on the following turn.${canPierce ? ' Phase Strike also pierces.' : ''}`);
    }
    case 'buffer_overflow': {
      const heat = bs.heatStacks || 0;
      return cue('heat', `Heat ${heat}/4`, heat >= 4
        ? 'Magma Breath primed. Defend against the burst.'
        : 'At full heat, Magma Breath also burns its user.', heat >= 4 ? 'danger' : 'warning', meter(heat, 4));
    }
    case 'bit_wraith':
      return bs.pierceNext
        ? cue('phase', 'Guard piercing', state.bench?.playerHp > 0
          ? 'Its next hit ignores Defend. Strike or swap to a healthy reserve.'
          : 'Its next hit ignores Defend. Use a technique instead of guarding.', 'danger')
        : cue('phase', 'Phase watch', 'A missed enemy attack makes its next hit pierce Defend.', 'neutral');
    case 'crypto_crab':
      return bs.decrypted
        ? cue('cipher', 'Cipher broken', 'Your attacks can now deal damage.', 'opening')
        : cue('cipher', 'Encrypted', bs.prevElement
          ? `Repeat ${name(bs.prevElement)} to crack the cipher; damage opens afterward.`
          : 'Land the same element twice to open its damage shield.');
    case 'phishing_siren': {
      const turn = state.turnCount + 1;
      const nextLure = [2, 5].find(value => value >= turn);
      if (!nextLure) return cue('lure', 'Lure spent', 'Both forced-swap windows have passed.', 'opening');
      if (!(state.bench?.playerHp > 0)) return cue('lure', 'No reserve to lure', 'The forced swap needs a living reserve.', 'neutral');
      return cue('lure', nextLure === turn ? 'Lure this turn' : `Lure on turn ${nextLure}`,
        'Your reserve will be forced in, followed by Toxic Cloud.', nextLure === turn ? 'danger' : 'warning');
    }
    case 'glitch_hydra': {
      const heads = bs.headsBroken || 0;
      const weaknesses = Object.keys(typeChart).filter(element => typeChart[element][state.npc.element] > 1).map(name).join(' / ');
      return cue('heads', `Heads broken ${heads}/${HYDRA_HEAD_COUNT}`, heads >= HYDRA_HEAD_COUNT
        ? 'The 30% HP lock is gone. Finish the fight.'
        : `${weaknesses} hits break a head. Repeated elements count.`, heads >= HYDRA_HEAD_COUNT ? 'opening' : 'warning', meter(heads, HYDRA_HEAD_COUNT));
    }
    case 'logic_bomb': {
      const fuse = bs.fuseTurns ?? 6;
      return cue('fuse', fuse === 0 ? 'Detonation armed' : `Fuse ${fuse}/6`, fuse === 0
        ? 'Final Detonation is primed. Defend or finish it.'
        : 'Attack before the fuse burns out. Low HP can trigger its signature early.', fuse <= 2 ? 'danger' : 'warning', meter(fuse, 6));
    }
    case 'recursive_golem': {
      const stacks = bs.hardenStacks || 0;
      return cue('harden', `Harden ${stacks}/3`, stacks >= 3
        ? 'Tectonic Rupture primed. Prepare to Defend.'
        : 'Enemy buffs and guards build toward Tectonic Rupture.', stacks >= 3 ? 'danger' : 'warning', meter(stacks, 3));
    }
    case 'protocol_vulture':
      return cue('perch', bs.perchUsed ? 'Perch spent' : state.npcHp / state.npcMaxHp <= 0.5 ? 'Soul Drain primed' : 'Perch at half HP',
        'Soul Drain is a heavy shadow strike. Defend to soften it.', bs.perchUsed ? 'neutral' : 'warning');
    case 'data_corruption':
      return bs.garbledMoveKey && bs.garbledTurnsLeft > 0
        ? cue('garble', `${moves[bs.garbledMoveKey]?.name || 'Move'} corrupted`, `Fires as Basic Attack for ${bs.garbledTurnsLeft} more ${bs.garbledTurnsLeft === 1 ? 'use' : 'uses'}. Choose another technique.`)
        : cue('garble', state.turnCount === 0 ? 'Corruption incoming' : 'Slots clear', state.turnCount === 0
          ? 'One regular move will be replaced by Basic Attack.' : 'Your techniques have their usual effects.', 'neutral');
    case 'memory_leak': {
      const pips = bs.leakPips || 0;
      return cue('leak', `Leak ${pips}/5`, `DEF +${pips * 10}%; grows each turn. An Ice hit clears the buildup.`, pips >= 4 ? 'danger' : 'warning', meter(pips, 5));
    }
    case 'stack_overflow':
      if (bs.spdDoubleTurnsLeft > 0) return cue('surge', `Speed doubled · ${bs.spdDoubleTurnsLeft} turns`, 'Survive the surge; recovery follows.', 'danger', meter(bs.spdDoubleTurnsLeft, 2));
      if (bs.crashTurnsLeft > 0) return cue('surge', `Recovering · ${bs.crashTurnsLeft} turns`, 'It guards while recovering; a stored charge takes priority.', 'opening', meter(bs.crashTurnsLeft, 2));
      return cue('surge', bs.surgeUsed ? 'Surge spent' : 'Surge watch', bs.surgeUsed
        ? 'Its one-time speed burst has ended.' : 'The first Thunder Clap hit doubles its speed for two turns.', 'neutral');
    default:
      if (!isMirrorAdmin || state.currentPhase !== 2) return null;
      if (bs.mirrorHealPunished) return cue('reset', 'Great Reset spent', 'Its one-time KO heal has been used.', 'opening');
      if (state.phaseMoveHistory?.some(key => ['restoration', 'recompile'].includes(key))) {
        return cue('reset', 'Great Reset sealed', 'Restoration or Recompile was used this phase.', 'opening');
      }
      return cue('reset', 'Great Reset armed', 'A KO can heal it 25%. Restoration or Recompile this phase seals the reset.', 'danger');
  }
}

// Only expose committed information at decision time. Counters are dispatched
// ahead of animations, so reading them during resolution would reveal the future.
export function getBattleCues(state, { playerDefendedLastTurn = false, isMirrorAdmin = false } = {}) {
  if (state.phase !== 'playerTurn') return [];
  const cues = [];
  const npcData = npcs[state.npc.id] || state.npc;
  const charged = moves[state.npcChargedMove];
  const signatureReady = !state.signatureMoveUsed && npcData.signatureCondition
    && state.npcHp / state.npcMaxHp <= npcData.signatureCondition.hpThreshold;
  const signature = signatureReady && moves[npcData.signatureMoveKey];
  const attack = charged || signature;
  if (attack) {
    const pierces = attack.ignoreDefend || (state.bossPatternId === 'bit_wraith' && state.bossState?.pierceNext);
    cues.push(cue(charged ? 'charge' : 'signature', `${charged ? 'Charged' : 'Signature'}: ${attack.name}`,
      `${charged ? `ATK +${Math.round((CHARGE_ATK_MULTIPLIER - 1) * 100)}%. ` : ''}${pierces ? 'This attack ignores Defend.' : 'Defend to reduce incoming damage.'}`, 'danger'));
  }
  const pattern = getPatternCue(state, playerDefendedLastTurn, isMirrorAdmin);
  if (pattern) cues.push(pattern);
  return cues;
}
