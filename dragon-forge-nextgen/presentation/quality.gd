extends RefCounted
## Quality affects presentation only. It never changes ticks, tells, or damage.
const NAMES = ["Low", "Medium", "High", "Ultra"]
const SCALES = [0.70, 0.85, 1.0, 1.0]
const PARTICLES = [16, 32, 64, 128]

static func apply(index: int, viewport: Viewport, environment: Environment, sun: DirectionalLight3D, reduced: bool) -> Dictionary:
	var level = clampi(index, 0, 3)
	var renderer = RenderingServer.get_current_rendering_method()
	var forward = renderer == "forward_plus"
	viewport.scaling_3d_scale = SCALES[level]
	viewport.msaa_3d = Viewport.MSAA_DISABLED if level == 0 else (Viewport.MSAA_4X if level == 3 else Viewport.MSAA_2X)
	sun.shadow_enabled = level > 0
	environment.glow_enabled = forward and level > 0 and not reduced
	environment.ssao_enabled = forward and level >= 2
	environment.volumetric_fog_enabled = forward and level >= 2 and not reduced
	environment.volumetric_fog_density = 0.012
	return {"level": level, "renderer": renderer, "particles": PARTICLES[level] if forward and not reduced else 0}
