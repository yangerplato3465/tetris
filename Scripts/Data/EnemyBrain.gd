class_name EnemyBrain
extends RefCounted

# Decides what an enemy does next, from its EnemyData phases and patterns. Main
# owns one per battle (setStage) and asks it for a move each time the previous
# one lands; everything about *doing* the move stays in Main.
#
# Phases: the enemy is in the last phase whose "hp_below" its HP fraction is under
# (phase 0 has none, so it always qualifies). Thresholds strictly decrease, which
# DataValidator enforces, so phases read top to bottom as the fight goes on.
# Phases only move forward: an enemy that heals back above a threshold stays in
# the later phase, so its announcement never repeats.
#
# Patterns:
#   cycle   the moves in order, looping; restarts from the top on entering a phase
#   random  a uniform pick each time; list a move twice to weight it
#
# A move, once picked, is committed: the player has seen it telegraphed, so a
# phase change mid-wind-up only affects the pick after it lands.

var enemy: EnemyData
var phaseIndex := 0
var rng := RandomNumberGenerator.new()   # seed it for a repeatable fight (tests)
var _cycleIndex := 0

func _init(enemyData: EnemyData) -> void:
	enemy = enemyData
	rng.randomize()

# Moves to the phase `hpFraction` (current / max HP) calls for. Returns true only
# when that changed, so a caller can announce the new phase exactly once.
func updatePhase(hpFraction: float) -> bool:
	var target := 0
	for i in range(1, enemy.phases.size()):
		if hpFraction < enemy.phases[i].get("hp_below", 0.0):
			target = i
	if target <= phaseIndex:
		return false
	phaseIndex = target
	_cycleIndex = 0
	return true

func currentPhase() -> Dictionary:
	return enemy.phases[phaseIndex]

# Picks the next move for the current phase. Returns the move dictionary with its
# id added under "id", or {} if the data is broken (DataValidator reports that).
func pickMove() -> Dictionary:
	var pattern: Dictionary = currentPhase().get("pattern", {})
	var ids: Array = pattern.get("moves", [])
	if ids.is_empty():
		return {}
	var moveId
	match pattern.get("type", "cycle"):
		"random":
			moveId = ids[rng.randi_range(0, ids.size() - 1)]
		_:
			moveId = ids[_cycleIndex % ids.size()]
			_cycleIndex += 1
	var move = enemy.moves.get(moveId)
	if not move is Dictionary:
		return {}
	var picked: Dictionary = move.duplicate()
	picked["id"] = moveId
	return picked
