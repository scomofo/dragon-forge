# ADR-0011: Corruption Rendering Pipeline

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Rendering / UI / Accessibility |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/rendering.md`; `docs/engine-reference/godot/deprecated-apis.md`; `design/art/art-bible.md`; `design/accessibility-requirements.md`; `design/ux/hud.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 rendering backend awareness; Godot Compositor/CompositorEffect pattern for screen post-processing; Godot 4.6 glow-before-tonemapping behavior; Shader Baker as a recommended production optimization |
| **Verification Required** | Verify corruption effects on Forward+/desktop and OpenGL3 Compatibility fallback, reduced-motion/reduced-flash settings, HUD/readability contrast, color-independent communication, restored gold-code layering, and performance against 60fps/16.6ms budget. |

Godot 4.6 changed rendering defaults and glow behavior. This ADR avoids deprecated manual viewport post-process chains and treats corruption effects as a controlled rendering/profile pipeline rather than ad hoc per-screen shader hacks.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 Semantic Event Contracts; ADR-0003 Input Router Semantic Actions; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries; ADR-0010 Singularity Boss And Ending Orchestration |
| **Enables** | Corruption visual implementation stories; restored gold-code overlay stories; SCAR visual evidence; Mirror Admin phase presentation; post-game rendering stories |
| **Blocks** | Any story implementing CRITICAL/BREACH screen filters, SCAR overlays, restored gold-code shader, corruption HUD presentation, or ending-specific post-game overlays |
| **Ordering Note** | This ADR depends on Singularity's owned corruption/ending state but is presentation-only and must not mutate gameplay state. |

## Context

### Problem Statement

Singularity defines corruption classes, SCAR node visuals, Mirror Admin phase presentation, and restored gold-code post-game overlays. Architecture review flagged this as a gap because no decision owned how Godot 4.6 rendering should apply these effects without harming readability, accessibility, or performance.

Without a rendering ADR, implementers may add manual viewport chains, mutate gameplay state from visual effects, or create inconsistent corruption presentations across Campaign Map, Battle, Hub, Hatchery, and post-game screens.

### Constraints

- Rendering is presentation-only and must not own or mutate gameplay state.
- Singularity owns `corruption_class` and `ending_id`.
- Campaign Map owns map traversal and SCAR node behavior, but rendering owns SCAR visuals.
- UI/HUD must remain readable with gamepad-first focus indicators.
- Color cannot carry required meaning alone.
- Reduced-motion and reduced-flash settings must suppress aggressive glitch/pulse effects.
- Target is PC at 60fps with a 16.6ms frame budget and 500 draw-call budget.
- Godot 4.6 uses D3D12 by default on Windows; project preferences currently specify Vulkan primary and OpenGL3 compatibility fallback, so rendering stories must verify configured backend behavior.

### Requirements

- Define a single corruption presentation pipeline shared by screens.
- Route state changes from semantic events and snapshots, not polling live mutable SaveData.
- Use typed authored profile Resources for corruption and post-game visual profiles.
- Use Godot 4 Compositor/CompositorEffect for screen post-processing where global screen effects are required.
- Use CanvasItem/ShaderMaterial overlays for sprite-specific effects such as restored gold-code.
- Preserve HUD text, icons, and focus indicators above world corruption effects.
- Provide accessibility and performance validation criteria.

## Decision

Dragon Forge will implement corruption and post-game rendering through a presentation-only `CorruptionPresentationService` plus authored profile Resources. It subscribes to committed semantic events and reads save snapshots on screen entry. It never writes SaveData.

### Rendering Layers

Rendering is separated into four layers:

1. **World layer**: map tiles, environment, battle background, hub background.
2. **Entity layer**: dragons, NPCs, enemies, interactable props.
3. **Screen effect layer**: corruption filters, scanlines, desaturation, pixel noise, hardware-substrate exposure.
4. **UI/HUD layer**: text, icons, focus rings, action menus, terminal readouts.

The UI/HUD layer must render above corruption screen effects. Corruption may frame, tint, or border the HUD only through explicit UI theme states; global world filters must not reduce HUD contrast below the accessibility baseline.

### Service API

```gdscript
class_name CorruptionPresentationService
extends RefCounted

signal corruption_profile_applied(payload: CorruptionProfileAppliedPayload)
signal post_game_profile_applied(payload: PostGameProfileAppliedPayload)

func configure(profile_library: CorruptionProfileLibrary, accessibility: AccessibilitySettings) -> void
func apply_snapshot(snapshot: SaveSnapshot, screen_id: StringName) -> PresentationApplyResult
func on_corruption_class_changed(payload: CorruptionChangedPayload) -> PresentationApplyResult
func on_ending_resolved(payload: EndingResolvedPayload) -> PresentationApplyResult
func get_profile(corruption_class: StringName, screen_id: StringName) -> CorruptionVisualProfile
func get_post_game_profile(ending_id: StringName, screen_id: StringName) -> PostGameVisualProfile
```

The service is injectable into presentation screens. Feature gameplay systems may emit semantic events, but they must not call rendering internals directly.

### Authored Profile Resources

```gdscript
class_name CorruptionProfileLibrary
extends Resource

@export var corruption_profiles: Array[CorruptionVisualProfile]
@export var post_game_profiles: Array[PostGameVisualProfile]
```

```gdscript
class_name CorruptionVisualProfile
extends Resource

@export var corruption_class: StringName
@export var screen_id: StringName
@export var compositor_profile_id: StringName
@export var shader_profile_id: StringName
@export var ui_theme_state_id: StringName
@export var scar_overlay_id: StringName
@export var reduced_motion_variant_id: StringName
@export var reduced_flash_variant_id: StringName
```

```gdscript
class_name PostGameVisualProfile
extends Resource

@export var ending_id: StringName
@export var screen_id: StringName
@export var world_profile_id: StringName
@export var dragon_overlay_shader_id: StringName
@export var terminal_profile_id: StringName
@export var ui_theme_state_id: StringName
```

Required IDs must validate at boot/content-lock time. Profiles are immutable authored content.

### Godot Rendering Pattern

Global full-screen corruption effects use the Godot 4 Compositor/CompositorEffect pattern where a screen-wide post-process is required on supported renderers.

The OpenGL3 Compatibility fallback must use reduced presentation variants that do not require `CompositorEffect`, such as a screen-space CanvasItem shader overlay, WorldEnvironment adjustments where available, palette/material swaps, scanline UI overlay, and per-tile/per-sprite material states. This fallback is intentionally simpler than the Forward+ profile, but it must preserve the same semantic class mapping and accessibility guarantees. Manual chained Viewport post-processing remains forbidden for MVP corruption effects.

Sprite and tile overlays use CanvasItem-compatible ShaderMaterial profiles or material overrides applied by presentation nodes. Restored gold-code is a sprite/entity overlay, not a global post-process.

Rendering stories must account for these Godot 4.6 facts:

- D3D12 is the default Windows rendering backend in Godot 4.6; configured project backend must be verified.
- Rendering implementation must distinguish Godot rendering method from graphics backend. Forward+ is the primary desktop rendering method. On Windows, Godot 4.6 defaults to D3D12 unless project settings explicitly select Vulkan. If Vulkan is required by project technical preferences, `project.godot` must pin that backend and rendering QA must capture evidence on the pinned backend plus OpenGL3 Compatibility fallback.
- Glow processes before tonemapping in 4.6, so gold-code and corruption glows need screenshot validation under final tonemap settings.
- GDScript/material API texture parameters should use the current Godot texture base types where applicable; shader-language sampler uniforms remain written in normal `.gdshader` sampler syntax.
- Shader Baker should be evaluated before production content lock if shader variants cause startup hitching.

### Corruption Class Mapping

| Class | Rendering Profile |
|---|---|
| NOMINAL | No corruption post-process. Normal art profile. |
| ANOMALY | Brief edge pixel shear and optional HAZARD icon reveal theme. No persistent heavy filter. |
| WARNING | HAZARD battle-start enemy outline and battle-intro corruption accent. |
| ALERT | SCAR overlay materials for authored REST/LORE nodes; no global readability degradation. |
| CRITICAL | Screen/world desaturation, pixel noise, unstable scanline cadence, battle border corruption. |
| BREACH | Hardware-substrate profile: exposed circuitry, server-rack silhouettes, phosphor glow, broken sky geometry. |

Class profiles are screen-scoped. A global profile may be used for simplicity, but each screen applies the profile through its presentation adapter so UI/HUD ordering remains correct.

### SCAR Nodes

SCAR visuals are Campaign Map presentation overlays driven by Singularity-owned `scar_nodes[]`. SCAR overlays must:

- Remove the normal functional node icon.
- Display corrupted tile/static treatment.
- Preserve traversability indicators when the node is a bridge.
- Avoid modal pop-ups for new SCAR nodes.
- Provide screenshot evidence before visual acceptance.

Campaign Map owns whether the node triggers content; rendering owns only visual treatment.

### Restored Gold-Code Overlay

After `ending_id != ""`, all dragon sprites receive the restored gold-code overlay in roster, battle, hatchery, and post-game detail views.

Layering order:

```text
base sprite -> shiny tint (if is_shiny) -> restored_gold_code overlay -> UI labels/focus
```

The overlay has no stat effect and must be visually distinct from shiny. It must preserve element silhouette, shiny marker readability, stage badge readability, and HP/status UI.

### Accessibility

Corruption and post-game rendering must follow the Standard tier in `design/accessibility-requirements.md`.

- Color never communicates corruption class, Counter readiness, SCAR state, HP danger, or ending state alone.
- HUD corruption indicator includes text or accessible labels.
- Reduced-motion mode suppresses camera shake, heavy scanline cadence shifts, and aggressive glitch motion.
- Reduced-flash mode suppresses full-screen white pulses and intense impact flashes.
- Audio degradation cannot be the only signal of corruption stage.
- Focus ring and confirm/cancel affordances remain visible above all effects.

## Architecture Diagram

```text
Singularity post-commit events / SaveSnapshot
        |
        v
CorruptionPresentationService
        |
        +-> CorruptionProfileLibrary Resources
        +-> Screen presentation adapters
              |
              +-> World/entity materials
              +-> Compositor/CompositorEffect screen profile
              +-> UI theme state above effects
```

## Alternatives Considered

### Per-screen ad hoc shaders

- **Description**: Each screen implements its own corruption shaders and post-game overlays.
- **Pros**: Fast local implementation.
- **Cons**: Inconsistent class mapping, duplicated accessibility checks, and difficult performance tuning.
- **Rejection Reason**: Corruption is a global presentation language and needs one profile library.

### Manual viewport post-process chains

- **Description**: Screens render to custom Viewports and chain shader passes manually.
- **Pros**: Familiar older Godot approach.
- **Cons**: The local Godot 4.6 reference warns against manual viewport chains for post-processing; it complicates UI ordering and backend testing.
- **Rejection Reason**: Use Compositor/CompositorEffect for structured post-processing on supported renderers and reduced CanvasItem/material fallback profiles for Compatibility.

### Gameplay systems apply rendering effects directly

- **Description**: Singularity, Campaign Map, or Battle Engine directly changes screen materials.
- **Pros**: Fewer abstraction layers.
- **Cons**: Couples gameplay state ownership to presentation implementation and risks save/render feedback loops.
- **Rejection Reason**: Presentation subscribes to semantic state; gameplay does not own rendering.

## Consequences

### Positive

- TR-sing-005 has a concrete architecture owner.
- Visual effects are consistent across screens.
- Accessibility and HUD readability are built into the rendering contract.
- Godot 4.6 rendering risks are explicit before implementation.

### Negative

- Requires profile resources and presentation adapters before final visual stories can complete.
- Some visual choices remain Art Bible/Technical Artist polish work, especially shader values and screenshots.
- Compatibility fallback needs explicit screenshot/performance verification.

### Risks

- **HUD readability loss**: global filters may obscure text/focus.
  - **Mitigation**: UI layer renders above world effects and must pass contrast/focus checks.
- **Performance overrun**: compositor effects and shader overlays may exceed budget.
  - **Mitigation**: profile-level toggles, reduced variants, Shader Baker evaluation, and perf capture on dense map/battle scenes.
- **Gold-code/shiny ambiguity**: restored overlay may look like shiny.
  - **Mitigation**: overlay must use distinct pattern/motion and preserve shiny marker.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `singularity.md` | Corruption classes, SCAR visuals, Mirror Admin phase presentation, restored gold-code overlay, post-game terminal visual state. | Defines presentation service, profile Resources, class mapping, SCAR overlays, and restored gold-code layering. |
| `campaign-map.md` | SCAR overlays and CRITICAL/BREACH map visual filters. | Assigns SCAR/world rendering to presentation adapters driven by Singularity state. |
| `battle-engine.md` | Battle corruption filters and presentation profile signals. | Keeps Battle logic separate while allowing battle presentation adapters to apply profiles. |
| `audio-director.md` | Corruption class degradation must have visual equivalents. | Ensures rendering provides non-audio confirmation for every class. |
| `input-router.md` | Focus and gamepad controls remain visible and usable. | Requires UI/HUD layer and focus indicators above effects. |
| `design/accessibility-requirements.md` | Reduced motion/flash, color-independent communication. | Makes accessibility variants mandatory for profiles. |
| `design/ux/hud.md` | HUD corruption indicator, Counter affordance, post-game overlay readability. | Keeps HUD text/icon state above rendering effects and maps state to visual profiles. |

## Performance Implications

- **CPU**: Low to moderate; presentation updates are event-driven, but screen adapters must avoid per-frame allocation.
- **GPU**: Moderate; compositor filters, scanlines, glow, and sprite overlays must be profiled on dense map and battle scenes.
- **Memory**: Low to moderate; shader/material variants and profile Resources require content validation.
- **Load Time**: Shader variant compilation may affect first-load; evaluate Shader Baker if startup hitches appear.
- **Network**: None.

## Migration Plan

No implementation migration exists yet. When implementation begins:

1. Create profile Resource classes and initial profile library.
2. Implement CorruptionPresentationService.
3. Add presentation adapters for Campaign Map, Battle, Roster/Hatchery, Crown/terminal screens.
4. Implement restored gold-code overlay material and reduced variants.
5. Capture screenshot/performance evidence for NOMINAL, ALERT, CRITICAL, BREACH, and post-game.

## Validation Criteria

- HUD text, focus ring, corruption label, and confirm/cancel affordances remain readable under every profile.
- SCAR bridge nodes remain visibly traversable.
- Reduced-motion and reduced-flash variants suppress high-motion/high-flash effects.
- Restored gold-code appears after `ending_id != ""` and has no stat implication.
- Forward+/desktop and OpenGL3 Compatibility fallback render profiles without blank screens, broken shaders, or lost class readability.
- Dense Campaign Map and Mirror Admin Battle scenes stay within 60fps target budget.

## Related Decisions

- ADR-0002 Semantic Event Contracts
- ADR-0003 Input Router Semantic Actions
- ADR-0004 Authored Content Resources
- ADR-0005 Godot Scene Flow And Autoload Boundaries
- ADR-0010 Singularity Boss And Ending Orchestration
