extends RefCounted

# The first garbage the player sees: two light oozes, then a splat that adds a row.
const ENEMY := {
	"id": "slime",
	"name": "Slime",
	"health": 600,
	"reward": 60,
	"frame": 15,
	"description": "Start with small messy board",
	"board": "small",
	"moves": {
		"ooze": {"name": "Ooze", "steps": 5, "effects": [{"type": "attack", "amount": 12}]},
		"splat": {"name": "Splat", "steps": 6, "effects": [{"type": "add_garbage", "amount": 1}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["ooze", "ooze", "splat"]}},
	],
}
