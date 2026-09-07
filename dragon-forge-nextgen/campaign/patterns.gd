extends RefCounted
## Tell geometry and impact geometry share the same immutable payload.
static func lock(kind: String, origin: Vector3, target: Vector3) -> Dictionary:
	var direction = target - origin
	direction.y = 0.0
	direction = direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	var side = direction.cross(Vector3.UP).normalized()
	var circles: Array = []
	if kind == "fan":
		for offset in [-3.6, 0.0, 3.6]:
			circles.append(target + side * offset)
	elif kind == "slam":
		circles.append(target)
	return {"kind": kind, "origin": origin, "direction": direction, "circles": circles, "radius": 2.3, "inner": 2.8, "outer": 7.0, "length": 13.0, "half_width": 1.3}

static func contains(shape: Dictionary, at: Vector3) -> bool:
	var offset = at - shape.origin
	offset.y = 0.0
	match shape.kind:
		"beam":
			var along = offset.dot(shape.direction)
			var side = offset - shape.direction * along
			return along >= -0.8 and along <= shape.length and side.length() <= shape.half_width
		"ring":
			return offset.length() >= shape.inner and offset.length() <= shape.outer
		_:
			for center in shape.circles:
				var d: Vector3 = at - center
				d.y = 0.0
				if d.length() <= shape.radius:
					return true
	return false

static func tip(kind: String) -> String:
	return {"slam": "LEAVE THE CIRCLE", "fan": "FIND THE GAP", "beam": "MOVE SIDEWAYS", "ring": "SAFE INSIDE THE SMALL RING"}.get(kind, "DODGE OR GUARD")
