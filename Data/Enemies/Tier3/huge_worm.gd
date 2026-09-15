extends RefCounted

# Bites, burrows (a shield plus a blinded preview), then erupts with two rows of garbage.
const ENEMY := {
	"id": "huge_worm",
	"name": "huge worm",
	"health": 8000,
	"reward": 200,
	"frame": 44,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"bite": {"name": "Bite", "steps": 5, "effects": [{"type": "attack", "amount": 35}, {"type": "add_garbage", "amount": 1}]},
		"burrow": {"name": "Burrow", "steps": 4, "effects": [{"type": "enemy_shield", "amount": 600}, {"type": "hide_preview", "drops": 3}]},
		"erupt": {"name": "Erupt", "steps": 6, "effects": [{"type": "attack", "amount": 60}, {"type": "add_garbage", "amount": 2}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["bite", "burrow", "erupt"]}},
	],
}
