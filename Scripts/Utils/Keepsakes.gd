extends Node

# Keepsake definitions read by the shop (ShopPanell.gd). Keepsakes are
# permanent trinkets: buying one applies its effects immediately and they
# last for the rest of the run. Owned keepsakes never reappear in the shop.
#
# Keepsake:
#   "id": String                        unique key (same as its dictionary key)
#   "name": String
#   "description": String               shown as the shop tooltip
#   "price": int
#   "frame": int                        icon frame in Sprite/Cards/Icons.png
#   "effects": Array of descriptors     applied in order on purchase (optional)
#   "effect": Callable                  escape hatch for custom logic, runs
#                                       after "effects" (optional)
#
# Effect descriptor: {"type": String, "amount": int/float}
# Types: combo_mult, max_hp, heal, max_magic, unlock_hold, next_piece,
# hard_drop_damage, treasure_box, fire_blocks, poison_blocks, gold_blocks
# ("amount" is ignored by the boolean/unlock types; interpreted in
# PlayerManager.applyKeepsakeEffect — extend there.)

# Keepsakes rolled for the shop's bottom row. Every entry must be a key in
# "keepsakes" below; the shop filters out ids in PlayerManager.ownedKeepsakes.
var pool = [
	"old_key",
	"magnifying_glass",
	"alchemists_ring",
	"heart_locket",
	"mana_crystal",
	"ember_charm",
	"venom_fang",
	"gilded_idol",
	"smiths_hammer",
	"dragons_chest",
]

var keepsakes = {
	# --- Placeholder keepsakes (ported from the old equipment/alchemy items) ---
	"old_key": {
		"id": "old_key",
		"name": "Old Key",
		"description": "Unlock the ability to hold pieces",
		"price": 30,
		"frame": 185,
		"effects": [{"type": "unlock_hold"}],
	},
	"magnifying_glass": {
		"id": "magnifying_glass",
		"name": "Magnifying Glass",
		"description": "See one more upcoming piece",
		"price": 30,
		"frame": 169,
		"effects": [{"type": "next_piece", "amount": 1}],
	},
	"alchemists_ring": {
		"id": "alchemists_ring",
		"name": "Alchemist's Ring",
		"description": "Increase combo multiplier by 0.1",
		"price": 40,
		"frame": 331,
		"effects": [{"type": "combo_mult", "amount": 0.1}],
	},
	"heart_locket": {
		"id": "heart_locket",
		"name": "Heart Locket",
		"description": "Gain +25 max HP",
		"price": 50,
		"frame": 291,
		"effects": [{"type": "max_hp", "amount": 25}],
	},
	"mana_crystal": {
		"id": "mana_crystal",
		"name": "Mana Crystal",
		"description": "Increase max magic orbs by 2",
		"price": 50,
		"frame": 326,
		"effects": [{"type": "max_magic", "amount": 2}],
	},
	"ember_charm": {
		"id": "ember_charm",
		"name": "Ember Charm",
		"description": "Fire blocks appear in pieces. Clearing fire blocks deals +15 bonus damage each",
		"price": 40,
		"frame": 242,
		"effects": [{"type": "fire_blocks"}],
	},
	"venom_fang": {
		"id": "venom_fang",
		"name": "Venom Fang",
		"description": "Poison blocks appear in pieces. Clearing poison blocks deals +8 bonus damage each",
		"price": 30,
		"frame": 244,
		"effects": [{"type": "poison_blocks"}],
	},
	"gilded_idol": {
		"id": "gilded_idol",
		"name": "Gilded Idol",
		"description": "Gold blocks appear in pieces. Clearing gold blocks gives 1 coin each",
		"price": 40,
		"frame": 246,
		"effects": [{"type": "gold_blocks"}],
	},
	"smiths_hammer": {
		"id": "smiths_hammer",
		"name": "Smith's Hammer",
		"description": "Every time you hard drop, deal 20 damage to the enemy",
		"price": 60,
		"frame": 82,
		"effects": [{"type": "hard_drop_damage"}],
	},
	"dragons_chest": {
		"id": "dragons_chest",
		"name": "Dragon's Chest",
		"description": "Every time you score a Tetris, gain 50 coins",
		"price": 60,
		"frame": 187,
		"effects": [{"type": "treasure_box"}],
	},
}

func getKeepsake(id: String) -> Dictionary:
	return keepsakes.get(id, {})
