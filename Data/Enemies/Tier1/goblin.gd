extends RefCounted

# Two quick pokes, then a telegraphed stab — the first enemy teaches reading the next move.
const ENEMY := {
	"id": "goblin",
	"name": "Goblin",
	"health": 600,
	"reward": 40,
	"frame": 2,
	"description": "",
	"board": "clean",
	"moves": {
		"poke": {"name": "Poke", "steps": 5, "effects": [{"type": "attack", "amount": 6}]},
		"stab": {"name": "Stab", "steps": 8, "effects": [{"type": "attack", "amount": 16}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["poke", "poke", "stab"]}},
	],
}
