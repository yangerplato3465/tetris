extends RefCounted

# The tier's first unpredictable enemy: reaps two times in three, otherwise harvests
# a smaller hit that heals it.
const ENEMY := {
	"id": "reaper",
	"name": "Reaper",
	"health": 2500,
	"reward": 200,
	"frame": 36,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"reap": {"name": "Reap", "steps": 5, "effects": [{"type": "attack", "amount": 36}, {"type": "add_garbage", "amount": 1}]},
		"harvest": {"name": "Harvest", "steps": 5, "effects": [{"type": "attack", "amount": 20}, {"type": "heal", "amount": 200}]},
	},
	"phases": [
		{"pattern": {"type": "random", "moves": ["reap", "reap", "harvest"]}},
	],
}
