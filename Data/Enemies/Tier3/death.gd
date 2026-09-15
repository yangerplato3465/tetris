extends RefCounted

# Scythes and a mark that weakens the player, then below 30% only Doom: a race to
# finish it before the big hits pile up.
const ENEMY := {
	"id": "death",
	"name": "Death",
	"health": 5000,
	"reward": 200,
	"frame": 37,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"scythe": {"name": "Scythe", "steps": 5, "effects": [{"type": "attack", "amount": 40}, {"type": "add_garbage", "amount": 1}]},
		"mark": {"name": "Death Mark", "steps": 3, "effects": [{"type": "weaken", "amount": 0.7, "drops": 4}]},
		"doom": {"name": "Doom", "steps": 6, "effects": [{"type": "attack", "amount": 70}, {"type": "add_garbage", "amount": 1}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["scythe", "scythe", "mark"]}},
		{"name": "Final Hour", "hp_below": 0.3, "pattern": {"type": "cycle", "moves": ["doom"]}},
	],
}
