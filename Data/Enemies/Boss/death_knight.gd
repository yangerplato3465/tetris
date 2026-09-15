extends RefCounted

# Floor 12, hold locked all fight. Three phases: cleaves behind a dark ward, then
# cleaves around a soul drain that heals, then a last stand of executions.
const ENEMY := {
	"id": "death_knight",
	"name": "death knight",
	"boss_floor": 12,
	"health": 12000,
	"reward": 300,
	"frame": 30,
	"description": "Start with a very messy board, you cannot hold pieces",
	"board": "large",
	"passives": [{"type": "disable_hold"}],
	"moves": {
		"cleave": {"name": "Cleave", "steps": 4, "effects": [{"type": "attack", "amount": 50}, {"type": "add_garbage", "amount": 1}]},
		"ward": {"name": "Dark Ward", "steps": 3, "effects": [{"type": "enemy_shield", "amount": 800}]},
		"drain": {"name": "Soul Drain", "steps": 5, "effects": [{"type": "attack", "amount": 45}, {"type": "heal", "amount": 400}]},
		"execute": {"name": "Execution", "steps": 5, "effects": [{"type": "attack", "amount": 80}, {"type": "add_garbage", "amount": 1}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["cleave", "cleave", "ward"]}},
		{"name": "Unholy Vigor", "hp_below": 0.6, "pattern": {"type": "cycle", "moves": ["cleave", "drain", "cleave"]}},
		{"name": "Last Stand", "hp_below": 0.25, "pattern": {"type": "cycle", "moves": ["execute"]}},
	],
}
