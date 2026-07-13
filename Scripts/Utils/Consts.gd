extends Node

# Enemy rosters. Each tier is loaded at startup from one .tres per enemy under
# Data/Enemies/<Tier>/ (typed EnemyData resources). Files are read in sorted
# filename order, so the numeric prefixes (01_, 02_, ...) on the Boss files
# preserve the level order that MapScene/GameplayScene index into
# (BossEnemy[0] = level 3 boss, [1] = level 6, ...).
# To add or tune an enemy, edit/add a .tres in the Inspector — no code change.
var tier1Enemy: Array = []
var tier2Enemy: Array = []
var tier3Enemy: Array = []
var BossEnemy: Array = []

func _ready():
	tier1Enemy = _loadEnemyDir("res://Data/Enemies/Tier1")
	tier2Enemy = _loadEnemyDir("res://Data/Enemies/Tier2")
	tier3Enemy = _loadEnemyDir("res://Data/Enemies/Tier3")
	BossEnemy = _loadEnemyDir("res://Data/Enemies/Boss")

# Load every EnemyData .tres in a directory, sorted by filename. Handles the
# ".remap" suffix that Godot gives resources in exported builds.
func _loadEnemyDir(path: String) -> Array:
	var out: Array = []
	var dir = DirAccess.open(path)
	if dir == null:
		push_error("Consts: could not open enemy directory " + path)
		return out
	for file in dir.get_files():
		var res_name = file
		if res_name.ends_with(".remap"):
			res_name = res_name.trim_suffix(".remap")
		if res_name.ends_with(".tres"):
			out.append(load(path + "/" + res_name))
	return out

# --- Ability definitions (initial/static data) ---
# These are the templates. A run keeps mutable copies in
# PlayerManager.abilityState, so switching/upgrading abilities can change
# their text, cost or effect "value" without touching these defaults.
# "type" drives the battle effect: "attack" deals "value" damage,
# "block" grants "value" shield. Swapping an ability changes the value the
# slot uses, since Main.useSkill reads the equipped ability at cast time.
var abilities = {
	"magic_bolt": {
		"id": "magic_bolt",
		"name": "Magic Bolt",
		"type": "attack",
		"cost": 1,
		"costLabel": "1 orb",
		"value": 50,
		"price": 40,
		"description": "Deal 50 damage to the enemy"
	},
	"barrier": {
		"id": "barrier",
		"name": "Barrier",
		"type": "block",
		"cost": 1,
		"costLabel": "1 orb",
		"value": 20,
		"price": 40,
		"description": "Gain +20 shield"
	},
	# --- Placeholder abilities (generic attack/block for swap testing) ---
	"earthquake": {
		"id": "earthquake",
		"name": "Earthquake",
		"type": "attack",
		"cost": 1,
		"costLabel": "1 orb",
		"value": 80,
		"price": 55,
		"description": "Deal 80 damage to the enemy"
	},
	"mana_burst": {
		"id": "mana_burst",
		"name": "Mana Burst",
		"type": "attack",
		"cost": 1,
		"costLabel": "1 orb",
		"value": 120,
		"price": 80,
		"description": "Deal 120 damage to the enemy"
	},
	"frost_nova": {
		"id": "frost_nova",
		"name": "Frost Nova",
		"type": "attack",
		"cost": 2,
		"costLabel": "2 orbs",
		"value": 90,
		"price": 60,
		"description": "Deal 90 damage to the enemy"
	},
	"flame_wave": {
		"id": "flame_wave",
		"name": "Flame Wave",
		"type": "attack",
		"cost": 2,
		"costLabel": "2 orbs",
		"value": 100,
		"price": 65,
		"description": "Deal 100 damage to the enemy"
	},
	"lightning_strike": {
		"id": "lightning_strike",
		"name": "Lightning Strike",
		"type": "attack",
		"cost": 3,
		"costLabel": "3 orbs",
		"value": 150,
		"price": 95,
		"description": "Deal 150 damage to the enemy"
	},
	"time_warp": {
		"id": "time_warp",
		"name": "Time Warp",
		"type": "block",
		"cost": 1,
		"costLabel": "1 orb",
		"value": 40,
		"price": 50,
		"description": "Gain +40 shield"
	},
	"heal": {
		"id": "heal",
		"name": "Aegis",
		"type": "block",
		"cost": 2,
		"costLabel": "2 orbs",
		"value": 70,
		"price": 70,
		"description": "Gain +70 shield"
	},
}

# --- Character definitions ---
# "abilityPool" is every ability the class may equip; "startingAbilities" are
# the slots the player begins a run with (mapped to skill_1, skill_2, ...).
var characters = [
	{
		"id": "wizard",
		"name": "Wizard",
		"frame": 0,
		"tagline": "Amplification & Burst",
		"abilityPool": ["magic_bolt", "barrier", "earthquake", "mana_burst", "frost_nova", "flame_wave", "lightning_strike", "time_warp", "heal"],
		"startingAbilities": ["magic_bolt", "barrier"]
	}
]

var howToPlay = "-Deal damage by clearing lines on a tetris board
-consecutively clearing lines deals more damage
-you lose a run when the tetrimino reaches the top
-you start with 50 coins, item shop shows up when you
defeat an enemy,gather coins to spend at the shop
-hover on shop items to see what it does
-you can rebind control in the settings menu
-different enemies have certain debuff on you
-There are a total of 15 levels, good luck!"
