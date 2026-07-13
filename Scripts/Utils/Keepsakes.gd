extends Node

# Keepsake definitions read by the shop (ShopPanell.gd). Keepsakes are permanent
# trinkets: buying one applies its effects immediately and they last for the rest
# of the run. Owned keepsakes never reappear in the shop.
#
# Each keepsake is authored as a typed KeepsakeData .tres under Data/Keepsakes/
# and loaded here at startup (in _init, mirroring Consts). To add/tune one, edit
# or add a .tres in the Inspector — no code change. Effect descriptors on each
# keepsake are interpreted by PlayerManager.applyKeepsakeEffect.

# id -> KeepsakeData, and the list of ids eligible for the shop's bottom row
# (the shop filters out ids already in PlayerManager.ownedKeepsakes).
var keepsakes: Dictionary = {}
var pool: Array = []

func _init():
	for keepsake in _loadResourceDir("res://Data/Keepsakes"):
		keepsakes[keepsake.id] = keepsake
		pool.append(keepsake.id)

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
