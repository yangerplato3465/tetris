class_name AbilityData
extends Resource

# Typed definition for a single ability/spell. One .tres per ability lives under
# Data/Abilities/ and is loaded into Consts.abilities at startup.
#
# NOTE: this is the *authoring* form. At runtime PlayerManager keeps a mutable
# dictionary copy per ability (abilityState) via to_dict(), because a run can
# retext/upgrade abilities with arbitrary fields (see PlayerManager.updateAbility).
# Keeping the runtime copy as a plain Dictionary leaves every ability consumer
# (Main.useSkill, AbilityDraftScene, ShopPanel) untouched.
#
# What an ability *does* is authored declaratively in `effects` — a list of
# {"type": String, "amount": int} dictionaries applied in order when the skill
# is cast. Main._applyAbilityEffect is the only place that knows what each type
# means, so a new ability needs no code as long as it uses existing types:
#
#   damage_enemy      damage the enemy, after its damage reduction
#   damage_per_row    `amount` damage per occupied row on the board
#   damage_per_combo  `amount` damage per step of the combo held right now
#   damage_per_garbage `amount` damage per garbage block on the board
#   damage_per_shield `amount` damage per point of current shield (shield is not spent)
#   shield            gain shield
#   heal              restore HP (capped at maxPlayerHealth)
#   magic             refund magic orbs (capped at maxMagicMeter)
#   charge            bank flat damage onto the next line clear
#   clear_rows        wipe `amount` rows off the bottom of the board
#   holy_beam         clear the fullest row — no damage, no combo
#   purify_garbage    turn every garbage block back into a normal block
#   shuffle_rows      scramble the bottom `amount` rows
#   compact_board     every block falls straight down, closing all gaps; rows
#                     completed on the way clear normally (damage and combo)
#   add_garbage       push `amount` garbage rows onto your *own* board
#   enchant_piece     retype the falling piece to the elemental in `element`
#   queue_piece       put the tetromino in `shape` at the front of the queue
#   cleanse           strip the enemy's damage reduction for this battle
#   delay_attack      wind the enemy attack counter back `amount` drops
#
# Most effects carry an int `amount`. enchant_piece and queue_piece are the
# exceptions: they carry `element` (a Constants.Elemental value) and `shape` (an
# index into Constants.SHAPES) instead, so headlineAmount doesn't print an id as
# a card's headline number.
#
# The names match Events.gd / EventScene._applyEffect where the meaning is the
# same, so the two vocabularies read alike. The exception is damage_enemy:
# an event's "damage" hurts the *player*, so it gets a distinct name here.

@export var id: String = ""
@export var name: String = ""
# Descriptive only — casting dispatches on `effects`, not on this. Kept as a
# coarse tag for card visuals and for filtering an ability pool.
@export_enum("attack", "block") var type: String = "attack"
@export_enum("common", "uncommon", "rare") var rarity: String = "common"
@export var cost: int = 1            # magic orbs spent to cast
@export var costLabel: String = ""   # e.g. "1 orb"
@export var cooldown: int = 0        # pieces that must drop before recasting (0 = none)
@export var effects: Array[Dictionary] = []
@export var price: int = 0           # shop cost in coins
@export_multiline var description: String = ""

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": type,
		"rarity": rarity,
		"cost": cost,
		"costLabel": costLabel,
		"cooldown": cooldown,
		# Deep copy: the runtime dictionary exists so a run can upgrade an
		# ability, and a shallow copy would let that edit reach back into the
		# shared .tres and leak across runs.
		"effects": effects.duplicate(true),
		"price": price,
		"description": description,
	}

# Tooltip suffix describing the cooldown, or "" when the ability has none.
static func cooldownLabel(ability: Dictionary) -> String:
	var cd = ability.get("cooldown", 0)
	return "\nCooldown: %d drops" % cd if cd > 0 else ""

# Headline number for card UI: the first effect that carries an amount.
# Returns -1 when an ability has no numeric effect (e.g. a pure board clear).
static func headlineAmount(ability: Dictionary) -> int:
	for effect in ability.get("effects", []):
		if effect.has("amount"):
			return effect.amount
	return -1
