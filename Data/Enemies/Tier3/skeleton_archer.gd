extends RefCounted

# Random fire: quick arrows, a pinning shot that locks hold, or a slow volley. The
# counter's target changes every shot, so it has to be read each time.
const ENEMY := {
	"id": "skeleton_archer",
	"name": "skeleton archer",
	"health": 5000,
	"reward": 200,
	"frame": 29,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"arrow": {"name": "Arrow", "steps": 3, "effects": [{"type": "attack", "amount": 22}]},
		"pin": {"name": "Pin", "steps": 4, "effects": [{"type": "attack", "amount": 15}, {"type": "lock_hold", "drops": 3}]},
		"volley": {"name": "Volley", "steps": 7, "effects": [{"type": "attack", "amount": 60}]},
	},
	"phases": [
		{"pattern": {"type": "random", "moves": ["arrow", "arrow", "pin", "volley"]}},
	],
}
