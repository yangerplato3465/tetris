extends RefCounted

# Two bolts, then a hex that cuts the player's damage by a quarter for 4 drops.
# Raw damage is lower than before to pay for the hex.
const ENEMY := {
	"id": "orc_wizard",
	"name": "Orc Wizard",
	"health": 2000,
	"reward": 100,
	"frame": 1,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"bolt": {"name": "Bolt", "steps": 5, "effects": [{"type": "attack", "amount": 22}]},
		"hex": {"name": "Hex", "steps": 4, "effects": [{"type": "weaken", "amount": 0.75, "drops": 4}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["bolt", "bolt", "hex"]}},
	],
}
