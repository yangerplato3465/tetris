extends RefCounted

# Floor 3. Pounds and hardens behind a shield; below half it crumbles into constant
# avalanches, a little heavier than its old every-5-drops hit.
const ENEMY := {
	"id": "rock_golem",
	"name": "rock golem",
	"boss_floor": 3,
	"health": 2000,
	"reward": 120,
	"frame": 51,
	"description": "Start with a small messy board",
	"board": "small",
	"moves": {
		"pound": {"name": "Pound", "steps": 5, "effects": [{"type": "attack", "amount": 40}, {"type": "add_garbage", "amount": 1}]},
		"harden": {"name": "Harden", "steps": 3, "effects": [{"type": "enemy_shield", "amount": 200}]},
		"avalanche": {"name": "Avalanche", "steps": 5, "effects": [{"type": "attack", "amount": 45}, {"type": "add_garbage", "amount": 1}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["pound", "harden", "pound"]}},
		{"name": "Crumbling", "hp_below": 0.5, "pattern": {"type": "cycle", "moves": ["avalanche"]}},
	],
}
