class_name EnemyData
extends RefCounted

# One enemy, built at startup from a Data/Enemies/<Tier>/<id>.gd file holding a
# `const ENEMY` dictionary. The folder is the tier (Consts loads each into its own
# array). Enemies are .gd rather than .tres for the same reason events are: an
# enemy is a nested tree (phases -> pattern -> moves -> effects), which is painful
# to edit as sub-resources in the Inspector.
#
# Enemy:
#   "id": String                        must match the filename
#   "name": String
#   "boss_floor": int                   Boss/ only: the floor this boss owns
#   "health": int
#   "reward": int                       coins for the win
#   "frame": int                        sprite frame in the enemy sheet
#   "description": String               card tooltip (optional)
#   "board": String                     starting board, one of BOARDS
#   "passives": Array of descriptors    battle-long rules, PASSIVE_KEYS (optional)
#   "moves": {move id: Move}
#   "phases": Array of Phase
#
# Move:    {"name": String, "steps": int, "effects": Array of descriptors, "intent": String}
#          steps = piece drops to wind up; effects use EFFECT_KEYS, run in order.
#          intent (optional) replaces the generated line under the attack counter —
#          for a call move, whose effect the game can't describe itself
# Phase:   {"pattern": Pattern, "hp_below": float, "name": String}
#          hp_below: the phase starts once HP falls under this fraction of max.
#          The first phase has none; each later one needs one, strictly lower
#          than the phase before. name (optional) pops up when the phase starts.
# Pattern: {"type": "cycle" | "random", "moves": [move id, ...]}
#          cycle loops the list in order; random picks uniformly (list a move
#          twice to weight it). EnemyBrain runs both.

const ENEMY_KEYS := ["id", "name", "boss_floor?", "health", "reward", "frame", "description?", "board", "passives?", "moves", "phases"]
const MOVE_KEYS := ["name", "steps", "effects", "intent?"]
const PHASE_KEYS := ["pattern", "hp_below?", "name?"]
const PATTERN_KEYS := ["type", "moves"]
const PATTERN_TYPES := ["cycle", "random"]

# Starting boards, as Grid.setStage builds them.
const BOARDS := ["clean", "small", "medium", "large"]

# What a move can do, mapped to the keys each type reads (Main._applyEnemyEffect).
# `drops` effects last that many of the player's piece drops; applying one while it
# is active keeps the longer of the two counts.
const EFFECT_KEYS := {
	"attack": ["amount"],             # hit the player's shield, then HP
	"add_garbage": ["amount"],        # push that many garbage rows onto the player's board
	"enemy_shield": ["amount"],       # the enemy blocks that much damage; lasts until broken
	"heal": ["amount"],               # the enemy regains HP, up to its max
	"weaken": ["amount", "drops"],    # the player's damage x amount (0.5 = halved); cleanse lifts it
	"lock_hold": ["drops"],           # the player can't hold
	"hide_preview": ["drops"],        # the next-piece preview is blank
	"curse_piece": ["amount?"],       # the next amount (default 1) queued pieces become garbage
	"call": ["method"],               # run func <method>(battle) from this enemy's own file
}

# Rules that hold for the whole battle.
const PASSIVE_KEYS := {
	"damage_reduction": ["amount"],  # multiplier on all damage the player deals (0.5 = halved)
	"disable_hold": [],              # the player can't hold pieces
}

# Fields are untyped on purpose: DataValidator reports a wrong type in the data, and
# a typed field would crash the loader on it before the report could be made.
var id
var name
var bossFloor = 0
var health
var reward
var frame
var description
var board
var passives
var moves
var phases
var source: Dictionary   # the authored ENEMY dictionary, which DataValidator checks
var path: String         # the file it came from
var fileScript = null    # that file's GDScript (set by Consts); Main instances it per battle for call moves

# Battle-long debuffs, read off passives (Main.setStage).
var damageReduction = 1.0
var disablesHold = false

static func fromDict(data: Dictionary, sourcePath: String) -> EnemyData:
	var enemy := EnemyData.new()
	enemy.source = data
	enemy.path = sourcePath
	enemy.id = data.get("id", "")
	enemy.name = data.get("name", "")
	enemy.bossFloor = data.get("boss_floor", 0)
	enemy.health = data.get("health", 0)
	enemy.reward = data.get("reward", 0)
	enemy.frame = data.get("frame", 0)
	enemy.description = data.get("description", "")
	enemy.board = data.get("board", "clean")
	enemy.passives = data.get("passives", [])
	enemy.moves = data.get("moves", {})
	enemy.phases = data.get("phases", [])

	for passive in enemy.passives:
		if not passive is Dictionary:
			continue
		match passive.get("type", ""):
			"damage_reduction":
				enemy.damageReduction = passive.get("amount", 1.0)
			"disable_hold":
				enemy.disablesHold = true
	return enemy

# The intent line shown under the attack counter: what `move` will do when it
# lands, e.g. "40 dmg, +1 garbage", or the move's own `intent` if it has one.
# Kept short on purpose — it shares a 300px line. call effects add nothing.
static func describeMove(move: Dictionary) -> String:
	if move.get("intent") is String:
		return move.intent
	var damage := 0
	var rows := 0
	var parts := []
	for effect in move.get("effects", []):
		if not effect is Dictionary:
			continue
		var amount = effect.get("amount", 0)
		var drops = effect.get("drops", 0)
		match effect.get("type", ""):
			"attack":
				damage += amount
			"add_garbage":
				rows += amount
			"enemy_shield":
				parts.append("shield %d" % amount)
			"heal":
				parts.append("heal %d" % amount)
			"weaken":
				parts.append("weak x%s (%d)" % [amount, drops])
			"lock_hold":
				parts.append("no hold (%d)" % drops)
			"hide_preview":
				parts.append("blind (%d)" % drops)
			"curse_piece":
				parts.append("curse %d" % effect.get("amount", 1))
	if rows > 0:
		parts.push_front("+%d garbage" % rows)
	if damage > 0:
		parts.push_front("%d dmg" % damage)
	return ", ".join(parts)
