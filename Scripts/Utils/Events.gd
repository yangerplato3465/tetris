extends Node

# Event definitions read by EventScene.showEvent(). Every entry is one event
# "page"; follow-up pages are just more entries referenced by id via "next".
#
# Event:
#   "title": String
#   "body": String                      flavor / situation text
#   "options": Array of Option
#
# Option:
#   "text": String                      button label (required)
#   "cost": Array of effect descriptors spent when picked; button is disabled
#                                       and grayed out while unaffordable
#   -- either a single fixed outcome (flat on the option): --
#   "result": String                    aftermath text (optional)
#   "effects": Array of descriptors     applied in order (optional)
#   "effect": Callable                  escape hatch for custom logic, runs
#                                       after "effects" (optional)
#   "next": String                      follow-up page id; Continue opens it
#                                       instead of ending the event (optional)
#   -- or weighted random outcomes: --
#   "outcomes": [ {"weight": int, ...outcome fields as above...}, ... ]
#
# Effect / cost descriptor: {"type": String, "amount": int}
# Types: coins, heal, damage, max_hp, shield, magic, max_magic
# (interpreted in EventScene._applyEffect / _canAfford — extend there.)

# Events rolled for "?" nodes on the map. Follow-up pages (reached via
# "next") must NOT be listed here — only valid starting points.
var pool = ["abandoned_cart", "strange_shrine"]

var events = {
	# Placeholder demo event (also the showEvent() no-arg default).
	"abandoned_cart": {
		"title": "Abandoned Cart",
		"body": "A merchant's cart lies toppled by the roadside, its wheel shattered. Crates of goods are scattered across the dirt, but the owner is nowhere to be seen.",
		"options": [
			{
				"text": "Loot the crates (+30 coins)",
				"result": "You pry open the crates and pocket 30 coins. Somewhere, a merchant curses their luck.",
				"effects": [{"type": "coins", "amount": 30}],
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

	# Reference event exercising every schema feature — use as an authoring
	# template, replace with real events.
	"strange_shrine": {
		"title": "Strange Shrine",
		"body": "A crumbling shrine hums with unstable magic. Something glitters in the offering bowl.",
		"options": [
			{
				"text": "Make an offering (pay 25 coins)",
				"cost": [{"type": "coins", "amount": 25}],
				"result": "The shrine flares with warm light. You feel sturdier.",
				"effects": [{"type": "max_hp", "amount": 10}, {"type": "heal", "amount": 10}],
			},
			{
				"text": "Grab the glittering thing",
				"outcomes": [
					{
						"weight": 2,
						"result": "A pouch of coins! The shrine doesn't seem to mind.",
						"effects": [{"type": "coins", "amount": 40}],
					},
					{
						"weight": 1,
						"result": "The shrine's magic lashes out and something stirs behind you...",
						"effects": [{"type": "damage", "amount": 10}],
						"next": "strange_shrine_guardian",
					},
				],
			},
			{
				"text": "Back away slowly",
				"result": "Some things are best left alone.",
			},
		],
	},
	"strange_shrine_guardian": {
		"title": "The Guardian Wakes",
		"body": "A stone sentinel unfolds from the shrine's shadow, grinding to life. It blocks the path forward.",
		"options": [
			{
				"text": "Stand your ground (+15 shield)",
				"result": "You brace yourself as the guardian sizes you up... then slowly settles back into stillness.",
				"effects": [{"type": "shield", "amount": 15}],
			},
			{
				"text": "Sprint past it",
				"result": "You bolt. A stone fist grazes you as you escape.",
				"effects": [{"type": "damage", "amount": 5}],
			},
		],
	},
}
