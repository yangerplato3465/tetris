extends RefCounted

# The tier's tank and its first phase change: clubs and a small guard, then below
# 40% it stops guarding and swings hard every 6 drops.
const ENEMY := {
	"id": "orc",
	"name": "Orc",
	"health": 1000,
	"reward": 80,
	"frame": 0,
	"description": "",
	"board": "clean",
	"moves": {
		"club": {"name": "Club", "steps": 6, "effects": [{"type": "attack", "amount": 14}]},
		"guard": {"name": "Guard", "steps": 4, "effects": [{"type": "enemy_shield", "amount": 100}]},
		"rage": {"name": "Rage", "steps": 6, "effects": [{"type": "attack", "amount": 22}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["club", "club", "guard"]}},
		{"name": "Enraged", "hp_below": 0.4, "pattern": {"type": "cycle", "moves": ["rage"]}},
	],
}
