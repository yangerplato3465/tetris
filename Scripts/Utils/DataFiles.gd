class_name DataFiles
extends RefCounted

# Folder scanning shared by the loaders of script-based content — events
# (Events) and enemies (Consts) — each of which is one .gd file per entry holding
# a `const` dictionary.

# Every script in `dirPath`, sorted. Exported builds may store scripts as .gdc
# (binary tokens) or behind a .remap; both are mapped back to the .gd path, which
# is what load() expects.
static func scriptPaths(dirPath: String) -> Array:
	var out: Array = []
	var dir = DirAccess.open(dirPath)
	if dir == null:
		push_error("DataFiles: could not open data directory " + dirPath)
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

# The dictionary a data script declares as `const <constName>`, or null (with an
# error) if the file doesn't load or doesn't declare one.
static func loadConstant(path: String, constName: String):
	var script = load(path)
	var value = script.get_script_constant_map().get(constName) if script else null
	if not value is Dictionary:
		push_error("Data: %s has no `const %s` dictionary" % [path, constName])
		return null
	return value
