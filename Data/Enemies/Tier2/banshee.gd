extends RefCounted

# Alternates a hard shriek with a wail that blinds the preview for 3 drops — the
# heavy hit always lands while the player can see again.
const ENEMY := {
	"id": "banshee",
	"name": "Banshee",
	"health": 2500,
	"reward": 150,
	"frame": 35,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"shriek": {"name": "Shriek", "steps": 5, "effects": [{"type": "attack", "amount": 35}]},
		"wail": {"name": "Wail", "steps": 4, "effects": [{"type": "attack", "amount": 15}, {"type": "hide_preview", "drops": 3}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["shriek", "wail"]}},
	],
}
