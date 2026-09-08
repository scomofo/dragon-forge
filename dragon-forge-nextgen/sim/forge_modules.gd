extends RefCounted
## Small authored build choices, independent of presentation and save I/O.
const ORDER = ["coolant", "bastion", "catalyst"]
const DATA = {
	"coolant": {"name": "Coolant Heart", "tag": "SUSTAIN", "detail": "Cool 50% faster.\nKeep your breath and dodge available.", "stats": "Cooling 16 → 24 / sec", "color": Color("67e2d0"), "hp": 120.0, "cooling": 24.0, "guard": 0.25, "damage": 1.0, "heat": 1.0},
	"bastion": {"name": "Bastion Shell", "tag": "SURVIVE", "detail": "30% more health.\nGuard blocks 80% of incoming damage.", "stats": "Health 120 → 156", "color": Color("92b5ff"), "hp": 156.0, "cooling": 16.0, "guard": 0.20, "damage": 1.0, "heat": 1.0},
	"catalyst": {"name": "Cinder Catalyst", "tag": "PRESSURE", "detail": "Techniques deal 25% more damage.\nTrade-off: they generate 20% more heat.", "stats": "Damage ×1.25  /  Heat ×1.20", "color": Color("ffa665"), "hp": 120.0, "cooling": 16.0, "guard": 0.25, "damage": 1.25, "heat": 1.20},
}

static func valid(id: Variant) -> bool:
	return id is String and (id == "" or DATA.has(id))

static func profile(id: String) -> Dictionary:
	return DATA.get(id, {"name": "Unmodified core", "hp": 120.0, "cooling": 16.0, "guard": 0.25, "damage": 1.0, "heat": 1.0})
