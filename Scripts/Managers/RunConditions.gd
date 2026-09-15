class_name RunConditions
extends RefCounted

# Declarative conditions on run state, used by events: `requires` on an event
# decides whether it can be rolled, and `requires` on an option decides whether
# it is shown. A requires list is an Array of one-key Dictionaries, and every
# entry must hold:
#
#   "requires": [{"min_floor": 4}, {"flag": "robbed_merchant"}]
#
# Conditions are data rather than expression strings so DataValidator can check
# every condition name, value type and referenced id at boot.

# Condition -> the Variant type its value must hold.
const KEYS := {
	"min_floor": TYPE_INT,         # PlayerManager.currentLevel >= value
	"max_floor": TYPE_INT,         # currentLevel <= value
	"min_coins": TYPE_INT,         # coin >= value
	"has_keepsake": TYPE_STRING,   # owns the keepsake with this id
	"lacks_keepsake": TYPE_STRING, # does not own it
	"class": TYPE_STRING,          # PlayerManager.characterClass == value
	"flag": TYPE_STRING,           # run flag is set (RunEffects set_flag)
	"not_flag": TYPE_STRING,       # run flag is not set
}

# True when every condition in `requires` holds. An empty list always holds.
static func met(requires: Array) -> bool:
	for condition in requires:
		if not check(condition):
			return false
	return true

static func check(condition: Dictionary) -> bool:
	var key = condition.keys()[0]
	var value = condition[key]
	match key:
		"min_floor":
			return PlayerManager.currentLevel >= value
		"max_floor":
			return PlayerManager.currentLevel <= value
		"min_coins":
			return PlayerManager.coin >= value
		"has_keepsake":
			return PlayerManager.ownedKeepsakes.has(value)
		"lacks_keepsake":
			return not PlayerManager.ownedKeepsakes.has(value)
		"class":
			return PlayerManager.characterClass == value
		"flag":
			return PlayerManager.runFlags.has(value)
		"not_flag":
			return not PlayerManager.runFlags.has(value)
	push_warning("RunConditions: unknown condition '%s'" % key)
	return false
