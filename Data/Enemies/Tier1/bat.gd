extends RefCounted

# Weak bites; every third move a screech blanks the preview for two pieces.
const ENEMY := {
	"id": "bat",
	"name": "Bat",
	"health": 600,
	"reward": 60,
	"frame": 48,
	"description": "",
	"board": "clean",
	"moves": {
		"bite": {"name": "Bite", "steps": 6, "effects": [{"type": "attack", "amount": 10}]},
		"screech": {"name": "Screech", "steps": 4, "effects": [{"type": "hide_preview", "drops": 2}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["bite", "bite", "screech"]}},
	],
}
