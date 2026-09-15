extends RefCounted

# A flurry of tiny nips on a 2-drop rhythm, then a slower lunge. Same pressure as a
# plain attacker, but the counter never sits still.
const ENEMY := {
	"id": "centipede",
	"name": "Centipede",
	"health": 600,
	"reward": 60,
	"frame": 42,
	"description": "",
	"board": "clean",
	"moves": {
		"nip": {"name": "Nip", "steps": 2, "effects": [{"type": "attack", "amount": 6}]},
		"lunge": {"name": "Lunge", "steps": 8, "effects": [{"type": "attack", "amount": 24}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["nip", "nip", "nip", "lunge"]}},
	],
}
