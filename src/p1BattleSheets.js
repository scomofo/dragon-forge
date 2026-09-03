// P1 battle-actor paths. gameData.battleSheet in the art drop wires these.
// Copy snes-aaa-p1/dragons/*_stage3_battle.webp into public/assets/dragons/.
import { assetUrl } from './utils';

export const P1_BATTLE_SHEETS = {
  fire: assetUrl('/assets/dragons/fire_stage3_battle.png'),
  ice: assetUrl('/assets/dragons/ice_stage3_battle.png'),
  storm: assetUrl('/assets/dragons/storm_stage3_battle.png'),
};
