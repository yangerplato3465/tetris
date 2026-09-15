extends RefCounted

# Floor 6. Rends and feasts to heal on a learnable loop; below 40% it starves and
# picks at random, adding a heavy frenzy.
const ENEMY := {
	"id": "wendigo",
	"name": "wendigo",
	"boss_floor": 6,
	"health": 4000,
	"reward": 150,
	"frame": 50,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"rend": {"name": "Rend", "steps": 4, "effects": [{"type": "attack", "amount": 35}]},
		"feast": {"name": "Feast", "steps": 5, "effects": [{"type": "attack", "amount": 25}, {"type": "heal", "amount": 150}]},
		"frenzy": {"name": "Frenzy", "steps": 6, "effects": [{"type": "attack", "amount": 70}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["rend", "rend", "feast"]}},
		{"name": "Starving", "hp_below": 0.4, "pattern": {"type": "random", "moves": ["rend", "feast", "frenzy"]}},
	],
}
