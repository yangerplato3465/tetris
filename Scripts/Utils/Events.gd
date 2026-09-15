extends Node

# `?` events. Each event is one GDScript file under Data/Events/ holding a
# `const EVENT` dictionary with all of its pages — see EventData for the schema.
# Loaded in _init (like Consts and Keepsakes) and checked by DataValidator.
#
# Every file is a valid starting point, since follow-up pages live inside their
# event, so `pool` is simply every loaded id: add a file and it can be rolled on
# a `?` floor, delete it and it can't. Nothing else lists events. Whether an event
# can be rolled *right now* is its `requires` — use rollEvent, not pool directly.

var events: Dictionary = {}   # id -> event Dictionary (const, so read-only)
var pool: Array = []          # ids EventScene may roll
var scripts: Dictionary = {}  # id -> the event's GDScript; EventScene instances it for "call"

func _init():
	var paths := {}
	for path in _eventScriptPaths("res://Data/Events"):
		var script = load(path)
		var event = script.get_script_constant_map().get("EVENT") if script else null
		if not event is Dictionary:
			push_error("Data: %s has no `const EVENT` dictionary" % path)
			continue
		var id = event.get("id", "")
		if events.has(id):
			push_error("Data: %s reuses event id '%s'" % [path, id])
			continue
		events[id] = event
		paths[id] = path
		scripts[id] = script
		pool.append(id)
	# Keepsakes and Consts are earlier autoloads, so their data is already loaded here.
	var classes = Consts.characters.map(func(character): return character.id)
	DataValidator.validateEvents(events, paths, scripts, Keepsakes.keepsakes, classes)

# A random event whose `requires` hold right now, or "" when none do.
func rollEvent() -> String:
	var eligible = pool.filter(func(id): return RunConditions.met(events[id].get("requires", [])))
	return eligible.pick_random() if not eligible.is_empty() else ""

func hasEligibleEvent() -> bool:
	return pool.any(func(id): return RunConditions.met(events[id].get("requires", [])))

# Every event script in `dirPath`, sorted. Exported builds may store scripts as
# .gdc (binary tokens) or behind a .remap; both are mapped back to the .gd path,
# which is what load() expects.
func _eventScriptPaths(dirPath: String) -> Array:
	var out: Array = []
	var dir = DirAccess.open(dirPath)
	if dir == null:
		push_error("Events: could not open data directory " + dirPath)
		return out
	for file in dir.get_files():
		var fileName = file.trim_suffix(".remap")
		if fileName.ends_with(".gdc"):
			fileName = fileName.trim_suffix(".gdc") + ".gd"
		var path = dirPath + "/" + fileName
		if fileName.ends_with(".gd") and not out.has(path):
			out.append(path)
	out.sort()
	return out
