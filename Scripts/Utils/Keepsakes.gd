extends Node

# Keepsake definitions read by the shop (ShopPanell.gd). Keepsakes are permanent
# trinkets: buying one applies its effects immediately and they last for the rest
# of the run. Owned keepsakes never reappear in the shop.
#
# Each keepsake is authored as a typed KeepsakeData .tres under Data/Keepsakes/
# and loaded here at startup (in _init, mirroring Consts). To add/tune one, edit
# or add a .tres in the Inspector — no code change. Effect descriptors on each
# keepsake run on a trigger — see KeepsakeData for the schema.

# id -> KeepsakeData for every keepsake, and the ids eligible for the shop's bottom
# row and gain_random_keepsake — every keepsake with inShop, so event-only ones are
# in `keepsakes` but not `pool`. The shop also filters out ids already owned.
var keepsakes: Dictionary = {}
var pool: Array = []

func _init():
	for keepsake in _loadResourceDir("res://Data/Keepsakes"):
		if keepsakes.has(keepsake.id):
			push_error("Data: %s reuses keepsake id '%s'" % [keepsake.resource_path, keepsake.id])
			continue
		keepsakes[keepsake.id] = keepsake
		if keepsake.inShop:
			pool.append(keepsake.id)
	DataValidator.validateKeepsakes(keepsakes.values())

func _loadResourceDir(path: String) -> Array:
	var out: Array = []
	var dir = DirAccess.open(path)
	if dir == null:
		push_error("Keepsakes: could not open data directory " + path)
		return out
	for file in dir.get_files():
		var res_name = file
		if res_name.ends_with(".remap"):
			res_name = res_name.trim_suffix(".remap")
		if res_name.ends_with(".tres"):
			out.append(load(path + "/" + res_name))
	return out

func getKeepsake(id: String) -> KeepsakeData:
	return keepsakes.get(id, null)
