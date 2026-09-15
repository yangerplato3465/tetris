extends RefCounted

# Floor 9. Volleys, a pinning shot that locks hold, then a charge; below half it
# stampedes, alternating charge and trample with garbage on both.
const ENEMY := {
	"id": "centaur",
	"name": "centaur",
	"boss_floor": 9,
	"health": 8000,
	"reward": 200,
	"frame": 52,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"volley": {"name": "Volley", "steps": 4, "effects": [{"type": "attack", "amount": 30}]},
		"pin": {"name": "Pin Shot", "steps": 4, "effects": [{"type": "attack", "amount": 20}, {"type": "lock_hold", "drops": 4}]},
		"charge": {"name": "Charge", "steps": 6, "effects": [{"type": "attack", "amount": 70}, {"type": "add_garbage", "amount": 1}]},
		"trample": {"name": "Trample", "steps": 4, "effects": [{"type": "attack", "amount": 35}, {"type": "add_garbage", "amount": 1}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["volley", "volley", "pin", "charge"]}},
		{"name": "Stampede", "hp_below": 0.5, "pattern": {"type": "cycle", "moves": ["charge", "trample"]}},
	],
}
