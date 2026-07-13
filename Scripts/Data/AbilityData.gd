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

@export var id: String = ""
@export var name: String = ""
@export_enum("attack", "block") var type: String = "attack"
@export var cost: int = 1            # magic orbs spent to cast
@export var costLabel: String = ""   # e.g. "1 orb"
@export var value: int = 0           # attack: damage dealt; block: shield gained
@export var price: int = 0           # shop cost in coins
@export_multiline var description: String = ""

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": type,
		"cost": cost,
		"costLabel": costLabel,
		"value": value,
		"price": price,
		"description": description,
	}
