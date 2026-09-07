# Reconnection: first guardian pair

This pass adds an earned second playable guardian to the existing 22-room campaign.
It does not replace the campaign with an inspection room, erase progression, add
new biomes, or modify either original game or soundtrack.

## Earn Rime

Restore the Outer Grid core. Enter Frozen Cache and defeat the Thaw Guardian in
Thaw Junction. Take the west side passage to **Frozen Vault**, approach the egg
on the right-hand cyan plinth and press **E / B**. The egg rescue saves immediately.
Return to the Forge, approach the right-hand **Guardian Nursery** and press E / B
to hatch. It costs no salvage and adds Rime alongside Magma. The rescue/recruitment
are idempotent: neither repeated input nor revisiting the room duplicates rewards.

The optional room stays accessible to existing saves, even after its cache or
entire campaign was completed. No restart is required. **P / Guardians** shows the
recruitment route and owned guardian kits. The existing M route map is unchanged.

## Combat roles

Magma retains the previous fire kit and all thermal-relay interactions.
Rime is the Ice Dragon, a distinct low faceted quadruped with a dorsal crystal row,
not a rescaled/recolored Magma. Its health starts at 108 before shared upgrades.

| Slot | Rime technique | Base effect |
|---|---|---|
| 1 | Frost Bite | 18 damage, no heat, 0.55 second cooldown |
| 2 | Rime Lance | Narrow 8 m cone, 30 damage, 20 heat, 2.8 second cooldown; chills on a landed hit |
| 3 | Permafrost | 3.6-second field, 8 damage per 0.6-second tick, 30 heat; chills on landed ticks |
| 4 | Crystal Aegis | 55% damage reduction for Rime for 4 seconds, 36 heat, 10-second cooldown |

A chill lasts 3 seconds and reduces enemy **pursuit movement**, not its tell/contact
clock. A direct Magma hit consumes chill for 40% bonus damage. Fire fields do not
consume chill. Closed shields still block both damage and new cold application;
there is no silent shield bypass. Effects use the real actor's contact events.
Aegis does not transfer to Magma and its duration expires while Rime is in reserve.

Existing Forge upgrades and modules affect both guardians; the ability cards
show the resulting damage/heat rather than only the base values. Repair charges
are shared and heal only the active guardian. Ice cannot power thermal relays;
use Magma or rest/return to the Forge if Magma is down.

## Swapping and recovery

**Tab**, **right-stick click**, or the reserve HUD button swaps the active guardian.
There is a shared 2.5-second swap cooldown. An active technique or dodge must finish
first; overlays, focus pause, entry grace and unhatched state reject swaps. Only one
guardian is active on the field. The reserve does not fight autonomously.

Each guardian has independent HP, heat, cooldowns and temporary protection. Swapping
never heals, revives, resets a move cooldown or teleports the collision body. Reserve
cooldowns and heat recover with simulation time; reserve HP does not regenerate.
Persistent fields retain their caster and snapshotted damage after a swap.

When the active guardian falls, a living reserve takes over without being healed.
Only both guardians falling opens party defeat. A shelter, the Forge or checkpoint
retry revives and restores the party. Moving between unsafe rooms preserves both
health/resource states and cancels pending old-room attacks without refunds.

## Persistence

Campaign schema 2 adds `guardians`, `active_guardian`, and `ice_rescued`. Valid schema
1 campaigns migrate in memory with exactly Magma owned; no sector progress,
upgrade, cache or currency is invented. Loading does not write. The next successful
save backs up the previous file bytes through the existing store. Unknown future
versions and malformed ownership are blocked. The earlier prototype/browser saves
are untouched. Active-room combat state still is not serialized: Continue restores
health at the saved room entrance, as in the previous campaign.

## Art and presentation

`campaign/guardians/` ships two new GLBs and four 1024-square texture maps.
`tools/build_ice_guardian.py` is offline source using the existing glTF compiler.
Rime has 3,898 triangles, 21 skin joints and nine sampled clips; the egg has 164
triangles. The original fifteen exports and their shared textures are unchanged.
Playing requires no authoring step, Python, Node or external service.

Rime's four contact chains use a separate distance-driven diagonal gait adapted
from the existing Magma foot solver. It targets the current flat deck/dais surfaces,
not arbitrary stairs, slopes or moving platforms. The inspector now offers Rime
with correct head/hip camera framing and four independent sole probes. Studio
walk remains in place and cannot certify travelling foot contact. The gameplay
regression samples actual skinned sole points against live surface queries.

This is an initial authored/parametric Ice asset, not final sculpted character art.
The cinematic concept images are not screenshots of this implementation. No
fusion, evolution, larger roster, simultaneous companion AI, audio integration or
standalone executable is included. Numerical balance and target-hardware/controller
feel still require human playtesting; passing automated checks does not establish fun.

## Verify

Use Godot **4.6.3 Standard** (the pinned test version). From the project folder:

```
godot --headless --path . --editor --import
godot --headless --path . --script res://campaign/tests/party_tests.gd -- --test-mode
godot --path . --rendering-method gl_compatibility --script res://campaign/tests/party_capture.gd -- --test-mode
```

The existing campaign, prototype, art, review and Magma-polish regressions remain.
Party tests cover rescue/hatch, schema migration and byte-preserving backup,
resource continuity, actual Ice contacts, shields/chill/shatter, field ownership,
ward expiry, pause, knockout handoff and full-party recovery. Visual setup seeds
prerequisites to inspect each state: it is not a claim of an unassisted playthrough.
