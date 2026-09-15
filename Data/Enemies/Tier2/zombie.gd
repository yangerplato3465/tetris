extends RefCounted

# Claw, a grab that buries a row, then a retch that curses the next piece. Less raw
# damage than before; the garbage and curse are the threat.
const ENEMY := {
	"id": "zombie",
	"name": "Zombie",
	"health": 2500,
	"reward": 150,
	"frame": 32,
	"description": "Start with a messy board",
	"board": "medium",
	"moves": {
		"claw": {"name": "Claw", "steps": 5, "effects": [{"type": "attack", "amount": 20}]},
		"grab": {"name": "Grab", "steps": 6, "effects": [{"type": "attack", "amount": 25}, {"type": "add_garbage", "amount": 1}]},
		"retch": {"name": "Retch", "steps": 4, "effects": [{"type": "curse_piece", "amount": 1}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["claw", "grab", "retch"]}},
	],
}
