class_name DataValidator
extends RefCounted

# Boot-time checks for the content under Data/. Every .tres is plain data wired
# together by strings — effect types, trigger names, ability ids — and a typo in
# any of them otherwise fails silently: a skipped match branch, a key nobody
# reads, an ability that can never be drafted. Consts and Keepsakes call these
# from _init, so a bad file is a red error on launch instead of a bug found
# mid-run.
#
# Each check reports every problem it finds rather than stopping at the first,
# and returns how many it found. Nothing here stops the game from running.

const RARITIES := ["common", "uncommon", "rare"]
# Keys that must hold a number wherever they appear in an effect descriptor.
const NUMERIC_KEYS := ["amount", "min_lines", "element", "shape"]

static func validateAbilities(abilities: Array) -> int:
	var errors := 0
	for ability in abilities:
		var where := _where(ability)
		errors += _checkIdentity(ability, where)
		if ability.burn and ability.cooldown > 0:
			push_warning("Data: %s sets both burn and cooldown — burn outranks cooldown, so leave cooldown at 0" % where)
		for i in ability.effects.size():
			errors += _checkEffect(ability.effects[i], AbilityData.EFFECT_KEYS, [], "%s effects[%d]" % [where, i])
	return errors

static func validateKeepsakes(keepsakes: Array) -> int:
	var errors := 0
	for keepsake in keepsakes:
		var where := _where(keepsake)
		errors += _checkIdentity(keepsake, where)
		for i in keepsake.effects.size():
			var desc = keepsake.effects[i]
			var at := "%s effects[%d]" % [where, i]
			if not desc is Dictionary:
				errors += _fail(at, "is not a Dictionary")
				continue
			var trigger = desc.get("trigger", "")
			if not trigger in KeepsakeData.TRIGGERS:
				errors += _fail(at, "has unknown trigger '%s' (expected one of %s)" % [trigger, KeepsakeData.TRIGGERS])
				continue
			# acquire changes run state and has its own vocabulary; every other
			# trigger runs through Main._applyAbilityEffect.
			var vocabulary = KeepsakeData.ACQUIRE_EFFECTS if trigger == "acquire" else AbilityData.EFFECT_KEYS
			var extraKeys = ["trigger"]
			if trigger == "line_clear":
				extraKeys.append("min_lines")
			errors += _checkEffect(desc, vocabulary, extraKeys, at)
	return errors

static func validateCharacters(characters: Array, abilities: Dictionary) -> int:
	var errors := 0
	for character in characters:
		var where := _where(character)
		if character.id.is_empty():
			errors += _fail(where, "has no id")
		if not character.passive in CharacterData.PASSIVES:
			errors += _fail(where, "has unknown passive '%s'" % character.passive)
		for field in ["abilityPool", "startingAbilities"]:
			for abilityId in character.get(field):
				if not abilities.has(abilityId):
					errors += _fail(where, "%s lists unknown ability id '%s'" % [field, abilityId])
	return errors

# id present and matching the filename (CLAUDE.md: each file is named for its id),
# and a rarity from the shared tiers.
static func _checkIdentity(res, where: String) -> int:
	var errors := 0
	if res.id.is_empty():
		errors += _fail(where, "has no id")
	elif res.resource_path.get_file().get_basename() != res.id:
		errors += _fail(where, "has id '%s', which does not match its filename" % res.id)
	if not res.rarity in RARITIES:
		errors += _fail(where, "has unknown rarity '%s'" % res.rarity)
	return errors

# `vocabulary` maps type -> keys that type reads ("?" suffix = optional).
# `extraKeys` are keys the caller consumes itself (a keepsake's trigger).
static func _checkEffect(desc, vocabulary: Dictionary, extraKeys: Array, where: String) -> int:
	if not desc is Dictionary:
		return _fail(where, "is not a Dictionary")
	var type = desc.get("type", "")
	if not vocabulary.has(type):
		return _fail(where, "has unknown effect type '%s'" % type)
	var errors := 0
	var allowed = extraKeys.duplicate()
	allowed.append("type")
	for spec in vocabulary[type]:
		var key = spec.trim_suffix("?")
		allowed.append(key)
		if not spec.ends_with("?") and not desc.has(key):
			errors += _fail(where, "'%s' is missing required key '%s'" % [type, key])
	for key in desc:
		if not key in allowed:
			errors += _fail(where, "'%s' has unexpected key '%s'" % [type, key])
		elif key in NUMERIC_KEYS and typeof(desc[key]) != TYPE_INT and typeof(desc[key]) != TYPE_FLOAT:
			errors += _fail(where, "'%s' key '%s' must be a number" % [type, key])
	return errors

static func _where(res) -> String:
	return res.resource_path if res.resource_path != "" else str(res)

static func _fail(where: String, message: String) -> int:
	push_error("Data: %s %s" % [where, message])
	return 1
