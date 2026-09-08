extends RefCounted
## Separate Forge-Trials records. Never reads or writes reconnection-campaign.json.
const Trials = preload("res://campaign/trials.gd")
const VERSION = 1
var path = "user://forge-trials.json"
var message = ""

func fresh() -> Dictionary:
	return {"version":VERSION,"records":{}}

func normalize(value: Variant) -> Dictionary:
	if not value is Dictionary or value.get("version",0) != VERSION or not value.get("records") is Dictionary:
		return {}
	var out = fresh()
	for id in value.records:
		if not Trials.DATA.has(id) or not value.records[id] is Dictionary: return {}
		var r: Dictionary = value.records[id]
		for key in ["clears","best_ms","best_damage"]:
			if not r.has(key) or not (r[key] is int or r[key] is float) or float(r[key]) < 0 or float(r[key]) != floor(float(r[key])): return {}
		if not r.get("last_pair",[]) is Array or r.last_pair.size()>2: return {}
		for guardian in r.last_pair:
			if not guardian is String or not guardian in ["fire","ice","storm","stone"]: return {}
		out.records[id]={"clears":int(r.clears),"best_ms":int(r.best_ms),"best_damage":int(r.best_damage),"last_pair":r.last_pair.duplicate()}
	return out

func read_records() -> Dictionary:
	message=""
	if not FileAccess.file_exists(path): return fresh()
	var result=normalize(_read(path))
	if result.is_empty():
		message="Forge Trial records were unreadable. The original file was left untouched."
		return fresh()
	return result

func apply_record(state: Dictionary,id: String,time_ms: int,damage: int,pair: Array) -> bool:
	if not Trials.DATA.has(id) or time_ms<0 or damage<0: return false
	var current: Dictionary = state.records.get(id,{"clears":0,"best_ms":0,"best_damage":0,"last_pair":[]})
	current.clears=int(current.clears)+1
	if int(current.best_ms)==0 or time_ms<int(current.best_ms): current.best_ms=time_ms
	if int(current.best_damage)==0 or damage<int(current.best_damage): current.best_damage=damage
	current.last_pair=pair.slice(0,2)
	state.records[id]=current
	return true

func record(state: Dictionary,id: String,time_ms: int,damage: int,pair: Array) -> bool:
	return apply_record(state,id,time_ms,damage,pair) and write_records(state)

func write_records(state: Dictionary) -> bool:
	if normalize(state).is_empty(): return false
	var tmp=path+".tmp"
	var f=FileAccess.open(tmp,FileAccess.WRITE)
	if f==null:return false
	f.store_string(JSON.stringify(state,"\t"));f.flush();var err=f.get_error();f.close()
	if err!=OK or normalize(_read(tmp)).is_empty():return false
	var absolute=ProjectSettings.globalize_path(path);var backup=absolute+".bak";var previous=FileAccess.file_exists(path)
	if previous:
		if FileAccess.file_exists(backup):DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(absolute,backup)!=OK:return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp),absolute)!=OK:
		if previous:DirAccess.rename_absolute(backup,absolute)
		return false
	return true

func _read(filename:String)->Variant:
	var f=FileAccess.open(filename,FileAccess.READ)
	if f==null or f.get_length()>262144:return null
	var parser=JSON.new();var code=parser.parse(f.get_as_text());f.close()
	return parser.data if code==OK else null
