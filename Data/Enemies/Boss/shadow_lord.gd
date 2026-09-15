extends RefCounted

# Floor 15, all damage halved. Shadow bolts around a veil that blinds and curses;
# at two thirds the veil tears into random wither and grasp; at one third, an
# eclipse steals half the player's banked shield.
const ENEMY := {
	"id": "shadow_lord",
	"name": "Shadow Lord",
	"boss_floor": 15,
	"health": 10000,
	"reward": 0,
	"frame": 30,
	"description": "Final boss, Start with a very messy board, all damage halfed",
	"board": "large",
	"passives": [{"type": "damage_reduction", "amount": 0.5}],
	"moves": {
		"bolt": {"name": "Dark Bolt", "steps": 4, "effects": [{"type": "attack", "amount": 60}, {"type": "add_garbage", "amount": 1}]},
		"veil": {"name": "Veil", "steps": 4, "effects": [{"type": "attack", "amount": 30}, {"type": "hide_preview", "drops": 3}, {"type": "curse_piece", "amount": 1}]},
		"wither": {"name": "Wither", "steps": 4, "effects": [{"type": "attack", "amount": 50}, {"type": "weaken", "amount": 0.75, "drops": 4}]},
		"grasp": {"name": "Grasp", "steps": 4, "effects": [{"type": "add_garbage", "amount": 2}, {"type": "lock_hold", "drops": 3}]},
		"oblivion": {"name": "Oblivion", "steps": 4, "effects": [{"type": "attack", "amount": 70}, {"type": "curse_piece", "amount": 1}]},
		# The steal runs before the hit, so the 30 lands on the half that's left.
		"eclipse": {"name": "Eclipse", "steps": 5, "intent": "steals half shield, 30 dmg", "effects": [{"type": "call", "method": "eclipse"}, {"type": "attack", "amount": 30}]},
	},
	"phases": [
		{"pattern": {"type": "cycle", "moves": ["bolt", "veil", "bolt"]}},
		{"name": "The Veil Tears", "hp_below": 0.66, "pattern": {"type": "random", "moves": ["bolt", "wither", "grasp"]}},
		{"name": "Eclipse", "hp_below": 0.33, "pattern": {"type": "cycle", "moves": ["oblivion", "oblivion", "eclipse"]}},
	],
}

# Half the player's shield (rounded down) moves onto the Shadow Lord's own. Shield
# banked for the final fight is the run's biggest defensive play; this makes the
# last phase a race to burn through it before it's turned against you.
func eclipse(battle) -> String:
	var stolen = floori(PlayerManager.shieldNum / 2.0)
	PlayerManager.shieldNum -= stolen
	battle.enemyShield += stolen
	battle.updateShieldUI()
	battle.updateEnemyShieldUI()
	return "ECLIPSE -%d SHIELD" % stolen if stolen > 0 else "ECLIPSE"
