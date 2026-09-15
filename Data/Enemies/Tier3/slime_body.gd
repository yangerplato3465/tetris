extends RefCounted

# Slams and absorbs a shield; below half it splits into random slams and spit that
# buries a row and curses a piece. Hold stays locked all fight.
const ENEMY := {
	"id": "slime_body",
	"name": "slime body",
	"health": 6000,
	"reward": 200,
	"frame": 16,
	"description": "Start with a messy board, You cannot hold pieces",
	"board": "medium",
	"passives": [{"type": "disable_hold"}],
	"moves": {
		"slam": {"name": "Slam", "steps": 5, "effects": [{"type": "attack", "amount": 35}, {"type": "add_garbage", "amount": 1}]},
		"absorb": {"name": "Absorb", "steps": 5, "effects": [{"type": "enemy_shield", "amount": 400}]},
		"spit": {"name": "Spit", "steps": 4, "effects": [{"type": "add_garbage", "amount": 1}, {"type": "curse_piece", "amount": 1}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["slam", "absorb", "slam"]}},
		{"name": "Splitting", "hp_below": 0.5, "pattern": {"type": "random", "moves": ["slam", "spit"]}},
	],
}
