extends RefCounted

# Placeholder demo event: a single page with three flat options. Looting sets the
# "robbed_merchant" flag, which Strange Shrine reads later in the run.

const EVENT := {
	"id": "abandoned_cart",
	"title": "Abandoned Cart",
	"start": "intro",
	"pages": {
		"intro": {
			"body": "A merchant's cart lies toppled by the roadside, its wheel shattered. Crates of goods are scattered across the dirt, but the owner is nowhere to be seen.",
			"options": [
				{
					"text": "Loot the crates (+30 coins)",
					"result": "You pry open the crates and pocket 30 coins. Somewhere, a merchant curses their luck.",
					"effects": [{"type": "coins", "amount": 30}, {"type": "set_flag", "flag": "robbed_merchant"}],
				},
				{
					"text": "Rest by the cart (heal 20 HP)",
					"result": "You take shelter behind the cart and catch your breath. You recover 20 HP.",
					"effects": [{"type": "heal", "amount": 20}],
				},
				{
					"text": "Leave it alone",
					"result": "Not your cart, not your problem. You move on.",
				},
			],
		},
	},
}
