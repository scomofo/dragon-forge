# Magma surface, deformation and planted-foot pass

This is an implemented asset/rig pass, following the separate review-scene tools.
Concept illustrations are visual references only. All review evidence here is generated
from the exported GLB and actual Godot gameplay. It is not a final art-direction approval.

## Repainted materials

The unchanged 4 × 4 UV layout now uses four 2048² companion PNGs. Each material has
layered broad washes, recessed mineral boundaries, broken edges and fine directional
marks. Basalt uses ash and sparse hot fissures; oxide-copper scales use chipped edges;
ivory uses root staining and longitudinal striations. Copper machinery receives oxide
patches, enamel exposes worn substrate, and steel receives scuffs and dirt breakup.
Color, normal, roughness/metallic/occlusion and emission derive from the same masks.
The eye and chest remain the principal glowing shapes. No baked light or third-party
painted texture is bundled. `tools/paint_surfaces.py` is the editable, deterministic
paint recipe, not a claim of manual brush painting or unique per-character UV islands.
All existing atlas users receive these material changes; no additional biome is added.

## Deformation corrections in the actual export

Magma keeps 24 bones and the same nine named clips and combat durations. Proximal
shoulder and thigh rings now blend into chest/pelvis instead of rotating as detached
rigid sleeve ends. The jaw hinge moved to the rear mouth joint; a head-bound palate is
separate from the lower jaw, and the breath extreme is limited to 0.50 radians. Claw
reach, burst abduction and wall crouch are reduced to keep the plated masses coherent.
Sole pads are rigid to the foot rather than partially influenced by the hock.
`tools/pose_cleanup.py` bakes two-bone leg corrections into the exported animation keys:
stationary guard/attacks keep their support positions while the pelvis/torso can move.
This is weight/hinge/clip correction, not newly sculpted corrective blend shapes.

## Runtime contact contract

`presentation/foot_plant.gd` runs after imported pose sampling. Travel phase advances
from actual collider displacement, not requested speed. One full left/right cycle
covers 1.90 m; left stance is phase [0, .5), right stance [.5, 1). A swing can rise .16 m.
Stationary idle, guard and attacks retain both contacts. Moving guard/attacks continue
the lower-body step cycle instead of pinning both feet while the collider travels.

Each stance remembers a world-space sole target and foot orientation. Analytic two-bone
rotations solve thigh/hock/foot without changing bone lengths, collider motion, damage,
cooldowns or animation contact times. The solver queries actual imported deck and dais
triangles on layer 64, outside all gameplay collision masks. It targets 4 mm sole clearance.

Reach violations release a contact before clamping the leg, and a 120 ms settling step
returns it to a reachable target. Swing/release targets are kept above the visible deck.
Dodge, defeat, loss of floor contact, teleport and respawn release stale anchors. Missing
support surfaces never manufacture an invisible floor. This is tailored to the shipped
flat deck/dais, not general slope, stairs or moving-platform IK. Sharp turns can produce
small corrective steps. Foot roll, richer gait blending and final motion approval remain.

## Reproducible review

Run `validation/polish_tests.gd` with Godot 4.6.3. It checks raw exported stress poses,
actual material import, seven real controller replays, support coverage and lift/replant
windows, reduced motion, quality independence, respawn and lock release. The drift
baseline is a second hidden instance of the **same revised GLB**, sampled at identical
actor transforms and clip times without runtime IK. It is not a comparison against the
older PR's textures or mesh. Both measurements use independent CPU-skinned sole points.

Thresholds: <=15 mm horizontal displacement during an authored stance, >=-10 mm planted
surface clearance, and >=-12 mm clearance over sampled swing/turn/settle frames. Moving
replays require meaningful planted and swing coverage so disabling all contacts cannot
pass. These are finite scenario/sample tests, not proof against all mesh intersections.

The character inspector shows the baked export; the arena shows the live correction.
F11 toggles the correction only in the validation arena for direct A/B comparison.
Arena sole overlays distinguish LOCK/SWING and export authored stance drift separately
from the old proximity-derived diagnostic. `magma-polish-metrics.json` records the
loaded GLB hash, engine, paired baseline method and actual measurements.

Playing requires no build tools. Rebuilding requires the isolated pinned dependencies
in `tools/art-requirements.txt` and `python tools/build_art.py`. All exported bytes and
source hashes are recorded in `art/generated/manifest.json`. Neither game's saves or
soundtrack are touched by this pass.
