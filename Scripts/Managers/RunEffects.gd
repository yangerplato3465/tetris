class_name RunEffects
extends RefCounted

# The out-of-battle effect vocabulary: permanent changes to the run, applied by
# events (EventScene) and by the keepsake "acquire" trigger
# (PlayerManager.addKeepsake). In-battle effects are a separate vocabulary —
# Main._applyAbilityEffect, used by spells and every other keepsake trigger —
# because they need a live board and enemy.
#
# apply() returns a short note for anything an author can't know in advance:
# which random keepsake was granted, a piece change that was refused, text from a
# custom function. EventScene appends notes to the result text; "" means none.

# Every type apply() implements, mapped to the keys it reads ("?" = optional).
# DataValidator checks events and acquire effects against this.
const EFFECT_KEYS := {
	"coins": ["amount"],
	"heal": ["amount"],
	"lose_hp": ["amount"],
	"max_hp": ["amount"],
	"shield": ["amount"],
	"magic": ["amount"],
	"max_magic": ["amount"],
	"combo_mult": ["amount"],
	"next_piece": ["amount?"],
	"fire_blocks": [],
	"ice_blocks": [],
	"gold_blocks": [],
	"gain_keepsake": ["id"],
	"gain_random_keepsake": ["rarity?"],
	"add_piece": ["shape", "amount?"],
	"remove_piece": ["shape"],
	"set_flag": ["flag"],
	"clear_flag": ["flag"],
	"call": ["method"],
}

# Types that need an event's script as context, so only events may use them.
const EVENT_ONLY := ["call"]

# Smallest bag remove_piece may leave. NextPieces.drawPieces indexes into the rest
# of the current bag plus the whole next bag; right after a draw that is at least
# 2n - 1 pieces for a bag of n, and it must fill MAX_NEXT_PIECES slots — so n >= 3.
const MIN_SPAWN_BAG := 3
# The preview has this many slots (Main's Lock2..Lock5 plus the first).
const MAX_NEXT_PIECES := 5

# `ctx` carries what a type needs from its caller — "event": the event's script
# instance, for "call".
static func apply(desc: Dictionary, ctx: Dictionary = {}) -> String:
	var amount = desc.get("amount", 0)
	match desc.get("type", ""):
		"coins":
			PlayerManager.coin = maxi(PlayerManager.coin + amount, 0)
		"heal":
			PlayerManager.playerHealth = mini(PlayerManager.playerHealth + amount, PlayerManager.maxPlayerHealth)
		# Never kills: there is no game-over path outside a battle, so the floor is
		# 1 HP — the same rule an HP cost follows.
		"lose_hp":
			PlayerManager.playerHealth = maxi(PlayerManager.playerHealth - amount, 1)
		# Moves max and current HP together, so +10 max HP is also +10 HP. A negative
		# amount is a curse: it lowers both, never below 1.
		"max_hp":
			PlayerManager.maxPlayerHealth = maxi(PlayerManager.maxPlayerHealth + amount, 1)
			PlayerManager.playerHealth = clampi(PlayerManager.playerHealth + amount, 1, PlayerManager.maxPlayerHealth)
		"shield":
			PlayerManager.shieldNum = maxi(PlayerManager.shieldNum + amount, 0)
		"magic":
			PlayerManager.magicMeter = clampi(PlayerManager.magicMeter + amount, 0, PlayerManager.maxMagicMeter)
		"max_magic":
			PlayerManager.maxMagicMeter = maxi(PlayerManager.maxMagicMeter + amount, 1)
			PlayerManager.magicMeter = mini(PlayerManager.magicMeter, PlayerManager.maxMagicMeter)
		"combo_mult":
			PlayerManager.comboMult += amount
		"next_piece":
			PlayerManager.visibleNextPiece = mini(PlayerManager.visibleNextPiece + desc.get("amount", 1), MAX_NEXT_PIECES)
			PlayerManager.unlockNextPiece.emit()
		"fire_blocks":
			PlayerManager.fireBlocks = true
		"ice_blocks":
			PlayerManager.iceBlocks = true
		"gold_blocks":
			PlayerManager.goldBlocks = true
		"gain_keepsake":
			return _gainKeepsake(Keepsakes.getKeepsake(desc.id))
		# Rolls from the shop pool, so event-only keepsakes (inShop = false) stay
		# reachable only through an event that names them.
		"gain_random_keepsake":
			var rarity = desc.get("rarity", "")
			var choices = Keepsakes.pool.filter(func(id):
				return not PlayerManager.ownedKeepsakes.has(id) \
					and (rarity == "" or Keepsakes.keepsakes[id].rarity == rarity))
			if choices.is_empty():
				return "There was nothing left to find."
			return _gainKeepsake(Keepsakes.keepsakes[choices.pick_random()])
		# PlayerManager.spawnBag lists the Constants.SHAPES index of every piece in a
		# bag. Grid.newBag reads it, so a change shows up from the next bag drawn.
		"add_piece":
			for _i in desc.get("amount", 1):
				PlayerManager.spawnBag.append(desc.shape)
		# Removes every copy of the shape, unless that would shrink the bag below
		# MIN_SPAWN_BAG — then nothing changes and the note says so.
		"remove_piece":
			var remaining = PlayerManager.spawnBag.filter(func(shape): return shape != desc.shape)
			if remaining.size() < MIN_SPAWN_BAG:
				return "The pieces resist. Too few would remain."
			PlayerManager.spawnBag = remaining
		# Run flags (PlayerManager.runFlags) are read back by RunConditions "flag" /
		# "not_flag" — how one event leaves something behind for a later one.
		"set_flag":
			PlayerManager.runFlags[desc.flag] = true
		"clear_flag":
			PlayerManager.runFlags.erase(desc.flag)
		# Runs a function defined in the event's own file. Returning a String appends
		# it to the result text.
		"call":
			var target = ctx.get("event")
			if target == null or not target.has_method(desc.method):
				push_error("RunEffects: 'call' to '%s' has no event script that defines it" % desc.method)
				return ""
			var note = target.call(desc.method)
			return note if note is String else ""
		_:
			push_warning("RunEffects: unknown effect type '%s'" % desc.get("type", ""))
	return ""

# Free, and never a second copy: owning a keepsake twice would stack its acquire
# effects and fire its triggers twice.
static func _gainKeepsake(keepsake) -> String:
	if keepsake == null:
		push_error("RunEffects: gain_keepsake names a keepsake that does not exist")
		return ""
	if PlayerManager.ownedKeepsakes.has(keepsake.id):
		return ""
	PlayerManager.addKeepsake(keepsake, false)
	return "Gained %s." % keepsake.name
