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
#   damage_enemy  damage the enemy, after its damage reduction
#   shield        gain shield
#   heal          restore HP (capped at maxPlayerHealth)
#   magic         refund magic orbs (capped at maxMagicMeter)
#   clear_rows    wipe `amount` rows off the bottom of the board
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
		# Deep copy: the runtime dictionary exists so a run can upgrade an
		# ability, and a shallow copy would let that edit reach back into the
		# shared .tres and leak across runs.
		"effects": effects.duplicate(true),
		"price": price,
		"description": description,
	}

# Headline number for card UI: the first effect that carries an amount.
# Returns -1 when an ability has no numeric effect (e.g. a pure board clear).
static func headlineAmount(ability: Dictionary) -> int:
	for effect in ability.get("effects", []):
		if effect.has("amount"):
			return effect.amount
	return -1
