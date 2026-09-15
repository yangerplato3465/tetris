extends RefCounted

# No tricks, just rhythm: two fast slashes and a heavy crush. The clean-board
# damage check of the tier.
const ENEMY := {
	"id": "skeleton",
	"name": "Skeleton",
	"health": 2500,
	"reward": 100,
	"frame": 28,
	"description": "",
	"board": "clean",
	"moves": {
		"slash": {"name": "Slash", "steps": 4, "effects": [{"type": "attack", "amount": 20}]},
		"crush": {"name": "Bone Crush", "steps": 7, "effects": [{"type": "attack", "amount": 40}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["slash", "slash", "crush"]}},
	],
}
