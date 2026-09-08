extends RefCounted
## Small deterministic synthesized effects, cached in memory. No microphone or networking.
## Effects add feedback only; their envelope never controls a gameplay event.
static var cache: Dictionary = {}
const RATE = 22050
const CUES = {
	"ui":[740.0,.07,0.0], "launch":[260.0,.12,.15], "claw":[155.0,.18,.6],
	"breath":[210.0,.32,.65], "wall":[100.0,.34,.5], "burst":[75.0,.40,.75],
	"hit":[130.0,.12,.55], "blocked":[900.0,.13,.05], "guard":[520.0,.15,.2],
	"hurt":[85.0,.18,.5], "warning":[620.0,.24,.05], "impact":[65.0,.28,.6],
	"swap":[420.0,.23,.1], "reward":[520.0,.40,.0], "repair":[340.0,.30,.0],
	"shatter":[1200.0,.28,.7], "discharge":[360.0,.30,.7], "fusion":[175.0,.45,.18],
	"evolve":[440.0,.48,.0], "hatch":[330.0,.45,.12], "relay":[550.0,.30,.05],
}

static func sound(cue: String, guardian: String = "fire") -> AudioStreamWAV:
	if not CUES.has(cue): return null
	var key = cue + "/" + guardian
	if cache.has(key): return cache[key]
	var spec: Array = CUES[cue]
	var pitch: float = {"fire":.78,"ice":1.55,"storm":1.08,"stone":.58,"venom":.90,"shadow":.70,"void":.62,"light":1.32,"synthesis":1.12}.get(guardian,1.0)
	if cue in ["ui","warning","reward","evolve","repair","hatch","fusion","relay"]: pitch = 1.0
	var count = int(RATE * spec[1])
	var data = PackedByteArray()
	data.resize(count * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 83011 + key.hash()
	var phase = 0.0
	for i in range(count):
		var t = float(i) / RATE
		var q = float(i) / count
		var f: float = spec[0] * pitch
		if cue in ["reward","evolve","hatch","repair"]:
			f *= [1.0,1.25,1.5,2.0][mini(3, int(q*4.0))]
		elif cue == "warning": f *= 1.0 + .08*sin(t*50.0)
		else: f *= 1.0 + (1.0-q)*.7
		phase += TAU*f/RATE
		var tone = sin(phase)*.72 + sin(phase*2.01)*.18
		var noise = rng.randf_range(-1.0,1.0)
		var wave = lerpf(tone,noise,float(spec[2]))
		var envelope = minf(1.0, t/.007) * pow(1.0-q,1.6) * minf(1.0,(spec[1]-t)/.015)
		data.encode_s16(i*2, roundi(clampf(wave*envelope*.35,-.5,.5)*32767))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	cache[key] = stream
	return stream
