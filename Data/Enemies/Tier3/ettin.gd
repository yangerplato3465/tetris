extends RefCounted

# Two heads take turns, then both strike at once on a long wind-up.
const ENEMY := {
	"id": "ettin",
	"name": "Ettin",
	"health": 5000,
	"reward": 150,
	"frame": 7,
	"description": "Start with a very messy board",
	"board": "large",
	"moves": {
		"left": {"name": "Left Head", "steps": 5, "effects": [{"type": "attack", "amount": 30}]},
		"right": {"name": "Right Head", "steps": 5, "effects": [{"type": "attack", "amount": 30}, {"type": "add_garbage", "amount": 1}]},
		"both": {"name": "Both Heads", "steps": 8, "effects": [{"type": "attack", "amount": 60}, {"type": "add_garbage", "amount": 1}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["left", "right", "both"]}},
	],
}
