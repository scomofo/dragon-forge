// @ts-nocheck
import { assetUrl } from './utils';

// === ELEMENTS ===
export const ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow', 'void', 'light'];
export const JOURNAL_DRAGON_IDS = [...ELEMENTS, 'synthesis'];

// === TYPE EFFECTIVENESS ===
// typeChart[attacker][defender] = multiplier
export const typeChart = {
  fire:   { fire: 0.5, ice: 2.0, storm: 1.0, stone: 0.5, venom: 2.0, shadow: 1.0, void: 1.0, light: 1.0, synthesis: 1.0 },
  ice:    { fire: 0.5, ice: 0.5, storm: 2.0, stone: 1.0, venom: 1.0, shadow: 2.0, void: 1.0, light: 1.0, synthesis: 1.0 },
  storm:  { fire: 1.0, ice: 0.5, storm: 0.5, stone: 2.0, venom: 1.0, shadow: 0.5, void: 2.0, light: 1.0, synthesis: 1.0 },
  stone:  { fire: 2.0, ice: 1.0, storm: 0.5, stone: 0.5, venom: 2.0, shadow: 1.0, void: 1.0, light: 1.0, synthesis: 1.0 },
  venom:  { fire: 0.5, ice: 1.0, storm: 1.0, stone: 0.5, venom: 0.5, shadow: 2.0, void: 1.0, light: 2.0, synthesis: 1.0 },
  shadow: { fire: 1.0, ice: 0.5, storm: 2.0, stone: 1.0, venom: 0.5, shadow: 0.5, void: 2.0, light: 2.0, synthesis: 2.0 },
  void:   { fire: 1.0, ice: 1.0, storm: 1.0, stone: 2.0, venom: 1.0, shadow: 0.5, void: 1.0, light: 2.0, synthesis: 0.5 },
  light:  { fire: 1.0, ice: 1.0, storm: 1.0, stone: 1.0, venom: 2.0, shadow: 2.0, void: 0.5, light: 1.0, synthesis: 0.5 },
  synthesis: { fire: 1.0, ice: 1.0, storm: 1.0, stone: 1.0, venom: 1.0, shadow: 1.0, void: 2.0, light: 2.0, synthesis: 1.0 },
};

// === STAGE MULTIPLIERS ===
export const stageMultipliers = { 1: 0.6, 2: 0.8, 3: 1.0, 4: 1.2 };

// === STAGE THRESHOLDS ===
export const stageThresholds = { 2: 8, 3: 20, 4: 38 };

// === MOVES ===
export const moves = {
  // Fire
  magma_breath:     { name: 'Magma Breath',     element: 'fire',   power: 65, accuracy: 95, vfxKey: 'MAGMA_BREATH', canApplyStatus: true },
  flame_wall:       { name: 'Flame Wall',        element: 'fire',   power: 55, accuracy: 100, vfxKey: 'FLAME_WALL', canApplyStatus: true },
  // Ice
  frost_bite:       { name: 'Frost Bite',        element: 'ice',    power: 60, accuracy: 100, vfxKey: 'FROST_BITE', canApplyStatus: true },
  blizzard:         { name: 'Blizzard',          element: 'ice',    power: 70, accuracy: 85, vfxKey: 'BLIZZARD', canApplyStatus: true, canCharge: true, chargeChance: 0.45 },
  // Storm
  lightning_strike: { name: 'Lightning Strike',  element: 'storm',  power: 70, accuracy: 90, vfxKey: 'LIGHTNING_STRIKE', canApplyStatus: true, canCharge: true, chargeChance: 0.40 },
  thunder_clap:     { name: 'Thunder Clap',      element: 'storm',  power: 55, accuracy: 100, vfxKey: 'THUNDER_CLAP', canApplyStatus: true },
  // Stone
  rock_slide:       { name: 'Rock Slide',        element: 'stone',  power: 60, accuracy: 95, vfxKey: 'ROCK_SLIDE', canApplyStatus: true },
  earthquake:       { name: 'Earthquake',        element: 'stone',  power: 75, accuracy: 85, vfxKey: 'EARTHQUAKE', canApplyStatus: true, canCharge: true, chargeChance: 0.50 },
  // Venom
  acid_spit:        { name: 'Acid Spit',         element: 'venom',  power: 60, accuracy: 100, vfxKey: 'ACID_SPIT', canApplyStatus: true },
  toxic_cloud:      { name: 'Toxic Cloud',       element: 'venom',  power: 70, accuracy: 85, vfxKey: 'TOXIC_CLOUD', canApplyStatus: true, canCharge: true, chargeChance: 0.40 },
  // Shadow
  shadow_strike:    { name: 'Shadow Strike',     element: 'shadow', power: 65, accuracy: 95, vfxKey: 'SHADOW_STRIKE', canApplyStatus: true },
  void_pulse:       { name: 'Void Pulse',        element: 'shadow', power: 75, accuracy: 85, vfxKey: 'VOID_PULSE', canApplyStatus: true, canCharge: true, chargeChance: 0.45 },
  // Void
  void_rift:      { name: 'Void Rift',      element: 'void',  power: 80, accuracy: 80, vfxKey: 'VOID_RIFT', canApplyStatus: true, canCharge: true, chargeChance: 0.55 },
  null_reflect:   { name: 'Null Reflect',    element: 'void',  power: 0,  accuracy: 100, vfxKey: 'NULL_REFLECT', canApplyStatus: false, isReflect: true },
  // Light
  radiant_beam:  { name: 'Radiant Beam',  element: 'light', power: 65, accuracy: 95,  vfxKey: 'RADIANT_BEAM',  canApplyStatus: true },
  solar_flare:   { name: 'Solar Flare',   element: 'light', power: 70, accuracy: 85,  vfxKey: 'SOLAR_FLARE',   canApplyStatus: true, canCharge: true, chargeChance: 0.40 },
  // Neutral
  basic_attack:     { name: 'Basic Attack',      element: 'neutral', power: 40, accuracy: 100, vfxKey: 'BASIC_ATTACK', canApplyStatus: false },
  // Player signature techniques — unique actions, not just a bigger number.
  // Once per battle. The real combat decision the two-move kit was missing.
  heartforge:       { name: 'Heartforge',     element: 'fire',   power: 0,  accuracy: 100, vfxKey: 'HEARTFORGE',       actionType: 'buff', buffStat: 'atk', buffMultiplier: 1.35, buffDuration: 2, isSignature: true },
  absolute_zero:    { name: 'Absolute Zero',  element: 'ice',    power: 40, accuracy: 100, vfxKey: 'ABSOLUTE_ZERO',    canApplyStatus: true, applyChance: 1, isSignature: true },
  overclock:        { name: 'Overclock',      element: 'storm',  power: 50, accuracy: 100, vfxKey: 'LIGHTNING_STRIKE', canApplyStatus: true, applyChance: 1, isSignature: true },
  bastion:          { name: 'Bastion',        element: 'stone',  power: 0,  accuracy: 100, vfxKey: 'ROCK_SLIDE',       actionType: 'defendPlus', defBuff: 1.4, defDuration: 2, isSignature: true },
  hemotoxin:        { name: 'Hemotoxin',      element: 'venom',  power: 45, accuracy: 100, vfxKey: 'TOXIC_CLOUD',      canApplyStatus: true, applyChance: 1, isSignature: true },
  phase_strike:     { name: 'Phase Strike',   element: 'shadow', power: 55, accuracy: 100, vfxKey: 'SHADOW_STRIKE',    ignoreDefend: true, canApplyStatus: false, isSignature: true },
  siphon_rift:      { name: 'Siphon Rift',    element: 'void',   power: 60, accuracy: 90,  vfxKey: 'VOID_RIFT',        lifesteal: 0.4, canApplyStatus: true, isSignature: true },
  restoration:      { name: 'Restoration',    element: 'light',  power: 0,  accuracy: 100, vfxKey: 'SOLAR_FLARE',      actionType: 'heal', healPercent: 0.25, cleanse: true, isSignature: true },
  recompile:        { name: 'Recompile',      element: 'synthesis', power: 70, accuracy: 90,  vfxKey: 'VOID_RIFT',        copyAdvantage: true, canApplyStatus: true, isSignature: true },
  // NPC-only buff moves
  npc_focus:   { name: 'Focus',   actionType: 'buff', buffStat: 'atk', buffMultiplier: 1.3, buffDuration: 1, vfxKey: 'BASIC_ATTACK', accuracy: 100, power: 0, canApplyStatus: false },
  npc_harden:  { name: 'Harden',  actionType: 'buff', buffStat: 'def', buffMultiplier: 1.4, buffDuration: 2, vfxKey: 'BASIC_ATTACK', accuracy: 100, power: 0, canApplyStatus: false },
  // NPC-only signature moves
  golem_rupture:    { name: 'Tectonic Rupture', element: 'stone',  power: 95, accuracy: 90, vfxKey: 'EARTHQUAKE',       canApplyStatus: true,  canCharge: true, chargeChance: 0.70 },
  vulture_drain:    { name: 'Soul Drain',        element: 'shadow', power: 90, accuracy: 90, vfxKey: 'VOID_PULSE',       canApplyStatus: true },
  hydra_overcharge: { name: 'Arc Overload',      element: 'storm',  power: 85, accuracy: 85, vfxKey: 'LIGHTNING_STRIKE', canApplyStatus: true },
  bomb_detonation:  { name: 'Final Detonation',  element: 'fire',   power: 90, accuracy: 85, vfxKey: 'MAGMA_BREATH',     canApplyStatus: false },
  wraith_unravel:   { name: 'Void Unravel',      element: 'void',   power: 85, accuracy: 90, vfxKey: 'VOID_RIFT',        canApplyStatus: true },
};
